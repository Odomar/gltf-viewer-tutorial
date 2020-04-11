#version 330

in vec3 vViewSpaceNormal;
in vec3 vViewSpacePosition;
in vec2 vTexCoords;

// Directional Light
struct DirLight {
    vec3 uLightDirection;
	vec3 uLightIntensity;
};  
uniform DirLight dirLight;

// Point lights (TODO)

struct PointLight {    
    vec3 position;
    vec3  color;
    
    float constant;
    float linear;
    float quadratic;  
};
uniform PointLight pointLight;

// Spot light (TODO)

struct SpotLight {    
    vec3  position;
    vec3  direction;
    vec3  color;
    float cutOff;
    float outerCutOff;
	
    float constant;
    float linear;
    float quadratic;
};
uniform SpotLight spotLight;

// Materials factors
uniform vec4 uBaseColorFactor;
uniform float uMetallicFactor;
uniform float uRoughnessFactor;
uniform vec3 uEmissiveFactor;
uniform float uOcclusionStrength;
uniform float uNormalScale;

// Textures maps
uniform sampler2D uMetallicRoughnessTexture;
uniform sampler2D uBaseColorTexture;
uniform sampler2D uEmissiveTexture;
uniform sampler2D uOcclusionTexture;
uniform sampler2D uNormalTexture;

out vec3 fColor;

// Constants
const float GAMMA = 2.2;
const float INV_GAMMA = 1. / GAMMA;
const float M_PI = 3.141592653589793;
const float M_1_PI = 1.0 / M_PI;
const vec3 dielectricSpecular = vec3(0.04, 0.04, 0.04);
const vec3 black = vec3(0, 0, 0);

// We need some simple tone mapping functions
// Basic gamma = 2.2 implementation
// Stolen here: https://github.com/KhronosGroup/glTF-Sample-Viewer/blob/master/src/shaders/tonemapping.glsl

// linear to sRGB approximation
// see http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
vec3 LINEARtoSRGB(vec3 color) {
    return pow(color, vec3(INV_GAMMA));
}

// sRGB to linear approximation
// see http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
vec4 SRGBtoLINEAR(vec4 srgbIn) {
    return vec4(pow(srgbIn.xyz, vec3(GAMMA)), srgbIn.w);
}

vec3 calculateDirLight(DirLight light) {
    vec3 normal = texture(uNormalTexture, vTexCoords).rgb;
    normal = normalize(normal * 2.0 - 1.0) * uNormalScale;
    vec3 N = normalize(normal);
    vec3 L = light.uLightDirection;
    vec3 V = normalize(-vViewSpacePosition);
    vec3 H = normalize(L + V);

    vec4 baseColorFromTexture = SRGBtoLINEAR(texture(uBaseColorTexture, vTexCoords));
    vec4 baseColor = baseColorFromTexture * uBaseColorFactor;
    float NdotL = clamp(dot(N, L), 0, 1);
    float NdotV = clamp(dot(N, V), 0, 1);
    float NdotH = clamp(dot(N, H), 0, 1);
    float VdotH = clamp(dot(V, H), 0, 1);

    float metallic = texture(uMetallicRoughnessTexture, vTexCoords).z * uMetallicFactor;
    float roughness = texture(uMetallicRoughnessTexture, vTexCoords).y * uRoughnessFactor;

    vec3 cDiff = mix(baseColor.rgb * (1 - dielectricSpecular.r), black, metallic);
    vec3 f0 = mix(dielectricSpecular, baseColor.rgb, metallic);
    float a = uRoughnessFactor * roughness;
    float a2 = a * a;

    // You need to compute baseShlickFactor first
    float baseShlickFactor = (1 - VdotH);
    float shlickFactor = baseShlickFactor * baseShlickFactor; // power 2
    shlickFactor *= shlickFactor; // power 4
    shlickFactor *= baseShlickFactor; // power 5
    vec3 F = f0 + (1 - f0) * shlickFactor;

    float deno = NdotL * sqrt(NdotV * NdotV * (1 - a2) + a2) + NdotV * sqrt(NdotL* NdotL * (1 - a2) + a2);
    float Vis;
    if (deno == 0.) {
        Vis = 0;
    }
    else {
        Vis = 0.5 / deno;
    }

    deno = M_PI * (NdotH * NdotH * (a2 - 1) + 1) * (NdotH * NdotH * (a2 - 1) + 1);
    float D;
    if (deno == 0.) {
        D = 0;
    }
    else {
        D = a2 / deno;
    }

    vec3 diffuse = cDiff * M_1_PI;
    vec3 f_diffuse = (1 - F) * diffuse;
    vec3 f_specular = F * Vis * D;

    vec4 emissive = texture(uEmissiveTexture, vTexCoords) * vec4(uEmissiveFactor, 1);

    vec4 occlusion = texture(uOcclusionTexture, vTexCoords);

    vec3 color = (f_diffuse + f_specular) * light.uLightIntensity * NdotL + emissive.xyz;
    color = mix(color, color * occlusion.x, uOcclusionStrength);
    color = LINEARtoSRGB(color);
    return color;
}

