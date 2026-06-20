# pi‑config‑utils

**Purpose**: Helper functions for reading configuration from `settings.json`.

## Installation
```bash
# Already installed via Nix/Home‑Manager (no extra steps)
```

## API
```ts
import { getPluginConfig } from "pi-config-utils";

// Returns `undefined` when the requested config is missing
const cfg = await getPluginConfig(
  ctx,                     // the extension context
  "tools",                 // section name in `packageSettings`
  "local:pi-tools:searxng_search"   // qualified name of the plugin
);
```

## Quick Example
```ts
// Fetch a tool’s config and use its `baseUrl`
const cfg = await getPluginConfig(ctx, "tools", "local:pi-tools:searxng_search");
if (cfg?.baseUrl) {
  console.log(`Using base URL: ${cfg.baseUrl}`);
}
```

## Technical Details
- **Compression**: auto‑detect gzip/deflate/identity.
- **User‑Agent defaults**: `searxng_search` → `python-searxng-extension/1.0`; `web_scrape` → `python-web-scrape-extension/1.0`.
- **Retry logic**: exponential backoff (1 s → 2 s → 4 s, capped at 5 s).
- **Cancellation**: all functions accept an optional `AbortSignal` (or `signal`).

## License
MIT