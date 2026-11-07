#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float yaw;
    float pitch;
    float focal;
    float offX;
    float offY;
    float sizeW;
    float sizeH;
    vec4 tint1;
    vec4 tint2;
    vec4 base;
};

float h3(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}
float n3(vec3 p) {
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
               mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
void main() {
    vec3 d = normalize(vec3((offX + qt_TexCoord0.x * sizeW) / focal, -(offY + qt_TexCoord0.y * sizeH) / focal, 1.0));
    d = vec3(d.x, d.y * cos(pitch) + d.z * sin(pitch), -d.y * sin(pitch) + d.z * cos(pitch));
    d = vec3(d.x * cos(yaw) + d.z * sin(yaw), d.y, -d.x * sin(yaw) + d.z * cos(yaw));

    float band = exp(-abs(d.y + 0.2 * sin(d.x * 2.0 + d.z)) * 4.0);
    float neb = n3(d * 2.4 + 7.0) * 0.65 + n3(d * 5.3) * 0.35;
    vec3 col = base.rgb + tint1.rgb * band * 0.05
             + mix(tint2.rgb, tint1.rgb, smoothstep(0.3, 0.7, neb)) * (0.3 + band) * neb * neb * 0.28;

    for (int i = 0; i < 2; i++) {
        float sc = 110.0 + float(i) * 150.0;
        vec3 q = d * sc, c = floor(q);
        float r = h3(c);
        if (r > 0.945 - band * 0.03) {
            vec3 pt = c + 0.2 + 0.6 * vec3(h3(c + 3.7), h3(c + 9.1), h3(c + 5.3));
            float dist = length(q - pt), k = h3(c + 1.9);
            vec3 tint = k < 0.6 ? vec3(1.0) : k < 0.82 ? vec3(0.82, 0.9, 1.0) : vec3(1.0, 0.9, 0.78);
            float s = smoothstep(0.14, 0.0, dist) + exp(-dist * 7.0) * 0.12 * step(0.985, r);
            col += tint * s * (0.4 + (r - 0.94) * 8.0) / (1.0 + float(i));
        }
    }
    fragColor = vec4(col, 1.0) * qt_Opacity;
}
