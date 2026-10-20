"""Render every bitmap app icon from the Android adaptive-icon VectorDrawables.

The launcher icon lives in three VectorDrawables,
android/app/src/main/res/drawable/ic_launcher_{background,foreground,monochrome}.xml
(Claude Design, "Əlifba Brand Assets" 4.2), which build_icon_vectors.py writes.
This script converts the background and foreground layers back to SVG, renders
them with headless Chrome or Edge, and writes the bitmaps that cannot be vectors:

  android  mipmap-*/ic_launcher.png        48-192 px, rounded square (pre-API 26)
           mipmap-*/ic_launcher_round.png  48-192 px, circle (API 25 roundIcon)
  ios      AppIcon.appiconset/*.png        every size already in the set, opaque
  web      icons/Icon-{192,512}.png        rounded square
           icons/Icon-maskable-*.png       the full 108dp canvas (bleeds to the edge)
           favicon.png                     32 px, rounded square

Usage:  python branding/render_icons.py [--preview DIR]
Needs:  Python 3 with Pillow, and Chrome or Edge (set CHROME=<path> to pick one).

The Play Store icon (docs/store/ic_play_512.png) and the feature graphic are the
design's own exports and are not rendered here.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android" / "app" / "src" / "main" / "res"
A = "{http://schemas.android.com/apk/res/android}"

# Launcher masks from the design (ElifbaIcon MASKS), in 108dp canvas units.
MASKS = {
    "full108": ("0 0 108 108", None),
    "square": ("18 18 72 72", None),
    "rounded": ("18 18 72 72", "M30 18H78A12 12 0 0 1 90 30V78A12 12 0 0 1 78 90H30"
                               "A12 12 0 0 1 18 78V30A12 12 0 0 1 30 18Z"),
    "circle": ("18 18 72 72", "M18 54a36 36 0 1 0 72 0a36 36 0 1 0 -72 0Z"),
}
RENDER_PX = 1024
LEGACY_DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


# The VectorDrawable subset the converter understands. Anything else stops the
# script, so the bitmaps can never quietly stop matching the vector icon.
ALLOWED = {
    "vector": {"width", "height", "viewportWidth", "viewportHeight"},
    "group": {"name", "pivotX", "pivotY", "translateX", "translateY", "rotation",
              "scaleX", "scaleY"},
    "path": {"name", "pathData", "fillColor", "fillAlpha", "fillType", "strokeColor",
             "strokeAlpha", "strokeWidth"},
}


def _check_attributes(element):
    for key in element.attrib:
        if not key.startswith(A) or key[len(A):] not in ALLOWED[element.tag]:
            sys.exit(f"render_icons: unsupported attribute {key} on <{element.tag}>")


def _color(value, alpha):
    """VectorDrawable #RGB/#ARGB/#RRGGBB/#AARRGGBB -> (svg colour, opacity)."""
    if not re.fullmatch(r"#([0-9A-Fa-f]{3,4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})", value):
        sys.exit(f"render_icons: only literal #hex colours are supported, got {value}")
    v = value[1:]
    if len(v) in (3, 4):
        v = "".join(c * 2 for c in v)
    if len(v) == 8:
        alpha *= int(v[:2], 16) / 255
        v = v[2:]
    return f"#{v}", alpha


def _vd_to_svg(node):
    """Convert the subset of VectorDrawable this project uses into SVG markup."""
    out = []
    for child in node:
        tag = child.tag
        if tag in ALLOWED:
            _check_attributes(child)
        if tag == "path" and len(child):
            sys.exit("render_icons: <path> children (e.g. aapt:attr gradients) are not supported")
        if tag == "group":
            px = float(child.get(A + "pivotX", 0))
            py = float(child.get(A + "pivotY", 0))
            tx = float(child.get(A + "translateX", 0)) + px
            ty = float(child.get(A + "translateY", 0)) + py
            transform = (
                f"translate({tx} {ty}) rotate({child.get(A + 'rotation', 0)}) "
                f"scale({child.get(A + 'scaleX', 1)} {child.get(A + 'scaleY', 1)}) "
                f"translate({-px} {-py})"
            )
            out.append(f'<g transform="{transform}">{_vd_to_svg(child)}</g>')
        elif tag == "path":
            attrs = [f'd="{child.get(A + "pathData")}"']
            fill = child.get(A + "fillColor")
            if fill:
                c, o = _color(fill, float(child.get(A + "fillAlpha", 1)))
                attrs.append(f'fill="{c}" fill-opacity="{o}"')
            else:
                attrs.append('fill="none"')
            if child.get(A + "fillType") == "evenOdd":
                attrs.append('fill-rule="evenodd"')
            stroke = child.get(A + "strokeColor")
            if stroke:
                c, o = _color(stroke, float(child.get(A + "strokeAlpha", 1)))
                attrs.append(
                    f'stroke="{c}" stroke-opacity="{o}" '
                    f'stroke-width="{child.get(A + "strokeWidth", 0)}"'
                )
            out.append(f"<path {' '.join(attrs)}/>")
        else:
            sys.exit(f"render_icons: unsupported VectorDrawable element <{tag}>")
    return "".join(out)


