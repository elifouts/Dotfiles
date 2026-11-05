#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float core;
    float glow;
    float shade;
    vec4 tint;
};

void main() {
    vec2 p = qt_TexCoord0 * 2.0 - 1.0;
    float r = length(p);
    float aa = fwidth(r);
    float ball = smoothstep(core + aa, core - aa, r);
    vec3 n = vec3(p / core, sqrt(max(0.0, 1.0 - r * r / (core * core))));
    float lit = mix(1.0, 0.6 + 0.4 * dot(n, normalize(vec3(-0.45, 0.5, 0.75))), shade);
    vec3 c = mix(tint.rgb * lit, vec3(1.0), pow(n.z, mix(1.5, 4.0, shade)) * mix(0.9, 0.65, shade));
    float halo = glow * exp(-r * r * 5.0) * (1.0 - ball) * smoothstep(1.0, 0.7, r);
    fragColor = vec4(c * ball + tint.rgb * halo, ball + halo) * qt_Opacity;
}
