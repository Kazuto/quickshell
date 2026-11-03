#version 440

// Bends a straight strip along a cubic curve. Rebuild the .qsb after changing this:
// /usr/lib/qt6/bin/qsb --qt6 -o yarn.vert.qsb yarn.vert

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 strandCoord;

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

void main() {
    float t = qt_MultiTexCoord0.x;
    float across = qt_MultiTexCoord0.y * 2.0 - 1.0;
    float s = 1.0 - t;

    vec2 point = s * s * s * ubuf.p0
        + 3.0 * s * s * t * ubuf.p1
        + 3.0 * s * t * t * ubuf.p2
        + t * t * t * ubuf.p3;
    vec2 tangent = 3.0 * s * s * (ubuf.p1 - ubuf.p0)
        + 6.0 * s * t * (ubuf.p2 - ubuf.p1)
        + 3.0 * t * t * (ubuf.p3 - ubuf.p2);

    float speed = length(tangent);
    vec2 normal = speed > 0.001 ? vec2(-tangent.y, tangent.x) / speed : vec2(0.0, 1.0);

    strandCoord = vec2(t * ubuf.strandLength, across);
    gl_Position = ubuf.qt_Matrix * vec4(point + normal * across * ubuf.thickness, 0.0, 1.0);
}
