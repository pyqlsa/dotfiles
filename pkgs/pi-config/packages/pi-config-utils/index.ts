import { resolve } from "node:path";
import { readFile } from "node:fs/promises";
import { SettingsManager, getAgentDir } from "@mariozechner/pi-coding-agent";
import { cwd } from "node:process";

export type PluginConfigType = "extensions" | "tools";

/**
 * Retrieves configuration from a `packageSettings` in `settings.json` file.
 *
 * @param ctx The extension context.
 * @param type The section to look in ('extensions' or 'tools').
 * @param qualifiedName The URN-style name (e.g., 'npm:@my-org/searxng-ext:searxng_search').
 * @returns The configuration object if found, otherwise undefined.
 */
export async function getPluginConfig(
  ctx: any,
  type: PluginConfigType,
  qualifiedName: string,
) {
  try {
    // We use a fresh SettingsManager to ensure we can always read the disk,
    // as ctx.settingsManager might be undefined or restricted in some environments.
    const agentDir = getAgentDir();
    const settings = SettingsManager.create(cwd(), agentDir);
    const globalSettings = settings.getGlobalSettings() as any;
    const packageSettings = (globalSettings as any).packageSettings;
    console.log("[getPluginConfig] packageSettings:", JSON.stringify(packageSettings, null, 2));
    console.log("[getPluginConfig] type:", type);
    console.log("[getPluginConfig] qualifiedName:", qualifiedName);
    console.log("[getPluginConfig] result:", packageSettings[type]?.[qualifiedName]);

    return packageSettings[type]?.[qualifiedName];
  } catch (error) {
    console.log("[getPluginConfig] Error:", error);
    return undefined;
  }
}
