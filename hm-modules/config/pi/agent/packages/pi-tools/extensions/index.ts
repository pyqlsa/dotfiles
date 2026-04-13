/**
 * SearXNG Extension Package
 *
 * Provides web search and web scraping tools for pi.
 * - searxng_search: Search the web using SearXNG
 * - web_scrape: Scrape content from URLs with retry logic
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { getPluginConfig } from "../../pi-config-utils/index.ts";

// Get the directory containing this file
const extensionDir = path.dirname(fileURLToPath(import.meta.url));

// Paths to Python CLI tools
const SEARXNG_CLI_PATH = path.resolve(extensionDir, "searxng_cli.py");
const WEB_SCRAPER_CLI_PATH = path.resolve(extensionDir, "web_scrape_cli.py");

// Configuration key for searxng
const SEARXNG_QUALIFIED_TOOL_NAME = "local:@pyqkgs/pi-tools:searxng_search";
const WEB_SCRAPE_QUALIFIED_TOOL_NAME = "local:@pyqkgs/pi-tools:web_scrape";

// Default User-Agents
const DEFAULT_SEARXNG_UA = "python-searxng-extension/1.0";
const DEFAULT_WEB_SCRAPE_UA = "python-web-scrape-extension/1.0";

export default function(pi: ExtensionAPI) {
  /**
   * Tool 1: SearXNG Search
   * Searches the web using a SearXNG instance
   */
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
      condense: Type.Optional(
        Type.Boolean({
          description:
            "If true, returns a condensed, readable list of results. If false, returns raw JSON.",
          default: true,
        }),
      ),
      numResults: Type.Optional(
        Type.Integer({
          description: "Number of results to return (default: 10)",
          minimum: 1,
          maximum: 100,
          default: 10,
        }),
      ),
      userAgent: Type.Optional(
        Type.String({
          description: `User-Agent header to use (default: ${DEFAULT_SEARXNG_UA}). Some sites behave differently when using a browser-like (or more creative) User-Agent.`,
          examples: [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            DEFAULT_SEARXNG_UA,
          ],
        }),
      ),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const { query, condense = true, numResults = 10, userAgent } = params;

      // Get configuration
      const pluginConfig = await getPluginConfig(
        ctx,
        "tools",
        SEARXNG_QUALIFIED_TOOL_NAME,
      );
      const base_url = pluginConfig?.baseUrl;

      if (!base_url) {
        return {
          content: [
            {
              type: "text",
              text:
                `Error: SearXNG base_url is not configured.\n` +
                `Please set it in your package-settings.json (under 'tools.${SEARXNG_QUALIFIED_TOOL_NAME}.baseUrl').`,
            },
          ],
          details: { error: "MISSING_CONFIG" },
        };
      }

      onUpdate?.({
        content: [{ type: "text", text: `Searching for "${query}"...` }],
      });

      const format = condense ? "condensed" : "json";
      const args = [
        SEARXNG_CLI_PATH,
        query,
        "--format",
        format,
        "--base-url",
        base_url,
        "--num-results",
        String(numResults),
      ];

      // Add user-agent if specified
      if (userAgent) {
        args.push("--user-agent", userAgent);
      }

      try {
        const result = await pi.exec("python3", args, { signal });

        if (result.code !== 0) {
          return {
            content: [
              {
                type: "text",
                text: `Error executing search: ${result.stderr || result.stdout}`,
              },
            ],
            details: { exitCode: result.code, stderr: result.stderr, base_url },
          };
        }

        return {
          content: [{ type: "text", text: result.stdout.trim() }],
          details: { query, format, base_url },
        };
      } catch (error: any) {
        return {
          content: [
            {
              type: "text",
              text: `Exception during search execution: ${error.message}`,
            },
          ],
          details: { error: error.message, base_url },
        };
      }
    },
  });

  /**
   * Tool 2: Web Scrape
   * Scrapes content from a list of URLs with retry logic
   */
  pi.registerTool({
    name: "web_scrape",
    label: "Web Scrape",
    description:
      "Scrape content from a list of URLs. Fetches and extracts text content from web pages with retry logic for reliability.",
    promptSnippet: "Scrape content from specific URLs",
    promptGuidelines: [
      "Use this tool to extract actual content from web pages.",
      "Pass URLs gathered from searxng_search results to get detailed information.",
      "The tool will retry failed requests automatically (configurable).",
      "Returns extracted text content from each URL, with error handling for failures.",
    ],
    parameters: Type.Object({
      urls: Type.Array(
        Type.String({
          format: "uri",
          description: "A URL to scrape",
        }),
        {
          description: "List of URLs to scrape",
          minItems: 1,
          maxItems: 20,
        },
      ),
      numRetries: Type.Optional(
        Type.Integer({
          description:
            "Maximum number of retry attempts per URL on failure (default: 3)",
          minimum: 0,
          maximum: 10,
          default: 3,
        }),
      ),
      userAgent: Type.Optional(
        Type.String({
          description: `User-Agent header to use (default: ${DEFAULT_WEB_SCRAPE_UA}). Some sites behave differently when using a browser-like (or more creative) User-Agent.`,
          examples: [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            DEFAULT_WEB_SCRAPE_UA,
          ],
        }),
      ),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const { urls, numRetries = 3, userAgent } = params;

      if (urls.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: "Error: No URLs provided.",
            },
          ],
          details: { error: "NO_URLS" },
        };
      }

      onUpdate?.({
        content: [
          {
            type: "text",
            text: `Scraping ${urls.length} URL(s) with up to ${numRetries} retries each...`,
          },
        ],
      });

      // Build command to call Python CLI
      // Pass URLs as positional arguments
      const args = [
        WEB_SCRAPER_CLI_PATH,
        ...urls.map((u) => u.trim()),
        "--retries",
        String(numRetries),
        "--output",
        "json",
      ];

      // Add user-agent if specified
      if (userAgent) {
        args.push("--user-agent", userAgent);
      }

      try {
        const result = await pi.exec("python3", args, { signal });

        if (result.code !== 0) {
          return {
            content: [
              {
                type: "text",
                text: `Error executing web scraper: ${result.stderr || result.stdout}`,
              },
            ],
            details: { exitCode: result.code, stderr: result.stderr },
          };
        }

        // Parse JSON results from Python CLI
        let scrapedResults: Array<{
          url: string;
          title?: string;
          text?: string;
          error?: string;
          retry_count?: number;
        }>;

        try {
          scrapedResults = JSON.parse(result.stdout);
        } catch (parseError) {
          return {
            content: [
              {
                type: "text",
                text: `Error parsing scraper output: ${parseError.message}\n\nRaw output:\n${result.stdout}`,
              },
            ],
            details: { error: "PARSE_ERROR", rawOutput: result.stdout },
          };
        }

        // Calculate statistics
        const successCount = scrapedResults.filter((r) => r.text).length;
        const failedCount = scrapedResults.filter((r) => r.error).length;
        const totalRetries = scrapedResults.reduce(
          (sum, r) => sum + (r.retry_count || 0),
          0,
        );

        // Format output
        const outputLines: string[] = [
          `== Web Scraping Results ==`,
          `Total URLs: ${urls.length}`,
          `Successful: ${successCount}`,
          `Failed: ${failedCount}`,
          `Total retries: ${totalRetries}`,
          "",
        ];

        for (const [i, result] of scrapedResults.entries()) {
          outputLines.push(`--- Result ${i + 1} ---`);
          outputLines.push(`URL: ${result.url}`);

          if (result.title) {
            outputLines.push(`Title: ${result.title}`);
          }

          if (result.retry_count && result.retry_count > 0) {
            outputLines.push(`Retries: ${result.retry_count}`);
          }

          if (result.error) {
            outputLines.push(`Error: ${result.error}`);
          } else if (result.text) {
            outputLines.push("");
            outputLines.push("Content:");
            outputLines.push(result.text);
          }

          outputLines.push("");
          outputLines.push("-".repeat(50));
          outputLines.push("");
        }

        return {
          content: [
            {
              type: "text",
              text: outputLines.join("\n"),
            },
          ],
          details: {
            totalUrls: urls.length,
            successCount,
            failedCount,
            totalRetries,
            urls: urls.map((url, i) => ({
              url,
              success: !!scrapedResults[i]?.text,
              error: scrapedResults[i]?.error,
            })),
          },
        };
      } catch (error: any) {
        return {
          content: [
            {
              type: "text",
              text: `Exception during web scraping: ${error.message}`,
            },
          ],
          details: { error: error.message },
        };
      }
    },
  });
}
