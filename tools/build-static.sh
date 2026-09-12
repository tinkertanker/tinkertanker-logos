#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
rm -rf output/cloudflare
mkdir -p output/cloudflare
cp -R site/. output/cloudflare/
cp -R logos output/cloudflare/logos
printf 'ok\n' > output/cloudflare/healthz