vec3 calculatePointLight(PointLight light) {
    vec3 normal = texture(uNormalTexture, vTexCoords).rgb;
    normal = normalize(normal * 2.0 - 1.0) * uNormalScale;
    vec3 N = normalize(normal);
    vec3 L = normalize(light.position - vViewSpacePosition);
    vec3 V = normalize(-vViewSpacePosition);
    vec3 H = normalize(L + V);

    vec4 baseColorFromTexture = SRGBtoLINEAR(texture(uBaseColorTexture, vTexCoords));
    vec4 baseColor = baseColorFromTexture * uBaseColorFactor;
    float NdotL = clamp(dot(N, L), 0, 1);
    float NdotV = clamp(dot(N, V), 0, 1);
    float NdotH = clamp(dot(N, H), 0, 1);
    float VdotH = clamp(dot(V, H), 0, 1);

    float metallic = texture(uMetallicRoughnessTexture, vTexCoords).z * uMetallicFactor;
    float roughness = texture(uMetallicRoughnessTexture, vTexCoords).y * uRoughnessFactor;

    vec3 cDiff = mix(baseColor.rgb * (1 - dielectricSpecular.r), black, metallic);
    vec3 f0 = mix(dielectricSpecular, baseColor.rgb, metallic);
    float a = uRoughnessFactor * roughness;
    float a2 = a * a;

    // You need to compute baseShlickFactor first
    float baseShlickFactor = (1 - VdotH);
    float shlickFactor = baseShlickFactor * baseShlickFactor; // power 2
    shlickFactor *= shlickFactor; // power 4
    shlickFactor *= baseShlickFactor; // power 5
    vec3 F = f0 + (1 - f0) * shlickFactor;

    float deno = NdotL * sqrt(NdotV * NdotV * (1 - a2) + a2) + NdotV * sqrt(NdotL* NdotL * (1 - a2) + a2);
    float Vis;
    if (deno == 0.) {
        Vis = 0;
    }
    else {
        Vis = 0.5 / deno;
    }

    deno = M_PI * (NdotH * NdotH * (a2 - 1) + 1) * (NdotH * NdotH * (a2 - 1) + 1);
    float D;
    if (deno == 0.) {
        D = 0;
    }
    else {
        D = a2 / deno;
    }

    vec3 diffuse = cDiff * M_1_PI;
    vec3 f_diffuse = (1 - F) * diffuse;
    vec3 f_specular = F * Vis * D;

    vec4 emissive = texture(uEmissiveTexture, vTexCoords) * vec4(uEmissiveFactor, 1);

    vec4 occlusion = texture(uOcclusionTexture, vTexCoords);
    
    // attenuation
    float distance    = length(light.position - vViewSpacePosition);
    float attenuation = 1.0 / (light.constant + light.linear * distance + 
  			     light.quadratic * (distance * distance));
  			     
	f_diffuse *= attenuation;
    f_specular *= attenuation;

    vec3 color = (f_diffuse + f_specular) * light.color * NdotL + emissive.xyz;
    color = mix(color, color * occlusion.x, uOcclusionStrength);
    color = LINEARtoSRGB(color);
    return color;
}

