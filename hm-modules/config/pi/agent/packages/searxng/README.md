# SearXNG Extension for pi

This is a `pi` package that provides web search and scraping tools using a SearXNG instance.

## Installation

You can install this package locally:

```bash
pi install ./path/to/hm-modules/config/pi/agent/packages/searxng
```

Or add it to your `settings.json`:

```json
{
  "packages": [
    "./hm-modules/config/pi/agent/packages/searxng"
  ]
}
```

## Configuration

You can configure the SearXNG instance using one of the following methods:

### 1. Using `package-settings.json` (Recommended)

First, ensure your `settings.json` has the `packageSettings` path defined:

```json
{
  "packageSettings": "./package-settings.json"
}
```

Then, in your `package-settings.json`, add the SearXNG configuration:

```json
{
  "tools": {
    "local:searxng:searxng_search": {
      "baseUrl": "https://your-searxng-instance.com/search"
    }
  }
}
```

### 2. Using an Environment Variable

Alternatively, you can set the `SEARXNG_BASE_URL` environment variable:

```bash
export SEARXNG_BASE_URL="https://your-searxng-instance.com/search"
pi
```

## Tools

### 1. `searxng_search`

Search the web using SearXNG via a Python backend.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | Yes | - | The search query |
| `condense` | boolean | No | `true` | If `true`, returns a condensed, readable list of results. If `false`, returns raw JSON |
| `numResults` | integer | No | `10` | Number of results to return (range: 1-100) |

**Example Usage:**

```typescript
// Basic search with default 10 results
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

**Features:**

- **Retry Logic**: Automatically retries failed requests with exponential backoff (1s, 2s, 4s, max 5s)
- **Smart Content Extraction**: Removes scripts, styles, ads, navigation, footers, and other non-content elements
- **Polite Scraping**: 500ms delay between requests to avoid overwhelming servers
- **Content Validation**: Only returns pages with meaningful content (>50 characters)
- **Error Handling**: Tracks retry counts and reports detailed error messages
- **Cancellation Support**: Respects abort signals for graceful cancellation

**Example Usage:**

```typescript
// Scrape single URL
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
     query: "best machine learning resources 2024", 
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

### Workflow 3: Deep Dive with Raw Data

```typescript
// Get full JSON with many results for detailed analysis
searxng_search({ 
  query: "Python async programming", 
  numResults: 50,
  condense: false 
})
```

## Troubleshooting

### "Error: SearXNG base_url is not configured"

Make sure you've configured the SearXNG URL either in `package-settings.json` or via the `SEARXNG_BASE_URL` environment variable.

### "Failed after X attempts" errors

This typically means:
- The URL is not accessible (check if it's blocked or requires authentication)
- The server is down or responding slowly
- The page doesn't contain meaningful text content

Try increasing `numRetries` or checking the URL manually.

### Limited or no content extracted

Some websites use JavaScript-heavy rendering or have paywalls. The scraper extracts static HTML content only. For such sites, consider using the raw search results instead.

## License

MIT
