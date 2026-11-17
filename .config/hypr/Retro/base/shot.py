#!/usr/bin/env python3
import ctypes as C
import sys

import numpy as np
from PIL import Image

egl = C.CDLL("libEGL.so.1")
gl = C.CDLL("libGLESv2.so.2")
egl.eglGetDisplay.restype = C.c_void_p
egl.eglCreateContext.restype = C.c_void_p
egl.eglGetProcAddress.restype = C.c_void_p
for f in ("eglInitialize", "eglChooseConfig", "eglBindAPI", "eglMakeCurrent", "eglCreateContext"):
    getattr(egl, f).argtypes = None
gl.glGetUniformLocation.restype = C.c_int

VERT = b"""#version 300 es
in vec2 pos;
out vec2 v_texcoord;
void main() { v_texcoord = pos * 0.5 + 0.5; gl_Position = vec4(pos, 0.0, 1.0); }
"""


def ints(*v):
    return (C.c_int * len(v))(*v)


def context():
    get = C.CFUNCTYPE(C.c_void_p, C.c_uint, C.c_void_p, C.c_void_p)(egl.eglGetProcAddress(b"eglGetPlatformDisplayEXT"))
    d = C.c_void_p(get(0x31DD, None, None))
    if not d or not egl.eglInitialize(d, None, None):
        sys.exit("no egl")
    cfg, n = C.c_void_p(), C.c_int()
    egl.eglChooseConfig(d, ints(0x3040, 0x0040, 0x3038), C.byref(cfg), 1, C.byref(n))
    egl.eglBindAPI(0x30A0)
    ctx = C.c_void_p(egl.eglCreateContext(d, cfg, None, ints(0x3098, 3, 0x3038)))
    if not ctx or not egl.eglMakeCurrent(d, None, None, ctx):
        sys.exit("no gl context")


def shader(kind, src):
    s = gl.glCreateShader(kind)
    gl.glShaderSource(s, 1, C.byref(C.c_char_p(src)), None)
    gl.glCompileShader(s)
    ok = C.c_int()
    gl.glGetShaderiv(s, 0x8B81, C.byref(ok))
    if not ok.value:
        log = C.create_string_buffer(4096)
        gl.glGetShaderInfoLog(s, 4096, None, log)
        sys.exit(log.value.decode())
    return s


def main(src, dst, frag):
    img = np.ascontiguousarray(np.asarray(Image.open(src).convert("RGBA"))[::-1])
    h, w = img.shape[:2]
    context()
    prog = gl.glCreateProgram()
    gl.glAttachShader(prog, shader(0x8B31, VERT))
    gl.glAttachShader(prog, shader(0x8B30, open(frag, "rb").read()))
    gl.glBindAttribLocation(prog, 0, b"pos")
    gl.glLinkProgram(prog)
    gl.glUseProgram(prog)

    tex, fbo, out = C.c_uint(), C.c_uint(), C.c_uint()
    for t in (tex, out):
        gl.glGenTextures(1, C.byref(t))
        gl.glBindTexture(0x0DE1, t)
        for p in (0x2801, 0x2800):
            gl.glTexParameteri(0x0DE1, p, 0x2601)
        for p in (0x2802, 0x2803):
            gl.glTexParameteri(0x0DE1, p, 0x812F)
        gl.glTexImage2D(0x0DE1, 0, 0x1908, w, h, 0, 0x1908, 0x1401, C.c_void_p(img.ctypes.data) if t is tex else None)
    gl.glGenFramebuffers(1, C.byref(fbo))
    gl.glBindFramebuffer(0x8D40, fbo)
    gl.glFramebufferTexture2D(0x8D40, 0x8CE0, 0x0DE1, out, 0)
    gl.glActiveTexture(0x84C0)
    gl.glBindTexture(0x0DE1, tex)
    gl.glUniform1i(gl.glGetUniformLocation(prog, b"tex"), 0)
    gl.glUniform2f(gl.glGetUniformLocation(prog, b"screen_size"), C.c_float(w), C.c_float(h))

    quad = (C.c_float * 8)(-1, -1, 1, -1, -1, 1, 1, 1)
    gl.glEnableVertexAttribArray(0)
    gl.glVertexAttribPointer(0, 2, 0x1406, 0, 0, quad)
    gl.glViewport(0, 0, w, h)
    gl.glDrawArrays(0x0005, 0, 4)
    res = np.empty((h, w, 4), np.uint8)
    gl.glReadPixels(0, 0, w, h, 0x1908, 0x1401, C.c_void_p(res.ctypes.data))
    Image.fromarray(res[::-1, :, :3]).save(dst)


if __name__ == "__main__":
    main(*sys.argv[1:4])