vec3 calculateSpotLight(SpotLight light) {
    vec3 normal = texture(uNormalTexture, vTexCoords).rgb;
    normal = normalize(normal * 2.0 - 1.0) * uNormalScale;
    vec3 N = normalize(normal);
    vec3 L = normalize(light.position - vViewSpacePosition);
    vec3 V = normalize(-vViewSpacePosition);
    vec3 H = normalize(L + V);
    
    float theta = dot(L, normalize(-light.direction)); 
    float epsilon = (light.cutOff - light.outerCutOff);
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

    vec4 baseColorFromTexture = SRGBtoLINEAR(texture(uBaseColorTexture, vTexCoords));
    vec4 baseColor = baseColorFromTexture * uBaseColorFactor;
    float NdotL = clamp(dot(N, L), 0, 1);
    float NdotV = clamp(dot(N, V), 0, 1);
    float NdotH = clamp(dot(N, H), 0, 1);
    float VdotH = clamp(dot(V, H), 0, 1);

    float metallic = texture(uMetallicRoughnessTexture, vTexCoords).z * uMetallicFactor;
    float roughness = texture(uMetallicRoughnessTexture, vTexCoords).y * uRoughnessFactor;

    vec3 cDiff = mix(baseColor.rgb * (1 - dielectricSpecular.r), black, metallic);
    vec3 f0 = mix(dielectricSpecular, baseColor.rgb, metallic);
    float a = uRoughnessFactor * roughness;
    float a2 = a * a;

    // You need to compute baseShlickFactor first
    float baseShlickFactor = (1 - VdotH);
    float shlickFactor = baseShlickFactor * baseShlickFactor; // power 2
    shlickFactor *= shlickFactor; // power 4
    shlickFactor *= baseShlickFactor; // power 5
    vec3 F = f0 + (1 - f0) * shlickFactor;

    float deno = NdotL * sqrt(NdotV * NdotV * (1 - a2) + a2) + NdotV * sqrt(NdotL* NdotL * (1 - a2) + a2);
    float Vis;
    if (deno == 0.) {
        Vis = 0;
    }
    else {
        Vis = 0.5 / deno;
    }

    deno = M_PI * (NdotH * NdotH * (a2 - 1) + 1) * (NdotH * NdotH * (a2 - 1) + 1);
    float D;
    if (deno == 0.) {
        D = 0;
    }
    else {
        D = a2 / deno;
    }

    vec3 diffuse = cDiff * M_1_PI;
    vec3 f_diffuse = (1 - F) * diffuse;
    vec3 f_specular = F * Vis * D;

    vec4 emissive = texture(uEmissiveTexture, vTexCoords) * vec4(uEmissiveFactor, 1);
    vec4 occlusion = texture(uOcclusionTexture, vTexCoords);
    
    f_diffuse *= intensity;
    f_specular *= intensity;
    
    // attenuation
    float distance = length(light.position - vViewSpacePosition);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));
    f_diffuse *= attenuation;
    f_specular *= attenuation;

    vec3 color = (f_diffuse + f_specular) * light.color * NdotL + emissive.xyz;
    color = mix(color, color * occlusion.x, uOcclusionStrength);
    color = LINEARtoSRGB(color);
    return color;
}

void main() {
	fColor = vec3(0.0f);
    fColor += calculateDirLight(dirLight);
    fColor += calculatePointLight(pointLight);
    fColor += calculateSpotLight(spotLight);
}
