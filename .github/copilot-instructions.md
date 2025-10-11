## Using MCP Server for Azure DevOps

If the user has configured MCP Server for Azure DevOps in their `~/.config/mcp-config.json` file, use that server to get work items instead of GitHub issues.

Always assume the MCP Server for Azure DevOps is named `azure-devops` in the configuration file. If the user asks something related to Azure DevOps work items, always try to use the MCP Server for Azure DevOps.

When getting work items using MCP Server for Azure DevOps, always try to use batch tools for updates instead of many individual single updates. For updates, try and update up to 200 updates in a single batch. When getting work items, once you get the list of IDs, use the tool `get_work_items_batch_by_ids` to get the work item details. By default, show fields ID, Type, Title, State. Show work item results in a rendered markdown table.