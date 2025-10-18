#!/usr/bin/env python3
import sys, subprocess, os
from pathlib import Path

PROP = Path.home() / ".termux" / "termux.properties"

def set_fullscreen(enable: bool):
    PROP.parent.mkdir(parents=True, exist_ok=True)
    lines = []
    if PROP.exists():
        lines = PROP.read_text().splitlines()

    def upsert(key, val):
        for i, line in enumerate(lines):
            if line.startswith(key+"="):
                lines[i] = f"{key}={val}"
                return
        lines.append(f"{key}={val}")

    upsert("fullscreen", "true" if enable else "false")
    upsert("use-fullscreen-workaround", "true" if enable else "false")

    PROP.write_text("\n".join(lines) + "\n")
    subprocess.run(["termux-reload-settings"])

if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in ("on","off","toggle","status"):
        print("Usage: python3 toggle_fullscreen.py [on|off|toggle|status]")
        sys.exit(1)

    props = {}
    if PROP.exists():
        for line in PROP.read_text().splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                props[k.strip()] = v.strip()
    current = props.get("fullscreen") == "true"

    cmd = sys.argv[1]
    if cmd == "status":
        print(f"fullscreen={'ON' if current else 'OFF'}")
        print(f"use-fullscreen-workaround={props.get('use-fullscreen-workaround','(unset)')}")
        sys.exit(0)

    target = (cmd == "on") or (cmd == "toggle" and not current)
    set_fullscreen(target)
    print(f"Fullscreen set to {'ON' if target else 'OFF'}")
