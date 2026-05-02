#!/usr/bin/env python3
import json
import os
import re
import shutil
import subprocess
from typing import Optional


def map_layout(layout: str) -> str:
    l = (layout or "").strip().lower()
    if l.startswith("russian") or l.startswith("ru") or l.startswith("rus") or "рус" in l:
        return "R"
    if l.startswith("english") or l.startswith("en") or l.startswith("eng") or l == "us":
        return "E"
    return "?"


def resolve_hyprctl() -> Optional[str]:
    p = shutil.which("hyprctl")
    if p:
        return p
    for cand in ("/usr/bin/hyprctl", "/usr/sbin/hyprctl"):
        if os.path.exists(cand) and os.access(cand, os.X_OK):
            return cand
    return None


def _run_json(cmd: list[str]) -> Optional[dict]:
    try:
        out = subprocess.check_output(cmd, text=True, timeout=1.5)
        return json.loads(out)
    except Exception:
        return None


def _devices_json(hyprctl_bin: str) -> Optional[dict]:
    data = _run_json([hyprctl_bin, "devices", "-j"])
    if data:
        return data

    inst_data = _run_json([hyprctl_bin, "instances", "-j"])
    if isinstance(inst_data, list) and inst_data:
        data = _run_json([hyprctl_bin, "-i", "0", "devices", "-j"])
        if data:
            return data
        for inst in inst_data:
            sig = str(inst.get("instance") or "").strip()
            if not sig:
                continue
            data = _run_json([hyprctl_bin, "-i", sig, "devices", "-j"])
            if data:
                return data
    return None


def get_layout_from_hyprctl(hyprctl_bin: str) -> str:
    data = _devices_json(hyprctl_bin)
    if not data:
        return ""

    def km(kbd):
        return (
            kbd.get("active_keymap")
            or kbd.get("active_keymap_short_description")
            or kbd.get("active_keymap_short")
            or kbd.get("active_keymap_variant")
            or ""
        )

    def is_virtual(name: str) -> bool:
        return bool(re.search(r"virtual|vkeyboard|vkbd|wvkbd", name or "", re.I))

    keyboards = data.get("keyboards") or []

    def score(kbd) -> int:
        name = (kbd.get("name") or "").lower()
        s = 0
        if kbd.get("main") is True:
            s += 100
        if "keyboard" in name:
            s += 20
        if (kbd.get("layout") or "").strip():
            s += 5
        if km(kbd):
            s += 5
        if re.search(r"power-button|consumer|control|mouse|touchpad|video|camera", name):
            s -= 80
        if is_virtual(name):
            s -= 60
        return s

    if keyboards:
        best = max(keyboards, key=score)
        v = km(best)
        if v:
            return v

    for k in keyboards:
        if not is_virtual(k.get("name", "")):
            v = km(k)
            if v:
                return v

    for k in keyboards:
        v = km(k)
        if v:
            return v

    return ""


def main() -> None:
    hyprctl_bin = resolve_hyprctl()
    if not hyprctl_bin:
        print("?")
        return

    layout = get_layout_from_hyprctl(hyprctl_bin)
    print(map_layout(layout))


if __name__ == "__main__":
    main()
