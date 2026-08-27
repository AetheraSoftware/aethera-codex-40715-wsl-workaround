# Reproduction notes

Critical matrix:

```text
R1000 dotted_leaf_no_base                -> INVALID_TRANSPORT
R1001 dotted_leaf_plus_startup_base      -> THREAD_OK
R1002 nested_leaf_plus_startup_base      -> INVALID_TRANSPORT
R1003 dotted_full_runtime                -> THREAD_OK
R1004 nested_full_runtime                -> THREAD_OK
```

Conclusion:

```text
DOTTED_LEAF_MERGES_WITH_STARTUP_BASE
```

The Desktop bundle uses:

```text
mcp_servers.codex_app.enabled_tools
```

The official launcher worked when `CODEX_MCP_NODE_PATH` pointed to the userspace Codex runtime Node.

End-to-end validation: a real `create_thread` invocation succeeded with `hostId: local` and created a child chat.

Large proprietary application artifacts are intentionally not redistributed.
