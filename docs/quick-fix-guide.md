# Beginner Quick-Fix Guide — Codex Desktop on Windows + WSL

> A step-by-step version of the Aethera workaround for people who just want Codex Desktop to work again.
>
> This is an **unofficial, temporary workaround** for [`openai/codex #40715`](https://github.com/openai/codex/issues/40715). It is not an OpenAI release or official fix.

## Who should use this guide?

Use this guide only if all of the following are true:

- you use **Codex Desktop on Windows**;
- your Codex agent/workspace runs through **WSL / Ubuntu**;
- Codex Desktop shows an error similar to:

```text
failed to load configuration: invalid transport in mcp_servers.codex_app
```

or:

```text
ChatGPT can't load config.toml, so this thread can't resume.
Fix config.toml: invalid transport in mcp_servers.codex_app
```

This workaround was validated on:

- Codex Desktop `26.820.60940`;
- Windows MSIX `OpenAI.Codex_26.820.7780.0`;
- Desktop-managed WSL CLI `0.150.0-alpha.8`;
- bundled `codex-app-tools` `0.1.3`;
- Ubuntu under WSL.

If your versions are different, the folder names may also be different. Do not blindly copy a version number that is not installed on your computer.

---

## What this workaround does

The affected Desktop path can reach the WSL app-server with an incomplete `mcp_servers.codex_app` configuration. Codex then rejects it because the MCP server has no valid transport.

The workaround adds a complete user-level `mcp_servers.codex_app` definition so that the Desktop-provided `enabled_tools` setting has a valid base configuration to merge into.

It does **not**:

- modify `app.asar`;
- disable `codex_app`;
- use `/bin/false`;
- replace OpenAI application files;
- require you to know or manually enter `CODEX_APP_TOOLS_PIPE_PATH`.

The real pipe-path value is runtime data. **Do not publish or hard-code it.**

---

# Step 1 — Fully close Codex Desktop

Do not leave it merely minimized.

Close Codex Desktop completely before editing the configuration. If it has a tray icon, exit the application from there as well.

Leave your Ubuntu / WSL terminal open.

---

# Step 2 — Find your Windows username

Inside Ubuntu / WSL, run:

```bash
/mnt/c/Windows/System32/cmd.exe /d /s /c echo %USERNAME%
```

Example output:

```text
Alex
```

In the rest of this guide, replace every occurrence of `<USER>` with the username printed by that command.

For example:

```text
/mnt/c/Users/<USER>/.codex
```

would become:

```text
/mnt/c/Users/Alex/.codex
```

Do **not** literally leave `<USER>` in your final configuration.

---

# Step 3 — Check that your Codex configuration folder exists

Run:

```bash
ls "/mnt/c/Users/<USER>/.codex"
```

You should see the Codex user directory and normally a `config.toml` file.

If this path does not exist, stop here and verify that you used the correct Windows username.

---

# Step 4 — Back up `config.toml`

This step is important.

If `config.toml` already exists, run:

```bash
cp "/mnt/c/Users/<USER>/.codex/config.toml" "/mnt/c/Users/<USER>/.codex/config.toml.backup-40715"
```

Confirm the backup exists:

```bash
ls -l "/mnt/c/Users/<USER>/.codex/config.toml" "/mnt/c/Users/<USER>/.codex/config.toml.backup-40715"
```

If you make a mistake later, this backup lets you restore your previous configuration.

---

# Step 5 — Find the installed `codex-app-tools` version

Run:

```bash
ls -1 "/mnt/c/Users/<USER>/.codex/plugins/cache/openai-bundled/codex-app-tools/"
```

On the system used for the Aethera validation, the result was:

```text
0.1.3
```

Your installation may show a different version.

Remember the version you actually see. In this guide it will be called `<PLUGIN_VERSION>`.

Example:

```text
<PLUGIN_VERSION> = 0.1.3
```

Check that the official launcher and server are present:

```bash
ls -l "/mnt/c/Users/<USER>/.codex/plugins/cache/openai-bundled/codex-app-tools/<PLUGIN_VERSION>/scripts/launch_codex_app_tools_mcp.cmd" \
      "/mnt/c/Users/<USER>/.codex/plugins/cache/openai-bundled/codex-app-tools/<PLUGIN_VERSION>/server.mjs"
```

Both files should be listed.

If they are missing, stop rather than inventing another path.

---

# Step 6 — Check the userspace Codex Node runtime

The validated workaround used the Codex userspace runtime Node at:

```text
C:\Users\<USER>\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe
```

From WSL, check whether it exists:

```bash
ls -l "/mnt/c/Users/<USER>/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe"
```

If the file is listed, continue to Step 7.

### If that exact Node path does not exist

Search the Codex userspace runtimes:

```bash
find "/mnt/c/Users/<USER>/.cache/codex-runtimes" -type f -iname 'node.exe' -print 2>/dev/null
```

Use a Node executable belonging to the Codex **userspace runtime**, not a WindowsApps-packaged Node.

On the affected system used for validation, the WindowsApps-packaged Node was visible but returned `Access denied` when invoked through the WSL / `cmd.exe` bridge. The userspace Codex runtime Node worked.

If you cannot identify a suitable userspace Codex runtime Node, stop here rather than guessing.

---

# Step 7 — Make sure you will not create a duplicate TOML table

Before editing, check whether `config.toml` already contains a `codex_app` MCP table:

```bash
grep -n '^\[mcp_servers\.codex_app\]' "/mnt/c/Users/<USER>/.codex/config.toml" || true
```

### If nothing is printed

Good. You can add the block in Step 8.

### If a line is printed

Do **not** add a second `[mcp_servers.codex_app]` table. TOML duplicate tables can cause another configuration error.

Back up the file as shown above and replace/update the existing `codex_app` block instead of appending a duplicate.

---

# Step 8 — Open `config.toml`

A simple editor available in most Ubuntu installations is `nano`:

```bash
nano "/mnt/c/Users/<USER>/.codex/config.toml"
```

Go to the end of the file and add the block from Step 9.

---

# Step 9 — Add the complete `codex_app` configuration

Paste this block into `config.toml`:

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

cwd = "/mnt/c/Users/<USER>/.codex/plugins/cache/openai-bundled/codex-app-tools/<PLUGIN_VERSION>"

enabled = true
startup_timeout_sec = 10
tool_timeout_sec = 3600

env = { CODEX_MCP_NODE_PATH = 'C:\Users\<USER>\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' }

env_vars = [
  "CODEX_APP_TOOLS_PIPE_PATH"
]
```

Now make the two required substitutions:

1. replace every `<USER>` with your real Windows username;
2. replace `<PLUGIN_VERSION>` with the version found in Step 5.

Example only, if the Windows username is `Alex` and the plugin version is `0.1.3`:

```toml
cwd = "/mnt/c/Users/Alex/.codex/plugins/cache/openai-bundled/codex-app-tools/0.1.3"

env = { CODEX_MCP_NODE_PATH = 'C:\Users\Alex\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' }
```

Do not copy the example username unless it is actually yours.

### Important: `CODEX_APP_TOOLS_PIPE_PATH`

Leave this exactly as:

```toml
env_vars = [
  "CODEX_APP_TOOLS_PIPE_PATH"
]
```

Do **not** add a real pipe value to the file. The application supplies the runtime value through the environment.

---

# Step 10 — Save the file

In `nano`:

1. press `Ctrl+O`;
2. press `Enter` to confirm the filename;
3. press `Ctrl+X` to exit.

---

# Step 11 — Check for obvious placeholder mistakes

Run:

```bash
grep -nE '<USER>|<PLUGIN_VERSION>' "/mnt/c/Users/<USER>/.codex/config.toml" || true
```

If the command prints one of the new lines you just added, you forgot to replace a placeholder.

Fix it before opening Codex Desktop.

You can also inspect only the relevant part of the configuration:

```bash
grep -n -A30 '^\[mcp_servers\.codex_app\]' "/mnt/c/Users/<USER>/.codex/config.toml"
```

Make sure no secrets or manually entered pipe values are present.

---

# Step 12 — Reopen the original Codex Desktop

Start Codex Desktop normally from Windows.

Do not launch a modified copy of the application.

The Aethera validation was performed against the **original affected Codex Desktop** after the workaround had been placed in the normal user configuration.

---

# Step 13 — Test the actual problem

First, create a completely new normal chat.

Then test a chat in the WSL project/workspace that previously failed.

The expected result is that this error no longer appears:

```text
invalid transport in mcp_servers.codex_app
```

During the Aethera end-to-end validation:

- normal Desktop chat worked;
- project/workspace chat worked;
- `codex_app` remained enabled;
- all five Codex app tools were exposed;
- a real `create_thread` call succeeded with `hostId: local`;
- the child chat was actually created.

This is important because the workaround restores the MCP tool path rather than merely hiding the parser error.

---

# Optional Step 14 — Technical validation from WSL

If you are comfortable with the Codex CLI, this repository also contains:

```text
scripts/validate-codex-app.sh
```

It checks the base `codex_app` definition, applies a dotted `enabled_tools` override, and confirms that the transport information remains present.

See:

- [`../scripts/validate-codex-app.sh`](../scripts/validate-codex-app.sh)
- [`../config.example.toml`](../config.example.toml)
- [`../README.md`](../README.md)

The script is optional. For a beginner, successfully reopening Codex Desktop and creating/resuming the previously failing WSL chats is the most important functional test.

---

# If it still does not work

Check these items in order.

## 1. Did you fully restart Codex Desktop?

Minimizing it is not enough. Exit the application completely and start it again.

## 2. Is the Windows username correct in both paths?

Check:

```bash
/mnt/c/Windows/System32/cmd.exe /d /s /c echo %USERNAME%
```

Then compare the result with your `cwd` and `CODEX_MCP_NODE_PATH` values.

## 3. Is the plugin version correct?

Check again:

```bash
ls -1 "/mnt/c/Users/<USER>/.codex/plugins/cache/openai-bundled/codex-app-tools/"
```

If your installation no longer uses `0.1.3`, your `cwd` must use the version that is actually installed.

## 4. Does the launcher exist at the configured `cwd`?

Run:

```bash
ls -l "/mnt/c/Users/<USER>/.codex/plugins/cache/openai-bundled/codex-app-tools/<PLUGIN_VERSION>/scripts/launch_codex_app_tools_mcp.cmd"
```

## 5. Does the userspace Node executable exist?

Run:

```bash
ls -l "/mnt/c/Users/<USER>/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe"
```

## 6. Did you accidentally create two `[mcp_servers.codex_app]` tables?

Run:

```bash
grep -n '^\[mcp_servers\.codex_app\]' "/mnt/c/Users/<USER>/.codex/config.toml"
```

There should normally be one user-level table, not two copies of the workaround.

## 7. Did you hard-code `CODEX_APP_TOOLS_PIPE_PATH`?

Do not do that.

The workaround should contain only:

```toml
env_vars = [
  "CODEX_APP_TOOLS_PIPE_PATH"
]
```

Never publish or manually copy a real pipe-path value from another system.

---

# How to undo the workaround

If you made the backup exactly as shown in this guide, fully close Codex Desktop and restore it with:

```bash
cp "/mnt/c/Users/<USER>/.codex/config.toml.backup-40715" "/mnt/c/Users/<USER>/.codex/config.toml"
```

Then reopen Codex Desktop.

Alternatively, if you know how to edit TOML safely, remove only the `[mcp_servers.codex_app]` block that you added.

Do not delete your entire `.codex` directory.

---

# What to do after OpenAI ships an official fix

This workaround is intentionally temporary.

When OpenAI publishes a confirmed fix for the affected Desktop path:

1. update Codex Desktop;
2. fully restart it;
3. back up your current configuration;
4. remove the temporary user-level `[mcp_servers.codex_app]` workaround;
5. restart Codex Desktop again;
6. verify that new and existing WSL chats work without the workaround.

Do not remove a working workaround solely because a newer version number exists. First confirm that the official release actually addresses the relevant issue.

Track the upstream issue here:

- [`openai/codex #40715`](https://github.com/openai/codex/issues/40715)

---

# Want the technical explanation?

This document intentionally avoids the full debugging story.

For the evidence, test matrix, root-cause analysis, and end-to-end validation, see:

- [`README.md`](../README.md)
- [`docs/reproduction.md`](reproduction.md)
- [`config.example.toml`](../config.example.toml)
- [`scripts/validate-codex-app.sh`](../scripts/validate-codex-app.sh)

The technical investigation showed:

```text
dotted leaf, no base transport       -> INVALID_TRANSPORT
dotted leaf + valid startup base     -> THREAD_OK
nested leaf + valid startup base     -> INVALID_TRANSPORT
dotted full runtime config           -> THREAD_OK
nested full runtime config           -> THREAD_OK
```

The beginner takeaway is much simpler:

> the affected Desktop path needs a complete, valid `codex_app` base transport before the Desktop-provided tool configuration is merged.

---

## Safety notes

- Back up `config.toml` before changing it.
- Use paths and versions that actually exist on your computer.
- Do not download replacement OpenAI application bundles from strangers.
- Do not publish runtime pipe values, authentication data, tokens, or secrets.
- Do not modify `app.asar` for this workaround.
- Do not delete your entire `.codex` directory.
- This workaround is independent research by Aethera Engenharia & Software, not an official OpenAI fix.
