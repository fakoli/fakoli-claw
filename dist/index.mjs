import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
const CREW_MENU = [
  "Fakoli crew \u2014 8 tier-routed specialists + orchestrator.",
  "",
  "Cloud (GPT-5.5): fakoli-orchestrator, fakoli-guido (architect), fakoli-critic (review gate), fakoli-sentinel (QA).",
  "Local (SGLang): fakoli-welder (integration), fakoli-smith (plugin eng), fakoli-scout (research), fakoli-herald (docs), fakoli-keeper (infra).",
  "",
  "The orchestrator dispatches specialists in parallel waves via sessions_spawn + sessions_yield,",
  "gates each code wave with fakoli-critic, and finishes with fakoli-sentinel.",
  'Run a wave:  openclaw agent --agent fakoli-orchestrator -m "Execute the plan at <path> ..."'
].join("\n");
const FLOW_MENU = [
  "fakoli-flow pipeline (OpenClaw skills):",
  "  flow:brainstorm  \u2014 refine an idea into an approved spec (one question at a time)",
  "  flow:plan        \u2014 break the spec into an intent-driven task list (WHAT, not HOW)",
  "  flow:execute     \u2014 wave-based crew dispatch + critic gates + sentinel evidence gate",
  "  flow:verify      \u2014 evidence-based validation scorecard",
  "  flow:finish      \u2014 ship: merge / PR / keep / discard (explicit choice only)",
  "  flow:quick <t>   \u2014 fast path for changes under 3 files (one agent + critic gate)",
  "",
  "Pipeline:  brainstorm -> plan -> execute -> verify -> finish   (quick skips the middle)",
  "Invoke a stage by triggering its skill (e.g. the flow-execute skill)."
].join("\n");
var index_default = definePluginEntry({
  id: "fakoli-claw",
  name: "fakoli-claw",
  description: "The Fakoli suite on OpenClaw: specialist crew + wave orchestration, local-first and tier-routed.",
  register(api) {
    api.registerCommand("crew", {
      description: "Show the Fakoli specialist crew and how the orchestrator runs waves.",
      argumentHint: "",
      handler: async () => ({ text: CREW_MENU })
    });
    api.registerCommand("flow", {
      description: "Show the fakoli-flow pipeline (brainstorm -> plan -> execute -> verify -> finish, + quick).",
      argumentHint: "[brainstorm|plan|execute|verify|finish|quick]",
      handler: async () => ({ text: FLOW_MENU })
    });
    try {
      api.registerHook?.({
        event: "SessionStart",
        id: "fakoli-detect-context",
        handler: async () => ({
          text: "[fakoli-flow] crew + flow ready. Skills: brainstorm, plan, execute, verify, finish, quick. State MCP (fakoli-state) exposes durable PRD/plan/claim tools when installed."
        })
      });
    } catch {
    }
  }
});
export {
  index_default as default
};
