## Working Windows + WSL workaround found — `codex_app` remains functional

I reproduced the `invalid transport in mcp_servers.codex_app` failure deterministically on the affected Windows + WSL Desktop path and found a working workaround that restores the original Codex Desktop **without disabling `codex_app`, without `/bin/false`, and without modifying `app.asar`**.

### Tested setup

- Codex Desktop: `26.820.60940`
- MSIX: `OpenAI.Codex_26.820.7780.0_x64__2p2nqsd0c76g0`
- Desktop-managed WSL CLI: `0.150.0-alpha.8`
- bundled `codex-app-tools`: `0.1.3`
- Ubuntu under WSL

### Decisive finding

The affected Desktop uses:

```text
mcp_servers.codex_app.enabled_tools
```

Direct `app-server` / `thread/resume` testing showed:

```text
dotted leaf, no base transport       -> INVALID_TRANSPORT
dotted leaf + valid startup base     -> THREAD_OK
nested leaf + valid startup base     -> INVALID_TRANSPORT
dotted full runtime config           -> THREAD_OK
nested full runtime config           -> THREAD_OK
```

The Desktop-style dotted leaf therefore merges correctly **when a valid `codex_app` base transport already exists**.

Static analysis of this build strongly suggests the local WSL launch path does not materialize the complete `getConfigOverrides()`-provided `codex_app` base before spawning the WSL CLI. I am treating this as root-cause evidence rather than a claim about intended architecture.

### Working workaround

```toml
[mcp_servers.codex_app]

command = "/mnt/c/Windows/System32/cmd.exe"

args = [
  "/d", "/s", "/c", "call",
  "./scripts/launch_codex_app_tools_mcp.cmd",
  "./server.mjs"
]

cwd = "/mnt/c/Users/<USER>/.codex/plugins/cache/openai-bundled/codex-app-tools/0.1.3"
enabled = true
startup_timeout_sec = 10
tool_timeout_sec = 3600

env = { CODEX_MCP_NODE_PATH = 'C:\Users\<USER>\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' }

env_vars = ["CODEX_APP_TOOLS_PIPE_PATH"]
```

The userspace Node was required on this setup because the packaged Node under `WindowsApps` returned `Access denied` through the WSL/`cmd.exe` bridge.

### End-to-end validation

After restarting the **original Codex Desktop**:

- the `invalid transport` failure disappeared;
- normal Desktop and project/workspace chats worked;
- all five Codex app tools were exposed:
  `automation_update`, `create_thread`, `send_message_to_thread`, `fork_thread`, `handoff_thread`;
- a **real `create_thread` invocation succeeded** with `hostId: local`;
- the child chat was created successfully.

I also confirmed that applying:

```text
mcp_servers.codex_app.enabled_tools=["automation_update"]
```

preserves stdio transport, command, and cwd when the base exists.

Full reproduction package, sanitized config, validation script, and evidence screenshot:

https://github.com/AetheraSoftware/aethera-codex-40715-wsl-workaround

**Alexsander Oliveira**  
Founder & Technical Director  
Aethera Engenharia & Software  
GitHub: **@AetheraSoftware**  
Brazil
