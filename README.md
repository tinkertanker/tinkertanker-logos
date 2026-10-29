# Tinkertanker Logos

Official Tinkertanker, Tinkercademy, Get Hacking, and Tinker Class logos, available at [logos.tk.sg](https://logos.tk.sg).

## Assets

`logos/` contains full-resolution PNGs from the former [tk.sg/logos](https://tk.sg/logos) Zight collection, with original filenames preserved.

Verified Google Drive design sources are linked below matching PNGs and require Tinkertanker Google Workspace access.

## Agent guidance

[`/llms.txt`](https://logos.tk.sg/llms.txt) explains brand, layout, background contrast, file formats, source access, and direct downloads for every supplied PNG. It is discoverable from the homepage's HTML metadata and HTTP `Link` header. [`/logos.json`](https://logos.tk.sg/logos.json) remains the machine-readable asset catalog.

Selection advice describes the supplied artwork, not new brand rules or usage permissions. Keep the guidance's URLs and dimensions aligned with the catalog when refreshing assets. In particular, the catalog groups Get Hacking and Tinker Class together; their wordmarks are not interchangeable.

WebMCP is not needed for this read-only static library: agents can fetch the guidance, catalog, and assets directly without a browser session or tool registration. Reassess if the site gains actions that cannot be expressed as ordinary asset URLs.

Refresh the collection and manifest with:

```bash
ruby tools/import_zight_collection.rb
```

## Local preview

```bash
wrangler dev
```

## Deployment

Production is hosted on Cloudflare Workers Static Assets in the **Tinkertanker** account (`b8b1032c61d9475cd00229c74db7ec72`). The Worker is `tinkertanker-logos`, with the custom domain `logos.tk.sg`.

Deploy the current checkout with Wrangler v4 using the Tinkertanker auth profile:

```bash
wrangler deploy --dry-run --profile tinkertanker
wrangler deploy --profile tinkertanker
```

Wrangler runs `tools/build-static.sh` to assemble `site/`, `logos/`, and `/healthz` into `output/cloudflare/`. Cache and security headers are defined in `site/_headers`.

To restore a previous Worker version, run `wrangler rollback --profile tinkertanker`.
