# IRIS Configuration Manager

Deploy a configuration manager API to any InterSystems IRIS/Cache server that exposes `/api/atelier`, capture its configuration snapshot, and compare it against another server in minutes. This extension turns a manual, error-prone migration checklist into a repeatable diff report you can trust.

[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/silver42labs/iris-configuration-manager-extension/blob/main/README.md)
[![pt-br](https://img.shields.io/badge/lang-pt--br-green.svg)](https://github.com/silver42labs/iris-configuration-manager-extension/blob/main/LEIAME.md)

## Supported Browsers

- Google Chrome (Manifest V3) [Chrome Web Store](https://chromewebstore.google.com/detail/iris-configuration-manage/anamganabilobholichagldbejkpclag)
- Mozilla Firefox (Manifest V3) [Firefox Add-ons (AMO)](https://addons.mozilla.org/en-US/firefox/addon/iris-migration-checklist/).

## How to run this extension locally

### Build

```bash
# Build for both browsers
./scripts/build.sh all

# Or target a specific browser
./scripts/build.sh chrome
./scripts/build.sh firefox
```

### Load in Chrome

1. Go to `chrome://extensions`
2. Enable "Developer mode"
3. Click "Load unpacked" → select `dist/chrome/`

### Load in Firefox

1. Go to `about:debugging#/runtime/this-firefox`
2. Click "Load Temporary Add-on" → select `dist/firefox/manifest.json`

## Usage

1. Navigate to the IRIS management portal of your source server.
2. Click the extension icon and press **Save Server Data**.
3. Navigate to your target server.
4. Click the extension icon and press **Compare to Saved Server**.
5. A new tab opens with the comparison report.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for details on the project structure, browser compatibility layer, and design decisions.

## Privacy

The extension stores all data locally and communicates only with the IRIS/Caché servers you connect to. See the [Privacy Policy](src/docs/privacy.html) for full details.

## License

MIT — see [LICENSE](LICENSE).
