#ifndef HYBRID_PBRINPUT_INCLUDED
#define HYBRID_PBRINPUT_INCLUDED
#define PI 3.14159265358979323846
#define HALF_MIN 6.103515625e-5
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


//CBUFFER_START(UnityPerMaterial)
//Texture
TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);

TEXTURE2D(_MixTex);
SAMPLER(sampler_MixTex);

TEXTURE2D(_RampTex);
SAMPLER(sampler_RampTex);

TEXTURE2D(_EmissionTex);
SAMPLER(sampler_EmissionTex);

TEXTURE2D(_SpecularDetailMap);
SAMPLER(sampler_SpecularDetailMap);

TEXTURE2D(_TangentNoise);
SAMPLER(sampler_TangentNoise);
half4 _TangentNoise_ST;

TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);

TEXTURE2D(_MatCap);
SAMPLER(sampler_MatCap);

TEXTURE2D(_NonmetalMatCap);
SAMPLER(sampler_NonmetalMatCap);

TEXTURE2D(_FurNoise);
SAMPLER(sampler_FurNoise);
half4 _FurNoise_ST;
half2 _FurOffset;

//Color
half3 _LightTint;
half3 _Tint;
half3 _ShadowTint;
half3 _DarkTint;
half4 _Layer1Tint;
half4 _Layer2Tint;
half4 _Layer3Tint;
half3 _SpecularTint;
half3 _SubsurfaceTint;
half3 _SheenTint;
half4 _Iridescence;
half4 _Layer1ShininessTint;
half4 _Layer2ShininessTint;
half4 _Layer3ShininessTint;
half3 _SpecularTint1;
half3 _SpecularTint2;
half3 _ShadowColor;
half4 _RimLightColor;
half3 _EmissionTint;
//Paramter
half _Layer1Offset;
half _Layer2Offset;
half _Layer3Offset;
half _NormalScale;
half _RampSmooth;
half _Metallic;
half _Roughness;
half _IBLRoughness;
half _SpecularIntensity;
half _SubsurfaceIntensity;
half _SubsurfaceFalloff;
half _Anisotropic;
half _TangentRotation;
half _TangentDistortion;
half _Sheen;
half _ClearCoat;
half _ClearCoatGloss;
half _Cloth;
half _Layer1RoughnessX;
half _Layer1RoughnessY;
half _Layer2RoughnessX;
half _Layer2RoughnessY;
half _Layer3RoughnessX;
half _Layer3RoughnessY;
half _Layer1ShininessOffset;
half _Layer2ShininessOffset;
half _Layer3ShininessOffset;
half _Layer1ShininessDirection;
half _Layer2ShininessDirection;
half _Layer3ShininessDirection;
half _Layer1Shininess;
half _Layer2Shininess;
half _Layer3Shininess;
half _NormalSoftness;
half3 _EyeForward;
half _Parallax;
half _SpecularDetailMapTile;

half _SpecularExponent1;
half _SpecularExponent2;
half _Shift1;
half _Shift2;
half _Specular1Intensity;
half _Specular2Intensity;
half _ShadowThreshold;
half _DarkThreshold;
half _ShadowFeather;

half3 _RimLightViewDir;
half _RimLightExponent;
half _RimLightIntensity;
half _RimLightSmoothness;
half _HeightOffset;
half _DiffuseHeightOffset;
half _DiffuseOffsetSmooth;
half _RampHeightOffset;
half _RampOffsetSmooth;
half3 _ViewDirOffset;

half3 _LightDir;

//Fur
half _Opacity;
half _Offset;
half _FurAO;
half _FurAOPow;
half2 _SmoothStep;
//CBUFFER_END

//ToonParamter
float3 _MidTint;
float3 debug;
float _Test1,_Test2;

struct NPRInputData
{
    half3  positionWS;
    half3  normalWS;
    half3  difNormalWS;
	half3  tangentWS;
	half3  bitangentWS;
    half3  viewDirWS;
    half3  halfVecWS;
    half4  shadowCoord;
    half   fogCoord;
    half3  vertexLighting;
    half3  bakedGI;
    half2  screenUV;
    half3  clearCoatNormalWS;
};

