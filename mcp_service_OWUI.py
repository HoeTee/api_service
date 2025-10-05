# id: mcp_playwright_agent_extra
# name: MCP Playwright Agent Extra
# description: Spins up Playwright MCP via npx, runs an Autogen agent over MCP, and returns the final assistant message.

import asyncio, os, shutil
from typing import Optional, List, Any

# --- Autogen imports (ensure installed in OWUI backend env) ---
# pip install autogen-agentchat autogen-ext
from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.ui import Console
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_ext.tools.mcp import McpWorkbench, StdioServerParams


def _build_model_client(
    model_override: Optional[str] = None,
) -> OpenAIChatCompletionClient:

    return OpenAIChatCompletionClient(
        model=model_override or "glm-4.5",
        base_url="https://open.bigmodel.cn/api/paas/v4",  # None means default OpenAI API base
        api_key="cf44dc21645b46e5ad4fc19706e9dfe7.VgJ3CLdY0flKzgBc",
        model_info={
            "vision": False,
            "function_calling": True,
            "json_output": False,
            "family": (model_override or "glm-4.5"),
            "structured_output": True,
        },
    )


async def _run_agent(
    task: str, headless: bool, max_iters: int, model_override: Optional[str]
) -> str:
    # 1) Check npx availability early
    if not shutil.which("npx"):
        return (
            "npx not found on PATH. Install Node.js and npm, then run:\n"
            "npm install -g @playwright/mcp@latest\n"
            "Also run once: npx playwright install"
        )

    # 2) Build MCP server params
    mcp_args: List[str] = ["@playwright/mcp@latest"]
    if headless:
        mcp_args.append("--headless")
    server_params = StdioServerParams(command="playwright-mcp", args=["--headless"])

    # 3) Create workbench + agent and run
    async with McpWorkbench(server_params) as mcp:
        agent = AssistantAgent(
            "web_browsing_assistant",
            model_client=_build_model_client(model_override),
            workbench=mcp,
            model_client_stream=False,  # disable streaming for safety
            max_tool_iterations=max(1, min(int(max_iters), 50)),
        )
        result = await agent.run(task=task)

        # 4) Return agent's reply as string
        try:
            return result.text if hasattr(result, "text") else str(result)
        except Exception:
            return str(result)



class Tools:
    """
    OpenWebUI class-based tool.
    """

    # Mandatory metadata
    id = "mcp_playwright_agent_extra"
    name = "MCP Playwright Agent Extra"
    description = "Launches Playwright MCP via npx, runs an Autogen agent over MCP, and returns the final assistant message."

    # JSON Schema describing inputs OpenWebUI will show
    input_schema = {
        "type": "object",
        "properties": {
            "task": {
                "type": "string",
                "description": 'Natural-language task (e.g., "Find how many contributors microsoft/autogen has").',
            },
            "headless": {
                "type": "boolean",
                "description": "Run Playwright MCP with --headless",
                "default": True,
            },
            "max_tool_iterations": {
                "type": "integer",
                "description": "Safety cap on MCP tool-call loops (1..50)",
                "default": 10,
            },
            "model": {
                "type": "string",
                "description": "Override model id (else OWUI_MCP_MODEL or fallback)",
                "default": "",
            },
        },
        "required": ["task"],
    }

    def _run_coro_in_new_thread(self, coro):
        import threading, queue

        q = queue.Queue(maxsize=1)

        def _worker():
            try:
                result = asyncio.run(coro)
                q.put(("ok", result))
            except Exception as e:
                q.put(("err", e))

        t = threading.Thread(target=_worker, daemon=True)
        t.start()
        status, payload = q.get()
        if status == "ok":
            return payload
        raise payload

    # Main entrypoint
    def run(
        self,
        task: str = "",
        headless: bool = True,
        max_tool_iterations: int = 10,
        model: str = "",
        **rest  # ← swallow any planner junk (url/actions/etc.)
    ) -> str:

        task = (task or "").strip()
        # 5) Run the agent exactly as before
        coro = _run_agent(
            task=task,
            headless=headless,
            max_iters=max_tool_iterations,
            model_override=(model or None),
        )
        try:
            loop = asyncio.get_running_loop()
            # If already in an event loop → use thread helper
            return self._run_coro_in_new_thread(coro)
        except RuntimeError:
            # No loop → safe to asyncio.run directly
            return asyncio.run(coro)
