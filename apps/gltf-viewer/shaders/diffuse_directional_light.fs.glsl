#version 330

in vec3 vViewSpacePosition;
in vec3 vViewSpaceNormal;
in vec2 vTexCoords;

out vec3 fRadiance;

uniform vec3 uLightDirection;
uniform vec3 uLightIntensity;

const float PI = 3.1415;

vec3 fr(vec3 inDir, vec3 outDir) {
    return vec3(1/PI, 1/PI, 1/PI);
}

void main() {
    vec3 outDir = vec3(0, 0, 0);
    fRadiance = fr(uLightDirection, outDir) * uLightIntensity * dot(normalize(vViewSpaceNormal), uLightDirection);
}
