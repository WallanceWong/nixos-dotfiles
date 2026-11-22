#!/usr/bin/env python3
"""eva cursors — draws the HUD cursor set for one setup as SVG and writes the
xcursorgen configs. Shapes on a 32-unit grid; rendered at 24/32/48/64 px.

    gen.py <body> <edge> <alert> <outdir>
"""
import math, os, sys

body, edge, alert, out = sys.argv[1:5]
os.makedirs(out, exist_ok=True)
SIZES = [24, 32, 48, 64]

def svg(inner):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">{inner}</svg>'

def poly(pts, fill, stroke=edge, w=1.4):
    p = " ".join(f"{x},{y}" for x, y in pts)
    return f'<polygon points="{p}" fill="{fill}" stroke="{stroke}" stroke-width="{w}" stroke-linejoin="miter"/>'

ARROW = [(3, 2), (3, 25), (9, 19.5), (13, 28.5), (17, 26.8), (13, 18), (21, 18)]
def arrow(fill=body, extra=""):
    # the HUD arrow: cut tail, a lit tick along the leading edge
    return svg(poly(ARROW, fill) + f'<line x1="4.6" y1="5.5" x2="4.6" y2="14" stroke="{edge}" stroke-width="1.6"/>' + extra)

def hexagon(cx, cy, r, fill, stroke, w=1.6, rot=0):
    pts = [(cx + r * math.cos(math.radians(60 * i + rot)), cy + r * math.sin(math.radians(60 * i + rot))) for i in range(6)]
    return poly(pts, fill, stroke, w)

shapes = {}  # name -> (list of frames (svg), hotspot x, y on the 32 grid, frame delay ms)
shapes["default"] = ([arrow()], 3, 2, 0)
# pointer: the same arrow, lit
shapes["pointer"] = ([arrow(fill=edge, extra="")], 3, 2, 0)
shapes["text"] = ([svg(f'<path d="M11 5h10M11 27h10M16 5v22" stroke="{body}" stroke-width="4"/><path d="M11 5h10M11 27h10M16 5v22" stroke="{edge}" stroke-width="1.6"/>')], 16, 16, 0)
shapes["crosshair"] = ([svg("".join(f'<path d="{d}" fill="none" stroke="{body}" stroke-width="4"/><path d="{d}" fill="none" stroke="{edge}" stroke-width="1.6"/>'
                                    for d in ["M5 11V5h6", "M21 5h6v6", "M27 21v6h-6", "M11 27H5v-6", "M16 12v8M12 16h8"]))], 16, 16, 0)
# wait: a hexagon ring turning (12 frames)
shapes["wait"] = ([svg(hexagon(16, 16, 11, "none", body, 5, rot) + hexagon(16, 16, 11, "none", edge, 2, rot)
                       + f'<circle cx="{16 + 11 * math.cos(math.radians(rot))}" cy="{16 + 11 * math.sin(math.radians(rot))}" r="3" fill="{edge}"/>')
                   for rot in range(0, 360, 30)], 16, 16, 60)
# progress: the arrow with a small turning hexagon beside it
shapes["progress"] = ([svg(poly(ARROW, body) + f'<line x1="4.6" y1="5.5" x2="4.6" y2="14" stroke="{edge}" stroke-width="1.6"/>'
                           + hexagon(24, 24, 5.5, body, edge, 1.4, rot)) for rot in range(0, 60, 6)], 3, 2, 60)
shapes["not-allowed"] = ([svg(hexagon(16, 16, 12, body, alert, 2.4) + f'<line x1="9" y1="9" x2="23" y2="23" stroke="{alert}" stroke-width="2.6"/>')], 16, 16, 0)

def double(angle):
    a = f'<g transform="rotate({angle} 16 16)"><path d="M16 3l6 7h-4v12h4l-6 7-6-7h4V10h-4z" fill="{body}" stroke="{edge}" stroke-width="1.4" stroke-linejoin="miter"/></g>'
    return svg(a)
shapes["ns-resize"] = ([double(0)], 16, 16, 0)
shapes["ew-resize"] = ([double(90)], 16, 16, 0)
shapes["nwse-resize"] = ([double(-45)], 16, 16, 0)
shapes["nesw-resize"] = ([double(45)], 16, 16, 0)
shapes["move"] = ([svg(f'<path d="M16 2l5 6h-3v6h6v-3l6 5-6 5v-3h-6v6h3l-5 6-5-6h3v-6H8v3l-6-5 6-5v3h6V8h-3z" fill="{body}" stroke="{edge}" stroke-width="1.3" stroke-linejoin="miter"/>')], 16, 16, 0)

# X cursor names → our shapes
aliases = {
    "default": ["left_ptr", "arrow", "top_left_arrow", "default", "context-menu", "alias", "copy", "cell"],
    "pointer": ["pointer", "hand", "hand1", "hand2", "pointing_hand", "e29285e634086352946a0e7090d73106", "9d800788f1b08800ae810202380a0822"],
    "text": ["text", "xterm", "ibeam", "vertical-text"],
    "crosshair": ["crosshair", "cross", "tcross", "color-picker"],
    "wait": ["wait", "watch"],
    "progress": ["progress", "left_ptr_watch", "half-busy", "00000000000000020006000e7e9ffc3f", "08e8e1c95fe2fc01f976f1e063a24ccd"],
    "not-allowed": ["not-allowed", "crossed_circle", "forbidden", "no-drop", "circle", "03b6e0fcb3499374a867c041f52298f0"],
    "ns-resize": ["ns-resize", "n-resize", "s-resize", "row-resize", "sb_v_double_arrow", "v_double_arrow", "top_side", "bottom_side", "size_ver", "00008160000006810000408080010102"],
    "ew-resize": ["ew-resize", "e-resize", "w-resize", "col-resize", "sb_h_double_arrow", "h_double_arrow", "left_side", "right_side", "size_hor", "028006030e0e7ebffc7f7070c0600140"],
    "nwse-resize": ["nwse-resize", "nw-resize", "se-resize", "top_left_corner", "bottom_right_corner", "size_fdiag", "c7088f0f3e6c8088236ef8e1e3e70000"],
    "nesw-resize": ["nesw-resize", "ne-resize", "sw-resize", "top_right_corner", "bottom_left_corner", "size_bdiag", "fcf1c3c7cd4491d801f1e1c78f100000"],
    "move": ["move", "fleur", "all-scroll", "grab", "grabbing", "openhand", "closedhand", "size_all", "dnd-move", "dnd-none"],
}

for name, (frames, hx, hy, delay) in shapes.items():
    lines = []
    for i, f in enumerate(frames):
        fn = f"{name}-{i:02d}.svg"
        open(os.path.join(out, fn), "w").write(f)
        for s in SIZES:
            k = s / 32
            lines.append(f"{s} {round(hx * k)} {round(hy * k)} {name}-{i:02d}-{s}.png" + (f" {delay}" if delay else ""))
    open(os.path.join(out, name + ".in"), "w").write("\n".join(lines) + "\n")
open(os.path.join(out, "aliases.txt"), "w").write("\n".join(f"{n} {' '.join(a)}" for n, a in aliases.items()) + "\n")
print(f"eva cursors: {len(shapes)} shapes")
