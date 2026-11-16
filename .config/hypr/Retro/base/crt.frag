#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform vec2 screen_size;
out vec4 fragColor;

// defs

float grain(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453) - 0.5; }

void main() {
    vec2 c = v_texcoord - 0.5;
    vec2 px = 1.0 / max(screen_size, vec2(1.0));
    vec2 uv = c * (1.0 + BEND * dot(c, c)) + 0.5;

    vec2 q = abs(uv - 0.5) * 2.0;
    float r = max(ROUND * 0.06, 0.0001);
    vec2 o = q - (1.0 - r);
    float sd = length(max(o, 0.0)) + min(max(o.x, o.y), 0.0) - r;
    float fw = max(fwidth(sd), 2.0 * max(px.x, px.y)) * 1.2;
    float mask = 1.0 - smoothstep(-fw, fw, sd);
    if (mask <= 0.0) { fragColor = vec4(0.0, 0.0, 0.0, 1.0); return; }

#if CURVED
    vec2 h = px * 0.35;
    vec3 col = 0.25 * (texture(tex, uv + vec2(-h.x, -h.y)).rgb + texture(tex, uv + vec2(h.x, -h.y)).rgb
                     + texture(tex, uv + vec2(-h.x, h.y)).rgb + texture(tex, uv + vec2(h.x, h.y)).rgb);
#else
    vec3 col = texture(tex, uv).rgb;
#endif
    vec2 g = 2.0 * px;
    vec3 halo = texture(tex, uv + vec2(g.x, 0.0)).rgb + texture(tex, uv - vec2(g.x, 0.0)).rgb
              + texture(tex, uv + vec2(0.0, g.y)).rgb + texture(tex, uv - vec2(0.0, g.y)).rgb;
    col += GLOW * 0.35 * max(halo * 0.25 - 0.25, 0.0);

    float l = dot(col, vec3(0.299, 0.587, 0.114));
    vec3 phos = TINT * pow(l, 0.9) * 1.15 + vec3(0.04) * l * l;
    col = mix(col, phos, MONO);

    float row = mod(gl_FragCoord.y, 3.0);
    col *= 1.0 - LINES * smoothstep(1.4, 2.6, row) * (1.0 - 0.5 * l);
    col *= 1.0 - VIGNETTE * 0.9 * pow(dot(c, c) * 1.6, 1.6);
    col += GRAIN * grain(floor(gl_FragCoord.xy)) * smoothstep(0.0, 0.08, l);
    fragColor = vec4(clamp(col, 0.0, 1.0) * mask, 1.0);
}
