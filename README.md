# Provenance — a sourced live map of open data

**Provenance turns public feeds into one explorable globe where every marker says who published it, how it was derived, and what it cannot tell you.**

> **Provenance of this repository — read first.** This is a restored public mirror of work originally created by **011-sam-110 (Sam)** (`lesttech.dev.sam@gmail.com`) under the names `TrafficNerd-V2` and `Provenance`. The git history starts with that author's commits in June 2026; later commits in this mirror are dependency, build and deployment maintenance by this account. **This is not original work by `anya12forger12-max`.** The former upstream repository (`011-sam-110/Provenance` / `011-sam-110/TrafficNerd-V2`) is not currently public; the earlier London-only [TrafficNerd v1](https://github.com/011-sam-110/TrafficNerd) is. Copyright © 2026 011-sam-110, licensed [AGPL-3.0-only](LICENSE).

![Provenance globe with live open-data layers](docs/screenshots/hero.png)

## What it is

Governments, space agencies, seismologists and humanitarian organisations publish a lot of live data that is hard to read in its raw form. Provenance renders those feeds on a single MapLibre globe: road and traffic cameras, webcams, aircraft, satellites, earthquakes, wildfires, undersea cables, internet outages, conflict, displacement, markets and news. The core map needs no API key and no login.

Each layer is independently attributed. Its provenance card states what one pin actually represents, the method used to obtain it, a confidence class, and a limitation that is never left blank. A test fails the build if a new signal layer is registered without that explanation. When an upstream feed fails or truncates its response, the app says so instead of presenting an invented or silently shrunken picture.

This repository is a snapshot, not a live service promise. Coverage depends on public upstreams staying available; the upstream README records a **dated 2026-08-18 endpoint check pinned to commit `6f60b4a`** and documents known gaps, including a Castle Rock 511 adapter timeout that was fixed. Treat those figures as historical observations, not current counters. See [ROADMAP.md](ROADMAP.md) and [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for the current state.

## Features

- **One continuous globe-to-map engine** — a MapLibre `projection: 'globe'` instance morphs from a spinning satellite Earth into flat satellite, light or topographic maps, with 3D terrain engaging at closer zoom levels.
- **Independently sourced signal layers** — four core layers (cameras, webcams, aircraft, satellites) plus global signals such as earthquakes (USGS/EMSC), NASA EONET and FIRMS, NOAA space weather, GDACS, IODA outages, GDELT, ACLED, UNHCR, WFP, abuse.ch and Ransomware.live.
- **Attribution that travels with the data** — every layer carries publisher, method, confidence class and limitations; the landing page's source wall is generated from the same `SOURCE_CATALOG` the map uses, so it cannot drift from the app.
- **Declared truncation and honest failure** — coverage records state how many rows existed upstream, how many are shown and how they were selected; a failing feed keeps its last-good data or degrades to an empty set rather than returning an error or fabricating rows.
- **Camera adapters and a closed proxy** — one adapter per agency feed, normalised into a common `Camera` shape with last-good caching; live stills and HLS streams are fetched through a proxy that accepts a camera **id**, not an arbitrary URL, and enforces a host allowlist.
- **Aircraft and satellites** — OpenSky snapshots with an adsb.lol fallback, breadcrumb trails and click-to-enrich; CelesTrak TLEs propagated in the browser with SGP4.
- **Terminal-style console** — the `/app` workspace has a widget catalogue, rearrangeable boards, shareable layouts via a URL parameter, per-country dossiers, and CSV or GeoJSON export of visible rows.

## Quick start

```bash
git clone https://github.com/anya12forger12-max/Provenance.git
cd Provenance
npm install
npm run dev
```

Open `http://localhost:3000` for the site and `/app` for the console. `./install.sh` is an equivalent one-command dependency installer. For a production build use `npm run build && npm run start`; run the Vitest suite with `npm test` and Playwright checks with `npm run e2e`.

No keys are needed for the core map. Optional feeds use the environment variables documented in [.env.example](.env.example) and [docs/API_KEYS.md](docs/API_KEYS.md); copy the example to `.env` locally and never commit populated credentials. A local GeoCLIP sidecar can improve `/locate` accuracy.

![Console and clustered cameras](docs/screenshots/console.png)

## Project structure

```text
app/(site)/      landing page, privacy page, generated source wall
app/(console)/   console shell and workspace
app/api/         route handlers for cameras, signals, news, markets, recon, proxy, ...
components/      map, boards, camera/satellite/plane detail views, admin review tools
lib/sources/     one adapter per camera feed, normalisation and last-good cache
lib/signals/     one adapter and provenance card per signal layer
lib/proxy/       closed image/HLS proxy with host allowlist
lib/console/     widget registry, boards and shareable layouts
tests/           Vitest unit tests and Playwright checks
```

Adding a source is intended to be one adapter file, one registry entry and a fixture test; it then appears in the map, the widget catalogue and the site's source wall.

## Responsible use

This is public-data mapping, not a licence to surveil people. Respect each upstream's terms and attribution requirements, honour rate limits, do not use camera or aircraft data to track individuals, and independently verify any conclusion before acting on it. See [SECURITY.md](SECURITY.md) for reporting security issues.

## Licence and credits

- **Code:** copyright © 2026 011-sam-110, [AGPL-3.0-only](LICENSE). The AGPL's network clause applies when a modified version is run as a service; the running app's links back to source are part of that obligation.
- **Data:** each upstream feed keeps its own terms. TfL, Windy, CARTO/OpenStreetMap, NASA, USGS, GDACS, TeleGeography, OpenSky, adsb.lol and others require attribution reproduced in the app; this licence does not grant rights to their data.
- **Third-party code:** the upstream README states that no code was copied from other projects; `koala73/worldmonitor` was consulted only for factual endpoint information.

Original design and implementation belong to 011-sam-110. This mirror preserves that attribution and makes no claim of original authorship.
