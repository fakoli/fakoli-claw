// fakoli-claw — OpenClaw plugin entry point.
//
// Registers the Fakoli `/crew` and `/flow` commands, context-detection hooks,
// and (later) the wave-orchestration tooling.
//
// NOTE: the specialist agents themselves are shipped as `agents.list[]` config
// (see `config/fakoli-claw.openclaw.json5`), because OpenClaw agents are
// configured, not registered programmatically. This plugin provides the
// command/hook/skill surface around them.
import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "fakoli-claw",
  name: "fakoli-claw",
  description: "The Fakoli suite on OpenClaw: specialist crew + wave orchestration.",
  register(api) {
    // Phase C — commands:
    //   api.registerCommand({ name: "crew", ... });   // /crew menu
    //   api.registerCommand({ name: "flow", ... });   // /flow:brainstorm|plan|execute|verify|finish|quick
    // Phase D — hooks:
    //   api.registerHook({ ... });                    // detect-context (language / crew availability)
    // Phase B — optional wave helper tool:
    //   api.registerTool({ name: "fakoli_wave", ... });
    void api;
  },
});
