# Kasm Zen Browser Images

Custom [Kasm Workspaces](https://kasmweb.com) images that run the [Zen Browser](https://zen-browser.app) as a single-application desktop.

## Images

- `kasm-zen` — Zen Browser with uBlock Origin and Dark Reader preinstalled, dark GTK/xfwm4 theme, DuckDuckGo as the default search engine.
- `kasm-zen-mintcifra` — everything from `kasm-zen` plus the Russian Trusted Root/Sub CA certificates (Ministry of Digital Development of Russia) trusted in the system store and browser NSS database.

## Features

- Zen Browser installed from the latest GitHub release.
- uBlock Origin and Dark Reader preinstalled as managed extensions.
- First-run wizard disabled; starts on a single blank tab.
- Default browser prompt suppressed (`browser.shell.checkDefaultBrowser=false`).
- Default search engine set to DuckDuckGo via `policies.json`.
- Dark `Greybird-dark` GTK/xfwm4 theme so the window titlebar matches the browser.
- Single-application desktop optimizations (no panel, maximized window, restricted file chooser, file-manager breakout blocked).

## Requirements

- Docker with BuildKit.
- The `core-ubuntu-jammy` base image from the Kasm registry (auto-detected as the latest `rolling-weekly` tag, or override with `BASE_TAG`).

## Build

```bash
OWNER=your-gh-user scripts/build.sh zen
OWNER=your-gh-user scripts/build.sh zen-mintcifra
```

Optional environment variables:

| Variable    | Default             | Description                                   |
| ----------- | ------------------- | --------------------------------------------- |
| `BASE_IMAGE`| `core-ubuntu-jammy` | Kasm base image name                          |
| `BASE_TAG`  | auto-detected       | Base image tag (e.g. `1.19.0-rolling-weekly`) |
| `REGISTRY`  | `ghcr.io`           | Image registry                                |
| `OWNER`     | (required)          | Registry owner/organization                   |
| `TAGS`      | `rolling-weekly`    | Comma-separated tag list                      |

## Smoke Test

Run the image and verify KasmVNC answers on its health endpoint and the Zen process is alive:

```bash
OWNER=your-gh-user scripts/smoke-test.sh
```

## Run Locally

```bash
docker run -d \
  --name kasm-zen \
  -p 6901:6901 \
  -e VNC_PW=kasmtest \
  --shm-size=512m \
  ghcr.io/your-gh-user/kasm-zen:rolling-weekly
```

Connect to `https://localhost:6901` and log in with the VNC password.

## Layout

```
dockerfile-kasm-zen               Standard Zen image
dockerfile-kasm-zen-mintcifra     Zen image with Russian CA certificates
scripts/build.sh                  Build wrapper
scripts/detect-latest-core-tag.sh Resolves the latest Kasm base tag
scripts/smoke-test.sh             Container health/process smoke test
src/ubuntu/install/
  certificates/                   Russian Trusted Root/Sub CA certificates
  close_browser_breakout_via_file_manager/
  gtk/                            Restricted GTK file chooser
  misc/                           Single-application security hardening
  zen/                            Install scripts, extensions, startup script
.github/workflows/weekly-build.yml Weekly GHCR build + smoke test
```

## GitHub Actions

The `weekly-build.yml` workflow builds both images and pushes to GHCR weekly (Tuesday 04:00 UTC), with `workflow_dispatch` support for manual runs and a `base_tag` input override.
