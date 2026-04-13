# pi-tools for pi-coding-agent

This is a `pi` package that provides a number of small (hopefully) useful tools.

## Features

- **`searxng_search`**: Search the web using SearXNG with configurable result count and User-Agent
- **`web_scrape`**: Scrape content from URLs with retry logic, compression support, and configurable User-Agent
- **Flexible**: Optional custom User-Agent for interacting with site in interesting ways
- **Robust compression**: Supports gzip, deflate, and uncompressed responses with automatic detection
- **Retry logic**: Exponential backoff for failed requests with configurable retry count

## Installation

You can install this package locally:

```bash
pi install ./pi/agent/packages/pi-tools
```

Or add it to your `settings.json`:

```json
{
  "packages": [
    "./pi/agent/packages/pi-tools"
  ]
}
```

## Configuration

Search is powered by SearXNG, and the tool can be configured using `package-settings.json`:

First, ensure your `pi` agent `settings.json` has and extra `packageSettings` path defined (non-standard for `pi`):

```json
{
  "packageSettings": "./package-settings.json"
}
```

Then, in your `package-settings.json`, add the SearXNG configuration:

```json
{
  "tools": {
    "local:@pyqkgs/pi-tools:searxng_search": {
      "baseUrl": "https://your-searxng-instance.com/search"
    }
  }
}
```

Really, the `packageSettings` path can be anything, as long as it's relative to `pi`'s `settings.json` and actually exists.

Other tools in this package follow the same configuration convention, if they ever require their own config.

## Tools

### 1. `searxng_search`

Search the web using SearXNG via a Python backend.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | Yes | - | The search query |
| `condense` | boolean | No | `true` | If `true`, returns a condensed, readable list of results. If `false`, returns raw JSON |
| `numResults` | integer | No | `10` | Number of results to return (range: 1-100) |
| `userAgent` | string | No | `python-searxng-extension/1.0` | User-Agent header to use. |

**Example Usage:**

```typescript
// Basic search with default 10 results and default User-Agent
searxng_search({ query: "machine learning tutorials" })

// Search with specific number of results
searxng_search({
  query: "weather forecast",
  numResults: 5
})

// Get raw JSON results
searxng_search({
  query: "API documentation",
  condense: false,
  numResults: 20
})

// Use a browser-like User-Agent
searxng_search({
  query: "test query",
  userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
})
```

**Output Format (condensed):**
```
1. [Title of Result 1](https://example.com) - Brief snippet of the result

2. [Title of Result 2](https://example.org) - Another snippet

3. [Title of Result 3](https://example.net) - More content
```

---

### 2. `web_scrape`

Scrape content from a list of URLs with automatic retry logic for reliability. Designed to work with URLs gathered from `searxng_search` results.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `urls` | string[] | Yes | - | List of URLs to scrape (1-20 URLs) |
| `numRetries` | integer | No | `3` | Maximum retry attempts per URL on failure (range: 0-10) |
| `userAgent` | string | No | `python-web-scrape-extension/1.0` | User-Agent header to use |

**Features:**

- **Retry Logic**: Automatically retries failed requests with exponential backoff (1s, 2s, 4s, max 5s)
- **Smart Content Extraction**: Removes scripts, styles, ads, navigation, footers, and other non-content elements
- **Polite Scraping**: 500ms delay between requests to avoid overwhelming servers
- **Compression Support**: Handles gzip, deflate, and uncompressed responses with automatic detection
- **Content Validation**: Only returns pages with meaningful content (>50 characters)
- **Error Handling**: Tracks retry counts and reports detailed error messages
- **Cancellation Support**: Respects abort signals for graceful cancellation

**Example Usage:**

```typescript
// Scrape single URL with default User-Agent
web_scrape({
  urls: ["https://example.com/page"]
})

// Scrape multiple URLs with custom retry count
web_scrape({
  urls: [
    "https://example.com/page1",
    "https://example.org/page2",
    "https://example.net/page3"
  ],
  numRetries: 5
})

// Scrape with no retries (fail fast)
web_scrape({
  urls: ["https://example.com"],
  numRetries: 0
})

// Use a browser-like User-Agent
web_scrape({
  urls: ["https://example.com"],
  userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
})
```

