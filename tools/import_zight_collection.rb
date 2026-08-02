#!/usr/bin/env ruby

require "cgi"
require "fileutils"
require "json"
require "net/http"
require "uri"

COLLECTION_URL = "https://cld.tk.sg/collections/VrfVJr/Logos"
OUTPUT_DIR = File.expand_path("../logos", __dir__)
MANIFEST_PATH = File.expand_path("../site/logos.json", __dir__)

def fetch(url, redirects = 5)
  raise "Too many redirects for #{url}" if redirects.zero?

  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  return fetch(URI.join(url, response["location"]).to_s, redirects - 1) if response.is_a?(Net::HTTPRedirection)

  raise "HTTP #{response.code} for #{url}" unless response.is_a?(Net::HTTPSuccess)

  response.body
end

def category_for(name)
  case name
  when /Tinkercademy/i then "Tinkercademy"
  when /Tinkertanker/i then "Tinkertanker"
  when /\b(?:GH|TCPL)\b/i then "Tinker Class"
  else "Other"
  end
end

def preview_for(name)
  name.match?(/white text|on dark/i) ? "dark" : "light"
end

def dimensions(path)
  File.open(path, "rb") do |file|
    signature = file.read(24)
    raise "Not a PNG: #{path}" unless signature&.start_with?("\x89PNG\r\n\x1a\n".b)

    signature.byteslice(16, 8).unpack("NN")
  end
end

collection_html = fetch(ARGV.fetch(0, COLLECTION_URL))
items = collection_html.scan(
  /class="zt-dashboard-card-title" title="([^"]+)"[^>]*href="\/([^?]+)\?collection_id=/,
).map do |escaped_name, id|
  { "id" => id, "filename" => CGI.unescapeHTML(escaped_name) }
end

raise "No collection items found" if items.empty?

FileUtils.mkdir_p(OUTPUT_DIR)
FileUtils.mkdir_p(File.dirname(MANIFEST_PATH))

items.each_with_index do |item, index|
  puts format("[%02d/%02d] %s", index + 1, items.length, item["filename"])
  item_html = fetch("https://cld.tk.sg/#{item["id"]}")
  raw_url = item_html[/"content_url":"([^"]+)"/, 1]
  created_at = item_html[/"created_at":"([^"]+)"/, 1]
  raise "No content URL for #{item["id"]}" unless raw_url

  source_url = JSON.parse(%Q{"#{raw_url}"})
  output_path = File.join(OUTPUT_DIR, item["filename"])
  File.binwrite(output_path, fetch(source_url))
  width, height = dimensions(output_path)

  item.merge!(
    "slug" => File.basename(item["filename"], ".png").downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, ""),
    "path" => "/logos/#{item["filename"]}",
    "category" => category_for(item["filename"]),
    "preview" => preview_for(item["filename"]),
    "width" => width,
    "height" => height,
    "created_at" => created_at&.slice(0, 10),
    "source_url" => "https://cld.tk.sg/#{item["id"]}",
  )
end

manifest = {
  "name" => "Tinkertanker logo library",
  "source" => COLLECTION_URL,
  "count" => items.length,
  "items" => items,
}

File.write(MANIFEST_PATH, JSON.pretty_generate(manifest) + "\n")
puts "Imported #{items.length} logos into #{OUTPUT_DIR}"