struct NPRSurfaceData
{
    half3  baseColor;
    half3  shadowTint;
    half3  specular;
    half   specularDetail;
    half   metallic;
    half   roughness;
    half   subsurface;
    half   anisotropic;
    half4  tangentNoise;
    half   sheen;
    half   clearCoat;
    half   clearCoatGloss;
    half3  emission;
    half   occlusion;
    half   alpha;
    half3  normalTS;
    half4  iridescence;
    half   cloth;
};

struct BxDFContext
{
    half NoL;
    half NoV;
    half NoH;
    half LoH;
    half VoH;
    half VoL;

    half XoL;
    half YoL;
    half XoV;
    half YoV;
    half XoH;
    half YoH;
};

void InitializeBxDFContext(NPRInputData inputData, half3 L, out BxDFContext Context)
{
    Context = (BxDFContext)0;
    half3 N = inputData.normalWS;
    half3 V = inputData.viewDirWS;
    half3 X = inputData.tangentWS;
    half3 Y = inputData.bitangentWS;
    half3 H = normalize(L + V);

    //Context.VoL = dot(V, L);
	//float InvLenH = rsqrt( 2 + 2 * Context.VoL );

	Context.NoH = dot(N, H);
	Context.VoH = dot(V, H);
	Context.LoH = dot(L, H);
	Context.NoL = dot(N, L);
    Context.NoV = dot(N, V);
#ifdef _USENOV
    Context.NoL = dot(N, V + _ViewDirOffset);
#endif

//Anisotropic
#ifdef _SPECULARMODE_DISNEY
    Context.XoL = dot(L, X);
	Context.YoL = dot(L, Y);
	Context.XoV = dot(V, X);
	Context.YoV = dot(V, Y);
    Context.XoH = dot(X, H);
	Context.YoH = dot(Y, H);
#endif

}

half3 CustomUnpackNormalScale(half4 packedNormal, half scale)
{
    real3 normal;
    normal.xy = packedNormal.rg * 2.0 - 1.0;
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
    normal.xy *= scale;
    return normal;
}

void InitializeNPRSurfaceData(float2 uv, float3 viewDirForParallax, out NPRSurfaceData surfaceData)
{
	surfaceData = (NPRSurfaceData)1;
    
    half4 mixTex = SAMPLE_TEXTURE2D(_MixTex,sampler_MixTex,uv);
#ifdef _PARALLAXMAP
    half height = mixTex.a;
    half parallax = height * _Parallax - _Parallax / 2;
	viewDirForParallax = normalize(viewDirForParallax);
	uv.xy = (viewDirForParallax.xy / (viewDirForParallax.z + 0.42)) * parallax + uv.xy;
#endif

	surfaceData.metallic = max(mixTex.r * _Metallic,HALF_MIN);
	surfaceData.roughness = max(mixTex.g * _Roughness,HALF_MIN);
    surfaceData.occlusion = mixTex.b;

	half4 mainTex = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv);
    surfaceData.baseColor = (mainTex.rgb) * _Tint;
	surfaceData.shadowTint = surfaceData.baseColor * _ShadowTint;
	surfaceData.subsurface = mainTex.a * _SubsurfaceIntensity;

    half4 normalTex = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
	surfaceData.normalTS = UnpackNormalScale(normalTex, _NormalScale);

	surfaceData.specular = _SpecularTint * _SpecularIntensity;
    surfaceData.specularDetail = SAMPLE_TEXTURE2D(_SpecularDetailMap,sampler_SpecularDetailMap,uv*_SpecularDetailMapTile).r;
	surfaceData.anisotropic = _Anisotropic;
	surfaceData.tangentNoise = SAMPLE_TEXTURE2D(_TangentNoise,sampler_TangentNoise,uv);
	surfaceData.tangentNoise.a *= _TangentDistortion;
	surfaceData.clearCoat = _ClearCoat * (1-sqrt(surfaceData.roughness));
	surfaceData.clearCoatGloss = _ClearCoatGloss * (1-sqrt(surfaceData.roughness));
	surfaceData.iridescence = _Iridescence;
	surfaceData.cloth = _Cloth;
    surfaceData.emission = SAMPLE_TEXTURE2D(_EmissionTex, sampler_EmissionTex, uv).rgb * _EmissionTint;
}


