# Codex Desktop Windows + WSL: `mcp_servers.codex_app` invalid transport workaround

> Independent technical investigation and reproducible workaround for OpenAI Codex Desktop issue `openai/codex #40715`.

## Summary

On an affected Codex Desktop Windows + WSL installation, Codex failed with:

```text
failed to load configuration: invalid transport in mcp_servers.codex_app
```

We reproduced the failure deterministically and validated a workaround that restores the original Codex Desktop **without modifying `app.asar`, without disabling `codex_app`, and without using `/bin/false`**.

A real `create_thread` invocation succeeded with `hostId: local` and created a child chat.

![Successful real create_thread invocation](evidence/create-thread-success.png)

## Tested environment

- Codex Desktop: `26.820.60940`
- Windows MSIX: `OpenAI.Codex_26.820.7780.0_x64__2p2nqsd0c76g0`
- Desktop-managed WSL CLI: `0.150.0-alpha.8`
- bundled `codex-app-tools`: `0.1.3`
- Ubuntu under WSL

## Decisive finding

The affected Desktop uses:

```text
mcp_servers.codex_app.enabled_tools
```

Direct `app-server` / `thread/resume` experiments showed:

```text
dotted leaf, no base transport       -> INVALID_TRANSPORT
dotted leaf + valid startup base     -> THREAD_OK
nested leaf + valid startup base     -> INVALID_TRANSPORT
dotted full runtime config           -> THREAD_OK
nested full runtime config           -> THREAD_OK
```

Therefore, the Desktop-style dotted leaf merges correctly **if a complete `codex_app` base transport is already present**.

Static inspection of the affected Desktop build also found the startup `getConfigOverrides()` path that supplies the complete bundled `codex_app` config. Analysis of the local WSL launch path strongly suggests this base is not materialized before the WSL CLI is spawned. This is root-cause evidence, not a statement about OpenAI's intended architecture.

## Working workaround

Back up `config.toml` first, then add a complete WSL-visible base:

```toml
[mcp_servers.codex_app]

command = "/mnt/c/Windows/System32/cmd.exe"

args = [
  "/d",
  "/s",
  "/c",
  "call",
  "./scripts/launch_codex_app_tools_mcp.cmd",
  "./server.mjs"
]

cwd = "/mnt/c/Users/<USER>/.codex/plugins/cache/openai-bundled/codex-app-tools/0.1.3"

enabled = true
startup_timeout_sec = 10
tool_timeout_sec = 3600

env = { CODEX_MCP_NODE_PATH = 'C:\Users\<USER>\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' }

env_vars = [
  "CODEX_APP_TOOLS_PIPE_PATH"
]
```

Adjust `<USER>` and the plugin version/path to match the installation.

On this setup, the Node executable packaged under `WindowsApps` was visible but returned `Access denied` through the WSL/`cmd.exe` bridge. The userspace Codex runtime Node worked successfully.

## Validation

With the workaround active:

```text
codex_app
  enabled: true
  transport: stdio
  command: /mnt/c/Windows/System32/cmd.exe
  cwd: .../codex-app-tools/0.1.3
```

Applying:

```text
mcp_servers.codex_app.enabled_tools=["automation_update"]
```

preserved the stdio transport, command, and cwd.

After restarting the **original Codex Desktop**:

- `invalid transport in mcp_servers.codex_app` disappeared;
- normal Desktop chat operation worked;
- project/workspace chat operation worked;
- all five Codex app tools were exposed:
  - `automation_update`
  - `create_thread`
  - `send_message_to_thread`
  - `fork_thread`
  - `handoff_thread`
- a **real `create_thread` invocation succeeded**;
- `hostId` was `local`;
- a child chat was created successfully.

This demonstrates that the workaround restores the MCP tool path rather than merely silencing the parser error.

## Upstream implication

The evidence points to a narrow class of upstream fixes:

1. ensure the local Windows + WSL launch path materializes the complete `mcp_servers.codex_app` transport before spawning the WSL CLI/app-server; and/or
2. guarantee that thread/request-level dotted `mcp_servers.codex_app.enabled_tools` is merged only after a complete base transport exists.

## Scope and cautions

- Unofficial temporary workaround; not an OpenAI release.
- Back up `config.toml`.
- Paths/plugin versions may change after updates.
- Never publish `CODEX_APP_TOOLS_PIPE_PATH` values or auth/runtime secrets.
- No proprietary OpenAI application bundle is redistributed here.
- Re-evaluate/remove the workaround after an official fix.

## Attribution

**Alexsander Oliveira**  
Founder & Technical Director — **Aethera Engenharia & Software**  
GitHub: **@AetheraSoftware**  
Brazil

Investigation and validation performed by Aethera Engenharia & Software using an AI-assisted debugging workflow.
