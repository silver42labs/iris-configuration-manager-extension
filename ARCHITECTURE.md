# IRIS Configuration Manager — Architecture

## Overview

This project is a unified WebExtension that runs on both **Chrome** and **Firefox**.

---

## Directory Structure

```txt
iris-configuration-manager/
├── src/                            # All source code
│   ├── platform/
│   │   └── browser-polyfill.js     # Browser API compatibility layer
│   ├── core/                       # Pure business logic (no browser APIs)
│   │   ├── bootstrap.js            # Backend installation orchestration
│   │   ├── compare.js              # Snapshot comparison engine
│   │   ├── registry.js             # Entity type configuration
│   │   └── strategies/
│   │       ├── entityCompare.js    # ID-based entity diff strategy
│   │       └── flatCompare.js      # Multiset diff strategy
│   ├── api.js                      # Server API layer (uses polyfill)
│   ├── storage.js                  # Browser storage abstraction (uses polyfill)
│   ├── popup.js                    # Popup UI controller (uses polyfill)
│   ├── report.js                   # Report renderer
│   ├── popup.html                  # Popup page
│   ├── report.html                 # Report page
│   ├── privacy.html                # Privacy policy page
│   ├── styles.css                  # Shared stylesheet
│   └── Migration.Framework.cls     # Backend ObjectScript class
├── manifests/                      # Browser-specific manifests
│   ├── chrome/
│   │   └── manifest.json
│   └── firefox/
│       └── manifest.json
├── icons/                          # Shared icon assets
├── scripts/
│   └── build.sh                    # Build script
├── dist/                           # Build output (git-ignored)
│   ├── chrome/                     # Ready-to-load Chrome extension
│   └── firefox/                    # Ready-to-load Firefox extension
├── docs/                           # Docs folder for Github Pages
│   └── privacy.html                # Privacy policy page accessible on the web
├── ARCHITECTURE.md                 # This file
├── README.md
├── LEIAME.md
└── LICENSE
```

---

## What Is Shared vs Browser-Specific

### Shared (100% of business logic)

| Module                    | Purpose                                   |
| ------------------------- | ----------------------------------------- |
| `core/compare.js`         | Snapshot comparison engine                |
| `core/registry.js`        | Entity type configuration (declarative)   |
| `core/bootstrap.js`       | Backend installation orchestration        |
| `core/strategies/*`       | Comparison strategies (entity & flat)     |
| `api.js`                  | Server communication (fetch, Atelier API) |
| `storage.js`              | Snapshot/report persistence               |
| `popup.js`                | Popup UI controller                       |
| `report.js`               | Report page renderer                      |
| All HTML/CSS              | UI markup and styles                      |
| `Migration.Framework.cls` | Backend ObjectScript class                |

### Browser-Specific

| Item                    | Chrome                                                                                       | Firefox                                                                               |
| ----------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **Manifest**            | No `optional_host_permissions`, no `content_security_policy`, no `browser_specific_settings` | Includes `optional_host_permissions`, `content_security_policy`, and `gecko` settings |
| **Runtime permissions** | Host permissions auto-granted at install; `ensureHostPermissions()` is a no-op               | Host permissions require runtime approval; `ensureHostPermissions()` prompts the user |

---

## How Browser Differences Are Handled

### Compatibility Layer (`platform/browser-polyfill.js`)

The three original repos differed only in which global they called:

- Chrome: `chrome.runtime`, `chrome.storage.local`, `chrome.tabs`
- Firefox: `browser.runtime`, `browser.storage.local`, `browser.tabs`

Rather than sprinkling conditionals throughout the code, a single **compatibility module** detects which global is available and re-exports it as `browser`. All other modules import from this single point:

```js
import { browser } from './platform/browser-polyfill.js';
```

In Chrome MV3, the `chrome.*` APIs already return Promises for the methods this extension uses (`storage`, `tabs`, `permissions`), so a simple alias is sufficient — no callback wrapping is needed.

### Runtime Permissions (`ensureHostPermissions` in popup.js)

Firefox MV3 does **not** auto-grant `host_permissions` declared in the manifest. The user must approve them at runtime. The `ensureHostPermissions()` function in `popup.js` handles this:

1. Checks `browser.permissions.contains()` — if already granted, returns immediately.
2. Calls `browser.permissions.request()` — prompts the user on Firefox.
3. On Chrome, step 1 always succeeds (permissions are pre-granted), making the function a harmless no-op.

This approach avoids duplicating `popup.js` between browsers. A single unified file works correctly on both.

### Manifests

Each browser has its own `manifest.json` under `manifests/<browser>/`. Key differences:

- **Firefox** requires `browser_specific_settings.gecko` (addon ID, min version, data collection declaration).
- **Firefox** requires `optional_host_permissions` for the runtime permission flow.
- **Firefox** requires an explicit `content_security_policy` for `connect-src`.
- **Chrome** does not need any of these.

The build script copies the correct manifest into the output directory.

---

## How to Build

### Prerequisites

- Bash (Linux/macOS, or WSL on Windows)

### Commands

```bash
# Build both browsers
./scripts/build.sh all

# Build Chrome only
./scripts/build.sh chrome

# Build Firefox only
./scripts/build.sh firefox
```

### Output

Build artifacts are placed in:

- `dist/chrome/` — load as unpacked extension in Chrome (`chrome://extensions`)
- `dist/firefox/` — load as temporary add-on in Firefox (`about:debugging`)

### Packaging for Store Submission

```bash
# Chrome
cd dist/chrome && zip -r ../../iris-configuration-manager-chrome.zip .

# Firefox
cd dist/firefox && zip -r ../../iris-configuration-manager-firefox.zip .
```

---

## Key Design Decisions

1. **Single polyfill over per-file branching.** All browser API differences are isolated in one 15-line module. This is simpler and less error-prone than `if (typeof chrome !== 'undefined')` guards throughout the code.

2. **Unified popup.js with permission guard.** Rather than maintaining two separate popup controllers (Chrome-without-permissions vs Firefox-with-permissions), a single `ensureHostPermissions()` function works correctly on both browsers. On Chrome it's a no-op since permissions are already granted.

3. **No bundler required.** The extension uses native ES modules (`<script type="module">`), which both Chrome and Firefox MV3 support. This eliminates build tool complexity while preserving clean module boundaries.

4. **Core logic has zero browser dependencies.** The `core/` directory contains pure JavaScript with no browser API calls. It imports from `../api.js` (which uses the polyfill), maintaining a clean dependency direction: `popup → core → api → polyfill`.

5. **Separate manifests over manifest merging.** Browser manifests differ enough that a template/merge approach would add complexity without savings. Two small JSON files are clearer.

---

## Trade-offs

- **`ensureHostPermissions` on Chrome is technically unnecessary** but kept for code unification. The overhead is a single `permissions.contains()` call that returns `true` immediately.

- **No automated tests** were added as part of this restructuring. The `core/` modules are pure functions and would be straightforward to unit test with any test runner.
