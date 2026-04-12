# SearXNG Extension for pi

This is a `pi` package that provides a web search tool using a SearXNG instance.

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

## Features

- **Web Search**: Provides the `searxng_search` tool to the agent.
- **Condensed Results**: Returns a clean, Markdown-formatted list of results for better LLM consumption.
- **JSON Mode**: Allows the agent to request raw JSON for more detailed parsing if needed.
