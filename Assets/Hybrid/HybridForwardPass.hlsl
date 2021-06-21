#ifndef HYBRID_FORWARDPASS_INCLUDED
#define HYBRID_FORWARDPASS_INCLUDED
#include "./HybridPBRInput.hlsl"
#include "./HybridInput.hlsl"
#include "./HybridBxDF.hlsl"
#include "./HybridToonBxDF.hlsl"
#include "./ShadingModels.hlsl"

struct Attributes
{
	float3 positionOS   : POSITION;
	float2 uv           : TEXCOORD0;
	float2 lightmapUV   : TEXCOORD1;
#ifdef _FIXTANGENT
	float2 uv2			: TEXCOORD2;
#endif
	float3 normalOS		: NORMAL;
	float4 tangentOS	: TANGENT;
	float4 color		: COLOR;
};

struct Varyings
{
	float4 positionCS   : SV_POSITION;
	float4 color		: COLOR;
	float2 uv           : TEXCOORD0;
	float3 positionWS	: TEXCOORD1;
	float3 normalWS		: TEXCOORD2;
	float4 tangentWS	: TEXCOORD3;
	float3 bitangentWS	: TEXCOORD4;
	//float4 projPos	: TEXCOORD5;
	half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
	float4 shadowCoord              : TEXCOORD7;
	DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 8);
#ifdef _FIXTANGENT
	float2 uv2			: TEXCOORD9;
#endif

#ifdef _FUR
	float2 fur_uv		: TEXCOORD10;
#endif

#ifdef _PARALLAXMAP
	float3 viewDirForParallax : TEXCOORD11;
#endif
};

void InitializeNPRInputData(Varyings input, half3 normalTS, half4 tangentNoise, out NPRInputData inputData)
{
    inputData = (NPRInputData)0;

	half3 X1, Y1;
	CalculateTangentRotateOffset(_TangentRotation,_Layer1ShininessOffset,input.normalWS.xyz,input.tangentWS.xyz,X1,Y1);

	float3x3 m_tangentToWorld = float3x3(X1, Y1, input.normalWS);
#ifdef _USENORMALMAP
	float3 normalTexWS = TransformTangentToWorld(normalTS, m_tangentToWorld);
#else
	float3 normalTexWS = input.normalWS;
#endif

    inputData.positionWS = input.positionWS;
	inputData.normalWS = NormalizeNormalPerPixel(normalTexWS);
	inputData.difNormalWS = input.normalWS;

#ifdef _USEFLOWMAP
	half3 tangenTex = CustomUnpackNormalScale(tangentNoise.xyzz,1);
	tangenTex = TransformTangentToWorld(tangenTex,m_tangentToWorld);
	inputData.tangentWS = normalize(tangenTex);
	inputData.bitangentWS = normalize(cross(inputData.normalWS,inputData.tangentWS));
#else
	inputData.tangentWS.xyz = X1;
	inputData.bitangentWS = Y1;
#endif

#ifdef _USEREFRACTION
	inputData.screenUV = ComputeScreenPos(input.positionCS);
#endif

#ifdef _USECLEARCOAT
	inputData.clearCoatNormalWS = input.normalWS;
#endif

    inputData.viewDirWS = normalize(GetCameraPositionWS() - inputData.positionWS);
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);

}

Varyings HybridBaseVertex(Attributes input)
{
	Varyings output = (Varyings)0;

#ifdef _FIXTANGENT
	output.uv = input.uv;
	output.uv2 = TRANSFORM_TEX(input.uv2,_TangentNoise);
#else
	output.uv = TRANSFORM_TEX(input.uv,_TangentNoise);
#endif

#ifdef _FUR
	output.fur_uv = TRANSFORM_TEX(input.uv,_FurNoise);
	output.fur_uv.x += _FurOffset.x;
	output.fur_uv.y += _FurOffset.y;

    half noise = SAMPLE_TEXTURE2D_LOD(_FurNoise,sampler_FurNoise,output.fur_uv,0).r;
	noise = saturate(smoothstep(_SmoothStep.x,_SmoothStep.y,noise));
    input.positionOS.xyz += _Offset * noise * input.normalOS;
#endif

	VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
	//half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    output.positionWS = vertexInput.positionWS;
	output.positionCS = vertexInput.positionCS;

    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
	output.normalWS = normalInput.normalWS;
    output.tangentWS.xyz = normalInput.tangentWS;
	output.tangentWS.w = input.tangentOS.w * GetOddNegativeScale();
	output.bitangentWS = normalInput.bitangentWS;
	output.color = input.color;

#ifdef _PARALLAXMAP
	float3 binormalOS = cross(normalize(input.normalOS), normalize(input.tangentOS.xyz)) * input.tangentOS.w;
	float3x3 rotation = float3x3(input.tangentOS.xyz, binormalOS, input.normalOS);
	float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(GetCameraPositionWS(), 1)).xyz;

	output.viewDirForParallax = mul(rotation, objSpaceCameraPos - input.positionOS.xyz);
#endif

	half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
	//output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
	output.shadowCoord = TransformWorldToShadowCoord(vertexInput.positionWS);
    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

	return output;
}

float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return ((x*(a*x+b))/(x*(c*x+d)+e));
}

half4 HybridPBRFragment(Varyings input) : SV_Target
{
	NPRSurfaceData surfaceData;
	half2 uv;
#ifdef _FIXTANGENT
	uv = input.uv2;
#else
	uv = input.uv;
#endif

	half3 viewDirForParallax; 
#ifdef _PARALLAXMAP
	viewDirForParallax = input.viewDirForParallax;
#else
	viewDirForParallax = 1;
#endif

    InitializeNPRSurfaceData(uv, viewDirForParallax, surfaceData);

    NPRInputData inputData;
    InitializeNPRInputData(input, surfaceData.normalTS, surfaceData.tangentNoise, inputData);

	half4 color = HybridPBR(inputData,surfaceData);
	//color.rgb = ACESFilm(color.rgb);
	//color.rgb = LinearToGamma22(color.rgb);
	
#ifdef _FUR
	color.rgb -= pow(_FurAO - _Offset,_FurAOPow);
	color.a *= SAMPLE_TEXTURE2D(_FurNoise,sampler_FurNoise,uv) * saturate(_Opacity);
#endif

#ifdef _DEBUG
	return debug.xyzz;
	return LinearToGamma22(debug.xyzz);
#endif
	return color;
}

half4 HybridToonFragment(Varyings input) : SV_Target
{
	NPRSurfaceData surfaceData;
	half2 uv;
#ifdef _FIXTANGENT
	uv = input.uv2;
#else
	uv = input.uv;
#endif

	half3 viewDirForParallax; 
#ifdef _PARALLAXMAP
	viewDirForParallax = input.viewDirForParallax;
#else
	viewDirForParallax = 1;
#endif

    InitializeNPRSurfaceData(uv, viewDirForParallax, surfaceData);

    NPRInputData inputData;
    InitializeNPRInputData(input, surfaceData.normalTS, surfaceData.tangentNoise, inputData);

	half4 color = HybridToon(inputData,surfaceData);
	//color.rgb = ACESFilm(color.rgb);
	//color.rgb = LinearToGamma22(color.rgb);
#ifdef _DEBUG
	return debug.xyzz;
#endif
	half alpha = OutputAlpha(color.a); 
	
	return color;

}

#endif