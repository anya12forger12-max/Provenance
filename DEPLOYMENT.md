# Deployment — Provenance (`trafficnerd-v2`)

Self-hosting notes for the Next.js 15 app. Production images use Next's
**standalone** output: `next.config.ts` sets `output: "standalone"` while keeping
the `TN_DIST_DIR` override and the satellite.js webpack shims intact. A verified
`npm ci && npm run build` produces `.next/standalone/server.js`.

> Building from a VFAT-mounted directory (e.g. a pendrive) is unsupported by
> npm because it cannot create symlinks there. Copy the source to a normal
> filesystem first, then run install/build commands there.

## 1. Build and run

### Docker Compose (recommended)

```sh
cp .env.example .env      # then replace the placeholders
docker compose up -d --build
curl -fsS http://localhost:3000/api/status
```

`docker-compose.yml` reads runtime variables from `.env` via `env_file`, passes
`NEXT_PUBLIC_SITE_URL` as a build arg, publishes the port, sets
`restart: unless-stopped`, and defines a health check. To pull a published image
instead of building locally, skip `--build` (the `image:` field defaults to
`ghcr.io/011-sam-110/trafficnerd-v2:latest`).

### Docker CLI

```sh
docker build \
  --build-arg NEXT_PUBLIC_SITE_URL=https://provenance.example.com \
  -t provenance:local .

docker run -d --name provenance \
  --env-file .env -p 3000:3000 \
  --restart unless-stopped provenance:local
```

### Native (no Docker)

Use Node 22 (the image base) or newer:

```sh
npm ci
npm test
npm run build
PORT=3000 npm start
```

To run the standalone bundle directly, assemble the two directories Next does
not copy into it:

```sh
rm -rf /tmp/provenance-standalone && mkdir -p /tmp/provenance-standalone/.next
cp -a .next/standalone/. /tmp/provenance-standalone/
cp -a .next/static /tmp/provenance-standalone/.next/static
cp -a public /tmp/provenance-standalone/public
PORT=3000 HOSTNAME=0.0.0.0 node /tmp/provenance-standalone/server.js
```

If `TN_DIST_DIR` was set for the build, substitute that directory for `.next`
above; the Docker stages assume the default `.next` and leave `TN_DIST_DIR`
unset.

## 2. Ports

| Direction | Port | Notes |
| --- | --- | --- |
| Container / Node server | `3000` (`PORT` in the image) | `HOSTNAME=0.0.0.0` so it is reachable outside the container |
| Host (Compose) | `${PORT:-3000}` from `.env` | `docker-compose.yml` maps `"${PORT:-3000}:3000"`; set `PORT=3100` in `.env` to publish `3100` |
| Host (manual `docker run`) | first value in `-p` | e.g. `-p 8080:3000` |

The Docker `HEALTHCHECK` and Compose health check always probe the container's
internal port derived from `process.env.PORT` (3000 by default).

## 3. Environment variables

| Name | Scope | Purpose |
| --- | --- | --- |
| `NEXT_PUBLIC_SITE_URL` | **Build time** | The only `NEXT_PUBLIC_*` variable referenced in the source (`lib/brand.ts`). Canonical origin for metadataBase, OG cards, robots.txt and sitemap. Baked into the client bundle, so changing it requires a rebuild. Dockerfile `ARG`, GitHub Actions repository variable `vars.NEXT_PUBLIC_SITE_URL`, and Compose build arg all feed it. |
| `PORT` | Runtime | HTTP listen port; Compose also uses it as the published host port. |
| `HOSTNAME` | Runtime | Bind address, `0.0.0.0` in the image. |
| `NODE_ENV` | Runtime | `production` is set by the image and Compose. Also gates the `/admin` curation routes (they 404 in production by design). |
| `TN_DIST_DIR` | Build time, native only | `next.config.ts` build-directory override. Leave unset for Docker; the runtime stage copies from `.next/standalone` and `.next/static`. |
| Optional server-side API keys | Runtime | Supply via `.env` / `env_file` only. Names and what they unlock are listed in `docs/API_KEYS.md`; none are needed for the app to boot, and no values belong in this repo. |

Vercel-only variables (`VERCEL_ENV`, `VERCEL_PROJECT_PRODUCTION_URL`) are not
needed on a self-hosted deployment; with `NEXT_PUBLIC_SITE_URL` set, `siteUrl()`
does not fall back to a Vercel domain.

`.env.example` contains placeholders only. `.gitignore` excludes real `.env`
files, and `.dockerignore` keeps them out of the build context/image.

## 4. Health checks

- Image: `HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3`.
- Compose: same timing, `restart: unless-stopped`.
- Probe: Node 22's global `fetch` calls `http://127.0.0.1:$PORT/api/status` and
  exits non-zero on a network error or non-2xx response. No `curl`/`wget` is
  installed in the minimal runtime image.
- `/api/status` is an in-process capability report. It makes **no upstream
  requests**, so a healthy result means the server is up, not that every
  third-party feed is reachable. Missing optional API keys are reported as
  such rather than making the container unhealthy.

Inspect with:

```sh
docker compose ps
docker inspect --format '{{.State.Health.Status}}' <container>
```

## 5. CI/CD to GHCR

`.github/workflows/docker.yml` runs on every pull request and on pushes to
`main`. It builds with Buildx using metadata-derived tags, labels and the GHA
cache. Login to GHCR and `push: true` happen **only** on `main`; PRs are
build-only. The workflow uses `GITHUB_TOKEN` with `contents: read` and
`packages: write`. Published tags include `main`, `latest` (default branch) and
immutable `sha-<commit>` tags. The existing `.github/workflows/ci.yml` is
unchanged.

## 6. Upgrade and rollback

**Upgrade:** pick an immutable tag from the workflow run, then:

```sh
IMAGE=ghcr.io/011-sam-110/trafficnerd-v2:sha-<newsha> docker compose pull
IMAGE=ghcr.io/011-sam-110/trafficnerd-v2:sha-<newsha> docker compose up -d --force-recreate
docker compose ps    # wait for `healthy`
curl -fsS http://localhost:3000/api/status
```

**Rollback:** set `IMAGE` to the previously working `sha-<oldsha>` tag and run
the same `up -d --force-recreate`. Keep the last known-good image locally until
the replacement is confirmed healthy, or simply redeploy the older tag — no
database/schema migration exists in this repo. Because
`NEXT_PUBLIC_SITE_URL` is baked in at build time, a rollback also restores that
image's public URL; rebuild (with Compose's build arg) if the origin changed.

Native rollback: keep the previous release directory, stop the current server,
and start the old build on the same port using the standalone launch steps
above. ISR/cache data under `.next/cache` is disposable; `data/discovery/*`
files are shipped in the image and revert with it, while production-gated admin
curation writes are disabled (`NODE_ENV=production`).
