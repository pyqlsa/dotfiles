import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { getPluginConfig } from "../config-utils";
import { SettingsManager } from "@mariozechner/pi-coding-agent";

/**
 * SearXNG Search Extension
 * Wraps a Python-based SearXNG CLI tool for use in pi.
 */
export default function (pi: ExtensionAPI) {
  // Get the path to the Python script relative to this extension file
  const extensionDir = path.dirname(fileURLToPath(import.meta.url));
  const pythonScriptPath = path.resolve(extensionDir, "searxng_cli.py");

  // Configuration: Use package-settings.json via qualified name, 
  // then environment variable. No hard-coded default.
  const QUALIFIED_TOOL_NAME = "local:searxng:searxng_search";

  pi.registerTool({
    name: "searxng_search",
    label: "SearXNG Search",
    description: "Search the web using SearXNG via a Python backend",
    promptSnippet: "Search the web for information",
    promptGuidelines: [
      "Use this tool when you need up-to-date information from the internet.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "The search query" }),
      condense: Type.Optional(Type.Boolean({ 
        description: "If true, returns a condensed, readable list of results. If false, returns raw JSON.",
        default: true 
      })),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const { query, condense = true } = params;

      // 1. Try to get config from package-settings.json
      // 2. Fallback to environment variable
      const pluginConfig = await getPluginConfig(ctx, 'tools', QUALIFIED_TOOL_NAME);
      const base_url = pluginConfig?.baseUrl || process.env.SEARXNG_BASE_URL;

      if (!base_url) {
        return {
          content: [{
            type: "text",
            text: `Error: SearXNG base_url is not configured.\n` +
                  `Please set it in your package-settings.json (under 'tools.${QUALIFIED_TOOL_NAME}.baseUrl') ` +
                  `or via the SEARXNG_BASE_URL environment variable.`
          }],
          details: { error: "MISSING_CONFIG" },
        };
      }

      onUpdate?.({
        content: [{ type: "text", text: `Searching for "${query}"...` }],
      });

      const format = condense ? "condensed" : "json";
      const args = [
        pythonScriptPath, 
        query, 
        "--format", 
        format,
        "--base-url",
        base_url
      ];

      try {
        const result = await pi.exec("python3", args, { signal });

        if (result.code !== 0) {
          return {
            content: [{ type: "text", text: `Error executing search: ${result.stderr || result.stdout}` }],
            details: { exitCode: result.code, stderr: result.stderr, base_url },
          };
        }

        return {
          content: [{ type: "text", text: result.stdout.trim() }],
          details: { query, format, base_url },
        };
      } catch (error: any) {
        return {
          content: [{ type: "text", text: `Exception during search execution: ${error.message}` }],
          details: { error: error.message, base_url },
        };
      }
    },
  });
}