half3 EnvBRDFApprox( half3 SpecularColor, half Roughness, half NoV )
{
	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	// Adaptation to fit our G term.
	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
	half4 r = Roughness * c0 + c1;
	half a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
	half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	// Note: this is needed for the 'specular' show flag to work, since it uses a SpecularColor of 0
	AB.y *= saturate( 50.0 * SpecularColor.g );

	return SpecularColor * AB.x + AB.y;
}

half2 CalculateIBLUV(half2 uv, half roughness)
{
    half tile = 4;
	half frame = floor(roughness*(tile*tile));
	float row = floor(frame/tile);
	float column = frame - row*tile;
	uv  = uv + half2(column,row);
	uv.x/=tile;
	uv.y/=tile;
	return uv;
}

half3 MatCapSample(half3 N, half3 V, half roughness, half metallic)
{
    half3 vN = mul(UNITY_MATRIX_V,half4(N,1)).xyz;
	half m = 2.82842712474619 * sqrt(vN.z + 1.0);//Magic!
	half2 magicUV = vN.xy/m + 0.5;
    half2 uv = CalculateIBLUV(magicUV,roughness);
    half3 metalmatcap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, uv).rgb;//NtoV�1�7�1�7�1�7�1�7�1�7�1�7�1�7�1�7�1�7�1�7�1�7�1�7�0�0�1�7�0�8�1�7�1�7XY�1�7�1�7�1�7�1�7�1�7�0�3�1�7�0�4�0�8
	half3 nonmetalmatcap = SAMPLE_TEXTURE2D(_NonmetalMatCap, sampler_NonmetalMatCap, uv).rgb;
	half3 matcap = lerp(nonmetalmatcap,metalmatcap,metallic);
    return matcap;
}

half3 MatCapSample(half3 N, half3 V)
{
    half3 vN = mul(UNITY_MATRIX_V,half4(N,1)).xyz;
	// float m = 2. * sqrt(pow(vN.x, 2.) + pow(vN.y, 2.) + pow(vN.z + 1., 2.));
	half m = 2.82842712474619 * sqrt(vN.z + 1.0);//Magic!
    half2 magicUV = vN.xy/m + 0.5;
    half3 matcap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, magicUV*0.5+0.5).rgb;
    return matcap;
}

half3 IndirectLighting(half3 SH, NPRInputData inputData, NPRSurfaceData surfaceData)
{
	half3 color = SH * surfaceData.baseColor * (1-surfaceData.metallic) * surfaceData.occlusion;
	half roughness = saturate(surfaceData.roughness * _IBLRoughness);
	half3 IBL = 0;
#ifdef _IBLMODE_IBL
    half3 reflectVector = reflect(-inputData.viewDirWS, inputData.normalWS);
	IBL = GlossyEnvironmentReflection(reflectVector,sqrt(roughness),surfaceData.occlusion);
	//IBL = SRGBToLinear(IBL);
	//float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
	half3 indirectSpecular = lerp(kDieletricSpec.rgb, max(0.01,surfaceData.baseColor), surfaceData.metallic);
    //c += surfaceReduction * indirectSpecular * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
	indirectSpecular = EnvBRDFApprox(indirectSpecular,roughness,saturate(dot(inputData.normalWS,inputData.viewDirWS))); 
	indirectSpecular *= IBL;
	color += indirectSpecular;
#elif _IBLMODE_MATCAPSHEET
	IBL = MatCapSample(inputData.normalWS,inputData.viewDirWS,roughness,surfaceData.metallic);
	IBL *= surfaceData.occlusion;
	color += IBL;
#elif _IBLMODE_MATCAP
	IBL = MatCapSample(inputData.normalWS,inputData.viewDirWS) * (1-roughness);
	IBL *= surfaceData.occlusion;
	color += IBL;
#endif

	return color;
}

#endif