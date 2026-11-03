#version 440

// Draws a twisted strand of wool across the strip from yarn.vert: diagonal plies, a
// rounded body and a fuzzy outline. Rebuild the .qsb after changing this:
// /usr/lib/qt6/bin/qsb --qt6 -o yarn.frag.qsb yarn.frag

layout(location = 0) in vec2 strandCoord;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 p0;
    vec2 p1;
    vec2 p2;
    vec2 p3;
    float thickness;
    float strandLength;
    vec4 yarn;
} ubuf;

const float PI = 3.14159265;

// The strip is wider than the wool so stray fibers have room outside it
const float CORE = 0.62;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
        mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

void main() {
    // In strand widths, so the detail scales with the thickness
    float along = strandCoord.x / ubuf.thickness;
    float across = strandCoord.y;
    float radius = abs(across) / CORE;
    float side = sign(across);
    float pixel = 1.0 / (ubuf.thickness * CORE);

    // The plies wrap around a round strand, so they curve as they reach its edges
    float wrap = asin(clamp(across / CORE, -1.0, 1.0)) / (PI * 0.5);
    float twist = along / 1.2 + wrap * 0.8;
    float groove = abs(fract(twist) - 0.5) * 2.0;
    float grooveDepth = groove * groove * groove * groove;
    float ply = 1.0 - grooveDepth;

    // Hairs run along the plies, so the grain is across them. No two plies match.
    float hairs = noise(vec2(twist * 22.0, along * 0.45 + across * 2.0));
    float tint = hash(vec2(floor(twist), 7.0)) - 0.5;
    float body = sqrt(max(1.0 - radius * radius, 0.0));
    float light = mix(0.3, 1.0, ply) * mix(0.42, 1.0, body) + (hairs - 0.5) * 0.24 + tint * 0.1;

    vec3 shadow = mix(ubuf.yarn.rgb, vec3(0.067, 0.067, 0.106), 0.62);
    vec3 shine = mix(ubuf.yarn.rgb, vec3(1.0), 0.28);
    vec3 color = light < 0.72
        ? mix(shadow, ubuf.yarn.rgb, clamp(light / 0.72, 0.0, 1.0))
        : mix(ubuf.yarn.rgb, shine, clamp((light - 0.72) / 0.28, 0.0, 1.0));

    // The outline dips at each groove and is a little uneven, like real wool
    float wobble = (noise(vec2(along * 2.7, side * 3.0)) - 0.5) * 0.14;
    float edge = 1.0 + wobble - grooveDepth * 0.16;
    float alpha = 1.0 - smoothstep(edge - pixel * 2.0, edge + pixel, radius);

    // A soft aura of fuzz, fading out from the strand
    float outside = clamp((abs(across) - CORE) / (1.0 - CORE), 0.0, 1.0);
    float clump = noise(vec2(along * 6.75, side * 9.0));
    float aura = (1.0 - outside) * (1.0 - outside) * (0.12 + clump * 0.3);

    // And the odd loose hair, each its own length
    float slot = along * 3.0 - outside * 1.4;
    float strayLength = hash(vec2(floor(slot), side + 2.0));
    float stray = step(0.84, hash(vec2(floor(slot), side)))
        * (1.0 - smoothstep(0.0, 0.16, abs(fract(slot) - 0.5)))
        * (1.0 - smoothstep(strayLength * 0.8, strayLength, outside))
        * step(CORE * 0.9, abs(across)) * 0.55;

    float loose = max(aura, stray);
    if (loose > alpha) {
        color = mix(ubuf.yarn.rgb, shine, 0.3);
        alpha = loose;
    }

    fragColor = vec4(color * alpha, alpha) * ubuf.qt_Opacity;
}
