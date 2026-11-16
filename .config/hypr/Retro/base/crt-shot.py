#!/usr/bin/env python3
import re
import sys

import numpy as np
from PIL import Image


def defs(path):
    out = {}
    for name, val in re.findall(r"#define (\w+) (.+)", open(path).read()):
        nums = re.findall(r"-?\d+\.?\d*", val.split("(")[-1])
        out[name] = np.array([float(n) for n in nums], np.float32) if len(nums) > 1 else float(nums[0])
    return out


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def main(src, dst, frag):
    d = defs(frag)
    img = np.asarray(Image.open(src).convert("RGB"), np.float32) / 255
    h, w = img.shape[:2]
    fx = np.arange(w, dtype=np.float32) + 0.5
    fy = h - np.arange(h, dtype=np.float32)[:, None] - 0.5
    c = np.stack(np.broadcast_arrays((fx / w)[None, :] - 0.5, 0.5 - (h - fy) / h), -1)
    r2 = (c * c).sum(-1, keepdims=True)
    uv = c * (1 + d["BEND"] * r2) + 0.5

    def tap(ox, oy):
        x = np.clip((uv[..., 0] + ox / w) * w - 0.5, 0, w - 1)
        y = np.clip((0.5 - (uv[..., 1] + oy / h - 0.5)) * h - 0.5, 0, h - 1)
        x0, y0 = np.floor(x).astype(np.int32), np.floor(y).astype(np.int32)
        x1, y1 = np.minimum(x0 + 1, w - 1), np.minimum(y0 + 1, h - 1)
        ax, ay = (x - x0)[..., None], (y - y0)[..., None]
        top = img[y0, x0] * (1 - ax) + img[y0, x1] * ax
        bot = img[y1, x0] * (1 - ax) + img[y1, x1] * ax
        return top * (1 - ay) + bot * ay

    q = np.abs(uv - 0.5) * 2
    rr = max(d["ROUND"] * 0.06, 0.0001)
    o = q - (1 - rr)
    sd = np.linalg.norm(np.maximum(o, 0), axis=-1) + np.minimum(o.max(-1), 0) - rr
    fw = np.maximum(np.abs(np.gradient(sd, axis=1)) + np.abs(np.gradient(sd, axis=0)), 2 / min(w, h)) * 1.2
    mask = (1 - smooth(-fw, fw, sd))[..., None]

    if d["CURVED"]:
        col = 0.25 * (tap(-0.35, -0.35) + tap(0.35, -0.35) + tap(-0.35, 0.35) + tap(0.35, 0.35))
    else:
        col = tap(0, 0)
    halo = tap(2, 0) + tap(-2, 0) + tap(0, 2) + tap(0, -2)
    col = col + d["GLOW"] * 0.35 * np.maximum(halo * 0.25 - 0.25, 0)

    l = (col @ np.array([0.299, 0.587, 0.114], np.float32))[..., None]
    phos = d["TINT"] * np.power(l, 0.9) * 1.15 + 0.04 * l * l
    col = col + (phos - col) * d["MONO"]

    row = np.mod(fy, 3)[..., None]
    col = col * (1 - d["LINES"] * smooth(1.4, 2.6, row) * (1 - 0.5 * l))
    col = col * (1 - d["VIGNETTE"] * 0.9 * np.power(r2 * 1.6, 1.6))
    if d["GRAIN"]:
        gx, gy = np.floor(fx)[None, :], np.floor(fy - 0.5)
        noise = np.mod(np.sin(gx * 12.9898 + gy * 78.233) * 43758.5453, 1) - 0.5
        col = col + d["GRAIN"] * noise[..., None] * smooth(0, 0.08, l)
    out = np.clip(col, 0, 1) * mask
    Image.fromarray((out * 255 + 0.5).astype(np.uint8)).save(dst)


if __name__ == "__main__":
    main(*sys.argv[1:4])
