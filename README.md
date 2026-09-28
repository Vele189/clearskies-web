# ClearSkies — frontend

The map: React, MapLibre GL and a PMTiles archive, showing cumulative
environmental burden across Louisiana on an H3 resolution 8 grid.

## This repository is generated

It is produced from [`Vele189/ClearSkies`](https://github.com/Vele189/ClearSkies)
by `make split`, which rewrites that repository's `web/` directory into the root
of this one with `git subtree split`, keeping the commits that touched it.

**Send changes there, not here.** A commit made in this repository is not
carried back and is overwritten by the next sync. The monorepo's `docs/repos.md`
explains the arrangement and how to recover such a commit if one happens
anyway. What this repository is for is deploying: it is the whole service, so a
build here cannot be triggered by a change to the API or the pipeline.

## Running it

The quick way, with Docker, after the API's `./start.sh`:

```
./start.sh          # builds and serves on :8080
./start.sh down     # stops it
```

For development with hot reload:

```
npm ci
cp .env.example .env     # at least VITE_API_BASE_URL
npm run dev              # http://localhost:5173
```

The API it talks to is the monorepo's `api/`, or the published one. `npm run
test`, `npm run lint` and `npm run typecheck` are what CI runs.

## The container

```
docker build -t clearskies-web --build-arg VITE_API_BASE_URL=https://api.example.com .
docker run --rm -p 8080:8080 clearskies-web
```

A Node stage builds, an nginx stage serves, and no Node reaches the image that
holds the port open.

**The image is specific to one deployment.** Vite inlines every `VITE_`
variable into the bundle at build time, so the API's URL, the tile archive and
the basemap are fixed when the image is built and cannot be changed by the
environment the container starts in. Pointing the app at a different API is a
rebuild, not a restart. `.env.example` lists every variable; none of them is a
secret, because whatever is set is readable in the bundle.

`nginx.conf.template` is rendered at startup with `${PORT}` substituted. It
serves `index.html` for any path that is not a file on disk, which is what keeps
a deep link to `/hex/8844c0b18bfffff` from being a 404, and it caches the
hashed assets forever while refusing to cache `index.html` — a cached shell
pins the browser to the previous build's asset names.

## Deploying to Railway

`railway.json` tells Railway to build the Dockerfile and to wait for `/` to
answer before switching traffic. Railway hands a service's variables to a
Dockerfile build as build args, so the `VITE_` variables below reach Vite
through the `ARG`s the Dockerfile already declares.

1. New service from this repository, named `web`. Variables:

   ```
   VITE_API_BASE_URL=https://${{api.RAILWAY_PUBLIC_DOMAIN}}
   VITE_TILES_URL=https://<your R2 bucket>/clearskies-la.pmtiles
   VITE_BASEMAP_STYLE=https://tiles.openfreemap.org/styles/positron
   VITE_GEOCODER_URL=          # empty keeps search local
   ```

   A Railway build without `VITE_API_BASE_URL` fails on purpose rather than
   shipping a bundle that calls `localhost`.
2. Generate a public domain under Settings > Networking. The CDN under
   Settings > Edge is safe to turn on here: every asset name is hashed and
   `index.html` is served `no-cache`.
3. Put that domain in the API's `CORS_ORIGINS`, and in the R2 bucket's CORS
   policy, or the browser blocks the responses.

A changed `VITE_` variable needs a redeploy, not a restart: the value is in
the bundle.

## What CI here does and does not do

It lints, typechecks, tests, builds, and builds the image and asks it for a
page. It is a check that this repository still stands on its own. The
authoritative suite — the accessibility pass, the API's tests, the migrations
against real PostGIS, the validation gates — is in the monorepo, and a change
is meant to be green there before it is ever split.
