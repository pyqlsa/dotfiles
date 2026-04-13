# @pyqkgs/pi-config-utils

A utility package for pi extensions and tools to retrieve configuration from `package-settings.json`.

## Overview

This package provides helper functions for pi packages (extensions, tools, etc.) to read their configuration settings from a centralized `package-settings.json` file. It's designed to be used as a dependency by other pi packages that need to access user-configurable settings.

## Installation

This package should be installed alongside your pi package. It's typically placed in `.pi/agent/packages/` as a sibling package to your main extension package.

**Directory structure:**
```
~/.pi/agent/packages/
├── pi-config-utils/          # This utility package
│   ├── index.ts
│   ├── package.json
│   └── README.md
└── your-extension/           # Your main extension package
    ├── extensions/
    └── package.json
```

## API

### `getPluginConfig(ctx, type, qualifiedName)`

Retrieves configuration for a specific plugin (extension or tool) from `package-settings.json`.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ctx` | `any` | Yes | The extension context (provides `agentDir`) |
| `type` | `'extensions' \| 'tools'` | Yes | The section to look in |
| `qualifiedName` | `string` | Yes | The URN-style name of the plugin (e.g., `'local:@pyqkgs/pi-tools:searxng_search'`) |

**Returns:**
- `Promise<object \| undefined>` - The configuration object if found, otherwise `undefined`

**Example:**
```typescript
import { getPluginConfig } from "@pyqkgs/pi-config-utils";

// In your extension's tool execute function
async function execute(toolCallId, params, signal, onUpdate, ctx) {
  const config = await getPluginConfig(
    ctx,
    "tools",
    "local:@pyqkgs/pi-tools:searxng_search"
  );

  const baseUrl = config?.baseUrl;
  // Use baseUrl...
}
```

## Configuration Format

Configuration is stored in `package-settings.json`, which is referenced by the `packageSettings` path in your main `settings.json`.

### 1. Main `settings.json`

First, configure the path to your package settings file:

```json
{
  "packageSettings": "./package-settings.json"
}
```

### 2. `package-settings.json`

Define your plugin configurations under the appropriate section (`extensions` or `tools`):

```json
{
  "tools": {
    "local:@pyqkgs/pi-tools:searxng_search": {
      "baseUrl": "https://your-searxng-instance.com/search"
    },
    "local:mytool:my_custom_tool": {
      "apiKey": "dont-hard-code-your-api-keys",
      "timeout": 30
    }
  },
  "extensions": {
    "local:myext:my_extension": {
      "enabled": true,
      "options": {
        "theme": "dark - like your soul"
      }
    }
  }
}
```

## Qualified Name Format

The `qualifiedName` parameter uses a URN-style naming convention:

```
<source>:<package>:<name>
```

**Examples:**
- `local:@pyqkgs/pi-tools:searxng_search` - Local pi-tools package, searxng_search tool
- `npm:@myorg/mytool:my_tool` - npm package @myorg/mytool, my_tool tool
- `local:myext:my_extension` - Local myext package, my_extension extension

**Components:**
- **source**: Where the package comes from (`local`, `npm`, `git`, etc.)
- **package**: Package name (without scope prefix for local packages)
- **name**: Specific tool or extension name within the package

## Usage Example

Here's a complete example of how to use this package in a pi extension:

```typescript
// my-extension.ts
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { getPluginConfig } from "@pyqkgs/pi-config-utils";

export default function(pi: ExtensionAPI) {
  pi.registerTool({
    name: "my_tool",
    label: "My Tool",
    description: "A tool that uses configuration",
    parameters: Type.Object({
      query: Type.String({ description: "The query" }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      // Get configuration for this tool
      const config = await getPluginConfig(
        ctx,
        "tools",
        "local:myext:my_tool"
      );

      const apiKey = config?.apiKey;

      if (!apiKey) {
        return {
          content: [{
            type: "text",
            text: "Error: API key not configured. Please set it in package-settings.json."
          }],
          details: { error: "MISSING_CONFIG" },
        };
      }

      // Use the API key...
      return {
        content: [{ type: "text", text: "Success!" }],
        details: {},
      };
    },
  });
}
```

## How It Works

1. **Reads global settings** - Creates a fresh `SettingsManager` to read the global settings
2. **Gets package settings path** - Reads the `packageSettings` path from settings
3. **Resolves absolute path** - Resolves the path relative to the agent directory
4. **Reads and parses** - Reads the `package-settings.json` file and parses it as JSON
5. **Returns configuration** - Returns the configuration object for the specified plugin type and name

## Error Handling

The function returns `undefined` in these cases:
- `packageSettings` path is not configured in settings
- `package-settings.json` file doesn't exist
- File cannot be read (permissions, etc.)
- JSON parsing fails
- Configuration for the specified plugin doesn't exist

This "fail silently" approach allows extensions to gracefully handle missing configuration and provide helpful error messages to users.

## Package Structure

This package is designed to be a **utility library**, not a pi extension itself. Note the empty `pi` manifest in `package.json`:

```json
{
  "pi": {
    "extensions": [],
    "skills": [],
    "prompts": [],
    "themes": []
  }
}
```

This tells pi: "This is a package, but it has no resources to load." It exists solely to be imported as a dependency by other packages.

## Installation in pi

Since this is a utility package, it should be installed alongside your main extension package in `.pi/agent/packages/`:

```bash
# Copy both packages to .pi/agent/packages/
cp -r ./packages/pi-config-utils ~/.pi/agent/packages/
cp -r ./packages/your-extension ~/.pi/agent/packages/
```

Then import it in your extension using a relative path:

```typescript
import { getPluginConfig } from "../../pi-config-utils/index.ts";
```

Or if using npm-style imports (when properly set up... but we don't do that here):

```typescript
import { getPluginConfig } from "@pyqkgs/pi-config-utils";
```

## Dependencies

- `@mariozechner/pi-coding-agent` (peer dependency) - Required for `SettingsManager` and `getAgentDir`

## License

MIT
