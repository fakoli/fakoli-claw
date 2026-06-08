import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
const CREW_MENU = [
  "Fakoli crew \u2014 9 tier-routed agents (orchestrator + 8 specialists).",
  "",
  "Cloud (GPT-5.5): fakoli-orchestrator, fakoli-guido (architect), fakoli-critic (review gate), fakoli-sentinel (QA).",
  "Local (SGLang): fakoli-welder (integration), fakoli-smith (plugin eng), fakoli-scout (research), fakoli-herald (docs), fakoli-keeper (infra).",
  "",
  "The orchestrator dispatches specialists in parallel waves via sessions_spawn + sessions_yield,",
  "gates each code wave with fakoli-critic, and finishes with a fakoli-sentinel evidence scorecard.",
  'Run a wave:  openclaw agent --agent fakoli-orchestrator -m "Execute the plan at <path> ..."'
].join("\n");
const FLOW_MENU = [
  "fakoli-flow pipeline (OpenClaw skills):",
  "  flow-brainstorm  \u2014 refine an idea into an approved spec (one question at a time)",
  "  flow-plan        \u2014 break the spec into an intent-driven task list (WHAT, not HOW)",
  "  flow-execute     \u2014 wave-based crew dispatch + critic gates + sentinel evidence gate",
  "  flow-verify      \u2014 evidence-based validation scorecard",
  "  flow-finish      \u2014 ship: merge / PR / keep / discard (explicit choice only)",
  "  flow-quick <t>   \u2014 fast path for changes under 3 files",
  "",
  "Pipeline:  brainstorm -> plan -> execute -> verify -> finish   (quick skips the middle).",
  "Trigger a stage by invoking its skill (e.g. the flow-execute skill on fakoli-orchestrator)."
].join("\n");
var index_default = definePluginEntry({
  id: "fakoli-claw",
  name: "fakoli-claw",
  description: "The Fakoli suite on OpenClaw: specialist crew + wave orchestration, local-first and tier-routed.",
  register(api) {
    api.registerCommand({
      name: "crew",
      description: "Show the Fakoli specialist crew and how the orchestrator runs waves.",
      handler: async () => ({ text: CREW_MENU })
    });
    api.registerCommand({
      name: "flow",
      description: "Show the fakoli-flow pipeline (brainstorm -> plan -> execute -> verify -> finish, + quick).",
      handler: async () => ({ text: FLOW_MENU })
    });
  }
});
export {
  index_default as default
};
