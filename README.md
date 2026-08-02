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

The production host runs the static gallery in Docker behind the shared `devtksg` nginx proxy network. Deploy a published ref with:

```bash
REF=main ./deploy.sh
```
