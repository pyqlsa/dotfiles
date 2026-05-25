# pi‑tools

**Purpose**: Tiny, single‑purpose tools for web search and URL scraping.

## Installation
```bash
# Already installed via Nix/Home‑Manager (no extra steps)
```

## Usage (TypeScript)
```ts
// Search the web (default 10 results, browser‑like UA)
await searxng_search({ query: "machine learning", userAgent: "Mozilla/5.0" });

// Scrape URLs with retry logic (3 retries, custom UA)
await web_scrape({
  urls: [
    "https://example.com/page1",
    "https://example.org/page2"
  ],
  numRetries: 3,
  userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
});
```
Both functions accept an optional `AbortSignal` for cancellation.

## Configuration
Configure via `settings.json` → `packageSettings.tools.<tool>`.

## Technical Details
- **Compression**: auto‑detect gzip/deflate/identity.
- **User‑Agent defaults**: `searxng_search` → `python-searxng-extension/1.0`; `web_scrape` → `python-web-scrape-extension/1.0`.
- **Retry logic**: exponential backoff (1 s → 2 s → 4 s, capped at 5 s).
- **Cancellation**: all functions accept an optional `AbortSignal` (or `signal`).

## License
MIT