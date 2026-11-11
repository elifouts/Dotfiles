#version 440
#extension GL_GOOGLE_include_directive : enable
// inputs
#include "terrain/uniforms.glsl"
#include "terrain/noise.glsl"
#include "terrain/orbit.glsl"
#include "terrain/atlas.glsl"
#include "terrain/shapes.glsl"

// setup
void main() {
    vec2 c = vec2(0.5, 0.65);
    vec2 uv = c + (qt_TexCoord0 - c) / zoom;
    float y0 = 1.0 - uv.y;
    float x = (uv.x - 0.5) * aspect;
    float edge = mix(aspect * 0.5 + 0.7, -aspect * 0.5 - 0.7, wipe);
    if (x > edge + 0.7 || (beneath >= 0.0 && x < mix(aspect * 0.5, -aspect * 0.5 - 1.4, beneath))) {
        fragColor = vec4(0.0);
        return;
    }
    float r2 = rise * 2.4;
    float y = y0 + r2 * 0.15;
    vec3 col = vec3(0.0);
    float cover = 0.0;
    float mq = smoothstep(0.3, 1.0, rise);
    vec2 mc = mix(vec2(pan * 0.02, 0.56 - rise * 0.36), moonEnd.xy, mq);
    float mR = exp(mix(log(0.31), log(max(moonEnd.z, 0.001)), mq));
    float morph = smoothstep(0.02, 0.22, rise);
    // world rolls
    float R = clamp(relief + wv(1.0) * 0.5, 0.0, 1.0);
    float H = landH * (1.0 + wv(2.0) * 0.3);
    float F = flora * clamp(1.0 + wv(3.0) * 1.1, 0.0, 2.0);
    float G = grassy * clamp(1.0 + wv(4.0) * 0.8, 0.0, 2.0);
    float HZ = clamp(haze + wv(6.0) * 0.3, 0.0, 1.0);
    float BS = bases * clamp(1.0 + wv(11.0) * 0.8, 0.0, 2.0);
    float RK = rocks * clamp(1.0 + wv(15.0) * 0.8, 0.0, 2.0);
    float SN = snow * clamp(1.0 + wv(13.0) * 0.6, 0.0, 1.5);
    float A = atlas * (1.0 - moonless);
    // astronaut pick
    float tvH = h1(77.0), tvM = tvH < 0.45 ? 1.0 : tvH < 0.85 ? 2.0 : 0.0;
    tvM = tvM == 2.0 && ship * ships < 0.05 ? 1.0 : tvM;
    if (rise < 0.5) {
// sky
#include "terrain/sky.glsl"
// land
#include "terrain/land.glsl"
    }

// space
#include "terrain/space.glsl"
    fragColor = vec4(col + dither(), 1.0) * qt_Opacity * (1.0 - smoothstep(edge - 0.7, edge + 0.7, x));
}
