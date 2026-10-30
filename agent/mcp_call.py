"""Call an MCP server's tools directly: `list`, or `<tool> '<json args>'`."""
import asyncio, json, os, sys
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

async def main():
    name = sys.argv[1]
    args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    async with streamablehttp_client(os.environ["MCP_URL"]) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            if name == "list":
                for t in (await session.list_tools()).tools:
                    print(f"{t.name}: {t.description}")
                return
            result = await session.call_tool(name, args)
            for block in result.content:
                print(getattr(block, "text", block))

asyncio.run(main())
