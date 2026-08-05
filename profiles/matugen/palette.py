#!/usr/bin/env python3
"""Custom matugen scheme: wallpaper-derived ANSI hues.

Dumps matugen's Material (scheme-expressive) palette for UI chrome, then
samples the wallpaper's actual hue distribution to fill the six ANSI hue
slots. Slots whose hue is present in the wallpaper use the wallpaper's hue;
empty slots fall back to Material's canonical fixed-palette hues, so all six
stay distinct while keeping the wallpaper's tone (saturation/lightness).

Usage: palette.py <wallpaper> <mode>   (mode: dark|light)
Writes ~/.cache/matugen/scheme.json and renders config.toml + kitty.toml.
"""
import colorsys
import json
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image

MATUGEN = "matugen"
CONFIG = "~/.config/matugen/config.toml"
KITTY = "~/.config/matugen/kitty.toml"
OUT = Path("~/.cache/matugen/scheme.json").expanduser()

# canonical fixed-palette hues per ANSI slot (Material's standard accents)
SLOTS = {
    "red":     0,
    "yellow":  50,
    "green":   140,
    "cyan":    190,
    "blue":    235,
    "magenta": 300,
}

# adopt a wallpaper hue only if it lands within this range of the slot's
# canonical hue, so adjacent warm/cool clusters don't collapse into one slot
ADOPT_RANGE = 20

L_NORMAL = 45
L_BRIGHT = 68
# fallback (canonical-hue) colors stay muted so they don't fight the
# wallpaper-derived tones; adopted colors keep the wallpaper's own saturation
SAT_FALLBACK = 0.55
# light mode: backgrounds are bright, so lift saturation to keep colors punchy
SAT_LIGHT_BOOST = 1.35
SAT_MAX = 0.92


def hue_dist(a: float, b: float) -> float:
    d = abs(a - b) % 360
    return min(d, 360 - d)


def hex_from_hsl(h: float, s: float, l: float) -> str:
    r, g, b = colorsys.hls_to_rgb(h / 360, l / 100, s)
    return "#{:02x}{:02x}{:02x}".format(*(round(c * 255) for c in (r, g, b)))


def sample_wallpaper(image: str) -> dict:
    """Return per-slot (hue, sat, count) from the wallpaper's saturated pixels."""
    im = Image.open(image).convert("RGB")
    im.thumbnail((128, 128))
    px = im.getdata()
    clusters = {k: [] for k in SLOTS}
    for r, g, b in px:
        h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        hh = h * 360
        if s < 0.35 or not (0.15 < l < 0.85):
            continue
        slot = min(SLOTS, key=lambda k: hue_dist(hh, SLOTS[k]))
        clusters[slot].append((hh, s))
    return clusters


def slot_colors(clusters: dict, slot: str, mode: str) -> tuple[str, str]:
    """(normal_hex, bright_hex) for a slot, pulling hue/sat from wallpaper if present."""
    nominal = SLOTS[slot]
    pts = clusters[slot]
    if len(pts) >= 25:
        pts.sort(key=lambda p: -p[1])
        top = pts[: max(1, len(pts) // 2)]
        rep = sum(p[0] * p[1] for p in top) / sum(p[1] for p in top)
        if hue_dist(rep, nominal) <= ADOPT_RANGE:
            hue = rep
            sat = min(max(sum(p[1] for p in top) / len(top), 0.5), 0.85)
        else:
            hue, sat = nominal, SAT_FALLBACK
    else:
        hue, sat = nominal, SAT_FALLBACK
    if mode == "light":
        sat = min(sat * SAT_LIGHT_BOOST, SAT_MAX)
    return (
        hex_from_hsl(hue, sat, L_NORMAL),
        hex_from_hsl(hue, sat, L_BRIGHT),
    )


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    image, mode = sys.argv[1], sys.argv[2]
    if mode not in ("dark", "light"):
        print("mode must be dark or light")
        return 1

    dump = subprocess.run(
        [MATUGEN, "image", image, "-m", mode, "-t", "scheme-expressive", "-j", "hex"],
        capture_output=True, text=True, check=True,
    )
    scheme = json.loads(dump.stdout)

    clusters = sample_wallpaper(image)
    for slot in SLOTS:
        normal, bright = slot_colors(clusters, slot, mode)
        scheme["colors"][slot] = {"default": {"color": normal}}
        scheme["colors"][f"{slot}_bright"] = {"default": {"color": bright}}

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(scheme))

    for cfg in (CONFIG, KITTY):
        subprocess.run(
            [MATUGEN, "json", str(OUT), "-c", Path(cfg).expanduser()],
            check=True,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
