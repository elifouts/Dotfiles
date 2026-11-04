#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 texel;
    float start;
    float span;
    float radius;
    float fade;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    float d = clamp((qt_TexCoord0.y - start) / span, 0.0, 1.0);
    float sigma = max(radius * d * d * (3.0 - 2.0 * d), 0.001);
    float n = ceil(sigma * 2.5);
    vec4 sum = texture(source, qt_TexCoord0);
    float w = 1.0;
    for (float i = 1.0; i <= 64.0; i += 1.0) {
        if (i > n) break;
        float g = exp(-(i * i) / (2.0 * sigma * sigma));
        sum += (texture(source, qt_TexCoord0 + texel * i) + texture(source, qt_TexCoord0 - texel * i)) * g;
        w += 2.0 * g;
    }
    float a = fade > 0.5 ? smoothstep(0.0, 0.45, d) : 1.0;
    fragColor = sum / w * a * qt_Opacity;
}
