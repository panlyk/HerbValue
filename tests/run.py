"""Optional Lua 5.1 runner: python -m pip install lupa; python tests/run.py [Auctionator-dir]."""
import sys
from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parent.parent
if Path.cwd() != root:
    raise SystemExit("Run from the repository root")
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().arg = lua.table_from(dict(enumerate(sys.argv[1:], 1)))
lua.execute((root / "tests/run.lua").read_text())
