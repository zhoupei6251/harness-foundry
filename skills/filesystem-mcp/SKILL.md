---
name: filesystem-mcp
description: Filesystem operations via official Filesystem MCP. Read, write, list,
  search, and manage files and directories using mcp__filesystem__* tools. Use when
  you need structured filesystem operations beyond Claude Code built-in tools, or when
  working with specific directory paths in agent workflows.
metadata:
  origin: harness-foundry
  version: 1.0.0
when_to_use: 调用 filesystem-mcp 时，或需要文件系统 MCP 操作时
status: peripheral
tags:
- shared
domain: code
category: shared.workflow
---
# Filesystem MCP

Filesystem operations via the official `@modelcontextprotocol/server-filesystem` MCP server.

## When to Use

- When you need structured filesystem operations (read_file, write_file, list_directory)
- When working with specific directory paths that the Filesystem MCP is configured to serve
- When the agent workflow benefits from Filesystem MCP tools instead of Claude Code built-in tools
- For cross-platform filesystem operations with consistent tool naming

## Prerequisites

The Filesystem MCP must be configured in your MCP settings:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/your/projects"]
    }
  }
}
```

> **Note**: Replace `/path/to/your/projects` with your actual project directory path.

## MCP Tools

The Filesystem MCP provides these tools:

| Tool | Description |
|------|-------------|
| `read_file` | Read the complete contents of a file |
| `write_file` | Create or overwrite a file with content |
| `edit_file` | Apply a patch to a file (line-based editing) |
| `list_directory` | List contents of a directory with metadata |
| `create_directory` | Create a new directory (optionally recursive) |
| `move_file` | Move or rename a file or directory |
| `search_files` | Recursively search for files matching a pattern |
| `get_path` | Get the configured root path |

## Usage Examples

### Read a File

```
mcp__filesystem__read_file({ path: "/path/to/project/README.md" })
```

### Write a File

```
mcp__filesystem__write_file({
  path: "/path/to/project/output.txt",
  content: "File contents here"
})
```

### List Directory

```
mcp__filesystem__list_directory({ path: "/path/to/project/src" })
```

### Search Files

```
mcp__filesystem__search_files({
  path: "/path/to/project",
  pattern: "*.md"
})
```

### Create Directory

```
mcp__filesystem__create_directory({
  path: "/path/to/project/new-folder",
  recursive: true
})
```

## Best Practices

- **Configure the root path** to the minimum necessary directory for security
- **Use read_file** for files that are already in Claude Code's working directory
- **Use write_file** with caution — it can overwrite existing files
- **Prefer Claude Code built-in tools** (Read, Write, Edit) for files in the working directory
- **Use Filesystem MCP** when working with paths outside the Claude Code working directory

## Comparison with Claude Code Built-in Tools

| Operation | Claude Code Built-in | Filesystem MCP |
|-----------|---------------------|----------------|
| Read file | `Read` | `mcp__filesystem__read_file` |
| Write file | `Write` | `mcp__filesystem__write_file` |
| Edit file | `Edit` | `mcp__filesystem__edit_file` |
| List directory | `Bash ls` | `mcp__filesystem__list_directory` |
| Find files | `Glob` | `mcp__filesystem__search_files` |
| Create directory | `Bash mkdir` | `mcp__filesystem__create_directory` |

Use Filesystem MCP when you need:
- Operations on paths outside Claude Code's working directory
- Structured tool responses for programmatic workflows
- Consistent cross-platform filesystem behavior
