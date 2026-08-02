#!/usr/bin/env ruby

require "cgi"
require "fileutils"
require "json"
require "net/http"
require "uri"

COLLECTION_URL = "https://cld.tk.sg/collections/VrfVJr/Logos"
OUTPUT_DIR = File.expand_path("../logos", __dir__)
MANIFEST_PATH = File.expand_path("../site/logos.json", __dir__)

SOURCE_LINKS = {
  "Tinkercademy - vertical - black text - 1472w.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1VWiM_ahNziGEDysvG4B1XhN6Rtb-t9VC/view?usp=drivesdk" }],
  "Tinkercademy - vertical - white text - 1472w.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1I8uytj6eimZ7-G-yFPp7efjz0VmZn_ml/view?usp=drivesdk" }],
  "Tinkercademy - horizontal - white text - 3680w.png" => [{ "label" => "Source package (ZIP)", "url" => "https://drive.google.com/file/d/1-yOVRs3LltW2z1VIBGtMBXquxdyQPwU_/view?usp=drivesdk" }],
  "Tinkercademy - horizontal - black text - 3680w.png" => [{ "label" => "Source package (ZIP)", "url" => "https://drive.google.com/file/d/1-yOVRs3LltW2z1VIBGtMBXquxdyQPwU_/view?usp=drivesdk" }],
  "Tinkercademy - icon - colour - 1152w.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/182LD-3Y9IglNAnnnCqqTcJR0tC8osmr1/view?usp=drivesdk" }],
  "GH logo with tagline on white - 4544w.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1i9Zt3FJC3vRdxAkXhdCrYgyUe5ld5BvO/view?usp=drivesdk" }],
  "GH logo - vertical.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1hFhohBq4q0qR__iYMnQzA0dV79bX6uxV/view?usp=drivesdk" }],
  "GH logo - white text - 1152w.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1iKn2Lfd9hgF4qU53cIPUd_E5oARMnxUC/view?usp=drivesdk" }],
  "GH logo - horizontal - white text - 6240w.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1fGx0Dr0FOTUt0yoB0DHwbldKGINdNO4a/view?usp=drivesdk" }],
  "GH logo - horizontal - 6240w.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1iGh4LC7Q1uSNIXR_VH7w7Ps4H5ThJC28/view?usp=drivesdk" }],
  "GH and TCPL icon.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1i0Vr4NU7XnQ9Ffn5L1LBQQrU0SXlSBlk/view?usp=drivesdk" }],
  "TCPL logo - horizontal.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1eobZhQCyPRAH4n5Ehc39yPx7ht80bPFG/view?usp=drivesdk" }],
  "02 Tinkertanker Tertiary Logo Colour on Dark 4400 W.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1cfEHzMUqDwBLwgSJx5aCO7H_n_HT57D3/view?usp=drivesdk" }],
  "02 Tinkertanker Primary Logo Colour on Dark 3456 W.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1cejcKaf0alC6qElvJurtsyFuXzuELRGF/view?usp=drivesdk" }],
  "02 Tinkertanker Primary icon Colour On Dark 1152 W.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1dm70QN45w6H6kWJcsRe0SovJFSiTMNWI/view?usp=drivesdk" }],
  "01 Tinkertanker Primary Logo Colour on Light 3456 W.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1eOVjm5hL2RwcQmii93UYyhMU4lV5xpkL/view?usp=drivesdk" }],
  "01 Tinkertanker Primary icon Colour on Light 1152 W.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1dXTvT682ip5sW4Ki9fS7wUYQhM2wcY_K/view?usp=drivesdk" }],
  "01 Tinkertanker Tertiary Logo Colour on Light 4400 W.png" => [{ "label" => "SVG source", "url" => "https://drive.google.com/file/d/1ebJzXuZgNIUq2PcfsTp6HmjO0HYoQ_B6/view?usp=drivesdk" }],
}.freeze

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
    "sources" => SOURCE_LINKS.fetch(item["filename"], []),
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
