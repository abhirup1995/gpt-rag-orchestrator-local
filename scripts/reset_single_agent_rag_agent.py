"""One-off script: push a new version of the cached 'single_agent_rag' prompt
agent so it picks up changed instructions/tools (there is no delete_agent in
agent_provider_v2.py's versioned-agent pattern -- create_version is the reset
mechanism). Restart the orchestrator process after running this so its
in-process _agent_details_cache is cleared and re-resolves to the new version.

Run from the repo root with the same venv/az login the app uses:
    python scripts/reset_single_agent_rag_agent.py
"""
import asyncio
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from dependencies import get_config  # noqa: E402
from connectors.identity_manager import get_identity_manager  # noqa: E402
from strategies import agent_provider_v2  # noqa: E402
from strategies.single_agent_rag_strategy_v2 import (  # noqa: E402
    _render_agent_instructions,
    _resolve_agent_name,
    search_knowledge_base,
)
from azure.ai.projects.models import PromptAgentDefinition, Reasoning  # noqa: E402
from agent_framework import normalize_tools  # noqa: E402
from agent_framework_azure_ai._shared import to_azure_ai_tools  # noqa: E402

logging.basicConfig(level=logging.INFO)


async def main() -> None:
    cfg = get_config()
    endpoint = cfg.get("AI_FOUNDRY_PROJECT_ENDPOINT")
    if not endpoint:
        raise SystemExit("AI_FOUNDRY_PROJECT_ENDPOINT is not set")

    credential = get_identity_manager().get_aio_credential()
    provider = await agent_provider_v2.get_provider(endpoint, credential)

    name = _resolve_agent_name(cfg)
    aisearch_enabled = cfg.get("SEARCH_RETRIEVAL_ENABLED", True, type=bool)
    instructions = _render_agent_instructions(cfg, aisearch_enabled=aisearch_enabled)
    tools = [search_knowledge_base] if aisearch_enabled else None
    reasoning_effort = cfg.get("REASONING_EFFORT", "low")

    azure_tools = to_azure_ai_tools(normalize_tools(tools)) if tools else None
    definition = PromptAgentDefinition(
        model=cfg.get("CHAT_DEPLOYMENT_NAME"),
        instructions=instructions,
        tools=azure_tools,
        reasoning=Reasoning(effort=reasoning_effort),
    )

    client = agent_provider_v2._project_client  # populated by get_provider() above
    await client.agents.create_version(agent_name=name, definition=definition)
    print(f"Pushed new version for agent '{name}'. Restart the orchestrator process now.")


if __name__ == "__main__":
    asyncio.run(main())
