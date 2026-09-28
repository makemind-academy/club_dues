#!/usr/bin/env python3
"""club-dues: the smallest sample; one tap marks a member paid and the same tap undoes it."""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "tools"))
from appplayer import AppPlayer  # noqa: E402
from mcpclient import Server  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
SERVER = os.path.join(HERE, "dues_server")
CAP = os.path.join(HERE, "captures")
SERVER_ID = "com.makemind.sample.dues"

with Server(["dart", "run", "bin/server.dart"], cwd=SERVER) as s:
    assert s.call("dues.list")["paidCount"] == 3
    assert s.call("dues.toggle", {"who": "Amelia"})["paidCount"] == 4
    assert s.call("dues.toggle", {"who": "Amelia"})["paidCount"] == 3
screen = os.path.join(HERE, "dues.mbd", "ui", "pages", "dues.json")
lines = sum(1 for _ in open(screen))
assert lines <= 120, f"the screen grew to {lines} lines"

ap = AppPlayer()
ap.register_server(SERVER_ID, "Dues", cwd=SERVER)
ap.restart()
ap.open_server(SERVER_ID)
ap.wait_text("3 of 8 paid")
ap.expect_aligned("paid", min_rows=3)
ap.shot(f"{CAP}/01_before.png")
ap.tap("Amelia paid")
ap.wait_text("4 of 8 paid")
ap.shot(f"{CAP}/02_after_one_tap.png")
ap.tap("Amelia paid")
ap.wait_text("3 of 8 paid")
print("club-dues: one tap marks paid, the same tap undoes it")
