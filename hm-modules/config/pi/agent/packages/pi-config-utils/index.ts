import { resolve } from "node:path";
import { readFile } from "node:fs/promises";
import { SettingsManager, getAgentDir } from "@mariozechner/pi-coding-agent";

export type PluginConfigType = 'extensions' | 'tools';

/**
 * Retrieves configuration from a custom package-settings file.
 * 
 * @param ctx The extension context.
 * @param type The section to look in ('extensions' or 'tools').
 * @param qualifiedName The URN-style name (e.g., 'npm:@my-org/searxng-ext:searxng_search').
 * @returns The configuration object if found, otherwise undefined.
 */
export async function getPluginConfig(
  ctx: any, 
  type: PluginConfigType, 
  qualifiedName: string
) {
  try {
    // We use a fresh SettingsManager to ensure we can always read the disk,
    // as ctx.settingsManager might be undefined or restricted in some environments.
    const settings = SettingsManager.create();
    const globalSettings = settings.getGlobalSettings() as any;
    const packageSettingsPath = globalSettings.packageSettings;
    
    if (!packageSettingsPath) {
      return undefined;
    }

    // Resolve path relative to the agent directory, fallback to getAgentDir() or cwd
    const baseDir = ctx.agentDir || getAgentDir() || process.cwd();
    const absolutePath = resolve(baseDir, packageSettingsPath);
    
    const content = await readFile(absolutePath, "utf8");
    const config = JSON.parse(content);
    
    return config[type]?.[qualifiedName];
  } catch (error) {
    return undefined;
  }
}
