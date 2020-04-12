#version 330

layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aTexCoords;
layout(location = 3) in vec3 aTangent;

out vec3 vViewSpacePosition;
out vec3 vViewSpaceNormal;
out vec2 vTexCoords;
out vec3 vFragPos;
out vec3 vTangentViewSpacePosition;
out vec3 vTangentFragPos;

uniform mat4 uModelViewProjMatrix;
uniform mat4 uModelViewMatrix;
uniform mat4 uNormalMatrix;

void main()
{
	vec3 T = normalize(vec3(uModelViewMatrix * vec4(aTangent,   0.0)));
	vec3 N = normalize(vec3(uModelViewMatrix * vec4(aNormal,    0.0)));
	vec3 B = cross(N, T);
	mat3 TBN = transpose(mat3(T, B, N));
    vViewSpacePosition = vec3(uModelViewMatrix * vec4(aPosition, 1));
	vViewSpaceNormal = normalize(vec3(uNormalMatrix * vec4(aNormal, 0)));
	vTexCoords = aTexCoords;
	vFragPos = aPosition;
    gl_Position = uModelViewProjMatrix * vec4(aPosition, 1);
	vTangentViewSpacePosition = TBN * vViewSpacePosition;
	vTangentFragPos = TBN * vec3(uModelViewMatrix * vec4(aPosition, 0.0));
}
