# Tinkertanker Logos

Official Tinkertanker, Tinkercademy, Get Hacking, and Tinker Class logos, available at [logos.tk.sg](https://logos.tk.sg).

## Assets

`logos/` contains full-resolution PNGs from the former [tk.sg/logos](https://tk.sg/logos) Zight collection, with original filenames preserved.

Verified Google Drive design sources are linked below matching PNGs and require Tinkertanker Google Workspace access.

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