**Output Format:**
```
== Web Scraping Results ==
Total URLs: 3
Successful: 2
Failed: 1
Total retries: 2

--- Result 1 ---
URL: https://example.com/page1
Title: Page Title
Content:
[Extracted text content from the page...]

--------------------------------------------------

--- Result 2 ---
URL: https://example.org/page2
Title: Another Page
Retries: 1
Error: Failed after 3 attempts: HTTP 404: Not Found

--------------------------------------------------
```

---

## Common Workflows

### Workflow 1: Search and Scrape

1. **Search for information:**
   ```typescript
   searxng_search({
     query: "best machine learning resources 2026",
     numResults: 5
   })
   ```

2. **Extract URLs from results and scrape:**
   ```typescript
   web_scrape({
     urls: [
       "https://www.geeksforgeeks.org/machine-learning/",
       "https://developers.google.com/machine-learning/crash-course",
       "https://www.tensorflow.org/tutorials"
     ],
     numRetries: 3
   })
   ```

### Workflow 2: Limited Search for Quick Info

```typescript
// Get just 3 results for a quick answer
searxng_search({
  query: "current weather Tokyo",
  numResults: 3,
  condense: true
})
```

### Workflow 3: Using Browser User-Agent

```typescript
// Some sites behave differently when using a User-Agent that is browser-like
searxng_search({
  query: "test query",
  userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
})

web_scrape({
  urls: ["https://example.com"],
  userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
})
```

### Workflow 4: Deep Dive with Raw Data

```typescript
// Get full JSON with many results for detailed analysis
searxng_search({
  query: "Python async programming",
  numResults: 50,
  condense: false
})
```

## Technical Details

### Compression Support

The tools support multiple compression formats with explicit priority:

```
Accept-Encoding: gzip;q=1.0, deflate;q=0.8, identity;q=0.5
```

- **gzip**: Most preferred, best compression ratio
- **deflate**: Secondary option, handled with zlib
- **identity**: Fallback for uncompressed responses
- **Other formats (br, zstd, etc.)**: Not supported (forbidden by omission)

The tools also include **magic byte detection** to handle servers that send compressed data without proper `content-encoding` headers.

### User-Agent Defaults

- **`searxng_search`**: `python-searxng-extension/1.0`
- **`web_scrape`**: `python-web-scrape-extension/1.0`

These User-Agents identify the tools clearly. Use the `userAgent` parameter to override with browser-like User-Agents when needed.

### Retry Logic

- **Exponential backoff**: 1s, 2s, 4s (max 5s between retries)
- **Configurable**: Set `numRetries` from 0 to 10
- **Smart**: Doesn't retry on certain errors (e.g., non-HTML content)

## Troubleshooting

### "Error: SearXNG base_url is not configured"

Make sure you've configured the SearXNG URL in `package-settings.json` under `tools.local:searxng:searxng_search.baseUrl`.

### "Failed after X attempts" errors

This typically means:
- The URL is not accessible (check if it's blocked or requires authentication)
- The server is down or responding slowly
- The page doesn't contain meaningful text content

Try increasing `numRetries` or checking the URL manually.

### Limited or no content extracted

Some websites use JavaScript-heavy rendering or have paywalls. The scraper extracts static HTML content only. For such sites, consider using the raw search results instead.

### Sites blocking requests

Some sites may block requests from non-browser User-Agents. Use the `userAgent` parameter with a browser-like User-Agent:

```typescript
web_scrape({
  urls: ["https://example.com"],
  userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
})
```

## Architecture

- **Single TypeScript entry point**: `extensions/index.ts` registers both tools
- **Python CLIs**: `searxng_cli.py` and `web_scrape_cli.py` handle the heavy lifting
- **Clean separation**: TypeScript handles tool registration, Python handles HTTP/HTML processing

## License

MIT
