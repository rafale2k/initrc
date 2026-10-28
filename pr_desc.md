🎯 **What:** Added missing tests for the `set_monokai_colors` function in `common/_system.sh`.
📊 **Coverage:** Covered both interactive and non-interactive shell scenarios. Verified that the correct Monokai palette ANSI escape sequences are output when the shell is interactive, and that no output is produced when non-interactive. Used `sed` replacements in the BATS `setup` to enable mocking of `$EUID` and interactive shell state (`$-`).
✨ **Result:** Improved test coverage for terminal coloring functionality and guarded against regressions.