def _layer(name):
    root = ET.parse(RES / "drawable" / f"ic_launcher_{name}.xml").getroot()
    _check_attributes(root)
    if (root.get(A + "viewportWidth"), root.get(A + "viewportHeight")) != ("108", "108"):
        sys.exit(f"render_icons: ic_launcher_{name}.xml must use a 108x108 viewport")
    return _vd_to_svg(root)


def _find_browser():
    candidates = [os.environ.get("CHROME")] + [
        shutil.which(n) for n in ("chrome", "google-chrome", "chromium", "msedge")
    ] + [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    ]
    for c in candidates:
        if c and Path(c).exists():
            return c
    sys.exit("render_icons: Chrome/Edge not found; set CHROME=<path to the browser>")


def _render(browser, tmp, mask, layers):
    """Render [layers] (SVG markup, back to front) through [mask] at RENDER_PX."""
    view_box, clip = MASKS[mask]
    body = "".join(layers)
    if clip:
        body = f'<clipPath id="m"><path d="{clip}"/></clipPath><g clip-path="url(#m)">{body}</g>'
    html = tmp / f"{mask}.html"
    html.write_text(
        "<!doctype html><meta charset=utf-8><style>html,body{margin:0;background:transparent}"
        "svg{display:block}</style>"
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{RENDER_PX}" height="{RENDER_PX}" '
        f'viewBox="{view_box}">{body}</svg>',
        encoding="utf-8",
    )
    png = tmp / f"{mask}.png"
    subprocess.run(
        [
            browser, "--headless=new", "--disable-gpu", "--hide-scrollbars",
            "--force-device-scale-factor=1", "--default-background-color=00000000",
            f"--user-data-dir={tmp / 'profile'}", f"--window-size={RENDER_PX},{RENDER_PX}",
            f"--screenshot={png}", html.as_uri(),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    image = Image.open(png).convert("RGBA")
    if image.size != (RENDER_PX, RENDER_PX):
        sys.exit(f"render_icons: browser returned {image.size}, expected {RENDER_PX}px")
    return image


def _save(image, size, path, opaque=False):
    out = image.resize((size, size), Image.LANCZOS)
    if opaque:
        flat = Image.new("RGB", out.size, (0x8F, 0x78, 0xE6))
        flat.paste(out, mask=out.getchannel("A"))
        out = flat
    out.save(path, optimize=True)
    print(f"  {path.relative_to(ROOT)}  {size}px")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--preview", type=Path, help="also save the full-size renders here")
    args = parser.parse_args()

    browser = _find_browser()
    layers = [_layer("background"), _layer("foreground")]
    with tempfile.TemporaryDirectory() as t:
        tmp = Path(t)
        renders = {mask: _render(browser, tmp, mask, layers) for mask in MASKS}
        mono = _render(browser, tmp, "circle", [_layer("monochrome")])

    if args.preview:
        args.preview.mkdir(parents=True, exist_ok=True)
        for mask, image in renders.items():
            image.save(args.preview / f"icon_{mask}.png")
        mono.save(args.preview / "icon_monochrome.png")

    print("android")
    for density, size in LEGACY_DENSITIES.items():
        folder = RES / f"mipmap-{density}"
        _save(renders["rounded"], size, folder / "ic_launcher.png")
        _save(renders["circle"], size, folder / "ic_launcher_round.png")

    print("ios")
    icon_set = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for path in sorted(icon_set.glob("Icon-App-*.png")):
        # Icon-App-83.5x83.5@2x.png -> 83.5 * 2
        points, scale = path.stem[len("Icon-App-"):].split("@")
        size = round(float(points.split("x")[0]) * float(scale.rstrip("x")))
        _save(renders["square"], size, path, opaque=True)

    print("web")
    web = ROOT / "web"
    _save(renders["rounded"], 192, web / "icons" / "Icon-192.png")
    _save(renders["rounded"], 512, web / "icons" / "Icon-512.png")
    _save(renders["full108"], 192, web / "icons" / "Icon-maskable-192.png", opaque=True)
    _save(renders["full108"], 512, web / "icons" / "Icon-maskable-512.png", opaque=True)
    _save(renders["rounded"], 32, web / "favicon.png")


if __name__ == "__main__":
    main()
