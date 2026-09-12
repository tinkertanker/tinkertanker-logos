# Tinkertanker Logos

Downloadable gallery of official Tinkertanker, Tinkercademy, Get Hacking, and Tinker Class logos.

Browse the gallery at [logos.tk.sg](https://logos.tk.sg).

## Assets

The `logos/` directory contains the original full-resolution PNG files from the former [tk.sg/logos](https://tk.sg/logos) Zight collection. Original filenames are preserved.

Where a verified design source exists, the gallery links to it in Google Drive below the matching PNG. These are internal links and require access to the Tinkertanker Google Workspace.

Refresh the collection and manifest with:

```bash
ruby tools/import_zight_collection.rb
```

## Local preview

```bash
docker build -t tinkertanker-logos .
docker run --rm -p 8080:8080 tinkertanker-logos
```

Then open `http://localhost:8080`.

## Deployment

Production is hosted on Cloudflare Workers Static Assets in the **Tinkertanker** account (`b8b1032c61d9475cd00229c74db7ec72`). The Worker is `tinkertanker-logos`, with the custom domain `logos.tk.sg`.

Deploy the current checkout with Wrangler v4 using the Tinkertanker auth profile:

```bash
wrangler deploy --dry-run --profile tinkertanker
wrangler deploy --profile tinkertanker
```

Wrangler runs `tools/build-static.sh` to assemble `site/`, the original `logos/`, and `/healthz` into `output/cloudflare/`. No backend, database, or runtime secrets are required. Missing assets return 404; the gallery lives at `/`. Cache and security headers are defined in `site/_headers`.

For a Cloudflare local preview, run `wrangler dev`.

### Legacy Docker deployment / rollback

The previous Docker container on `dev.tk.sg` was stopped and removed on 2026-09-12. Its checkout and image remain for recovery. On the server, `/home/tinkertanker-server/Docker/tinkertanker-logos/docker-compose.yml` was renamed to `docker-compose.yml.disabled` to prevent ordinary Compose startup. The shared `devtksg` network and nginx proxy were left untouched.

**Do not run `deploy.sh` for normal deployments.** It targets only the retired Docker service, not Cloudflare, and can restore the tracked Compose file and restart the old service:

```bash
REF=main ./deploy.sh
```

To switch hosting back, remove the Worker's `logos.tk.sg` custom domain and restore DNS to the old origin (`66.96.215.10`, DNS-only). Verify the Docker service is healthy before switching. These are production routing changes, not part of a normal deploy. For subsequent Cloudflare releases, `wrangler rollback --profile tinkertanker` restores a previous Worker version.
