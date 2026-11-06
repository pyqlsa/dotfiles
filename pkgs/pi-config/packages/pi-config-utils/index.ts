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

    return packageSettings?.[type]?.[qualifiedName];
  } catch {
    // Fail soft: a missing or unreadable config just means "no override".
    // NOTE: never console.log()/print here. Extensions execute inside pi's
    // own process (see docs/how-pi-works.md), so any write to stdout lands on
    // the same fd as its TUI and corrupts the rendered screen — pi renders
    // incrementally and cannot resync around out-of-band writes.
    //
    // Use ctx.ui.notify()/setStatus() for user-facing feedback instead, and if
    // diagnostics are needed, gate them behind an env var writing to a file.
    return undefined;
  }
}
