#ifndef HYBRID_PREPAREPASS_INCLUDED
#define HYBRID_PREPAREPASS_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct Attributes
{
    float4 position     : POSITION;
    
#ifdef NEED_OUTPUT_NORMAL_INFO
	float3 normalOS     : NORMAL;

	#ifdef _NORMALMAP
	float4 tangentOS    : TANGENT;
	#endif
#endif

	float2 texcoord     : TEXCOORD0;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    float4 positionCS   : SV_POSITION;

#ifdef NEED_OUTPUT_NORMAL_INFO
	float3 normalWS                 : TEXCOORD1;

	#ifdef _NORMALMAP
	float4 tangentWS                : TEXCOORD2;
	#endif
#endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings DepthOnlyVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.uv = input.texcoord;
    output.positionCS = TransformObjectToHClip(input.position.xyz);

	// already normalized from normal transform to WS.
#ifdef NEED_OUTPUT_NORMAL_INFO
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);

	#ifdef _NORMALMAP
	real sign = input.tangentOS.w * GetOddNegativeScale();
	output.tangentWS = float4(TransformObjectToWorldNormal(input.tangentOS.xyz), sign);
	#endif
#endif

    return output;
}

half4 DepthOnlyFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    //Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _Tint, 1);

#if defined(NEED_OUTPUT_NORMAL_INFO) 
	half3 normalWS = input.normalWS.xyz;

	#ifdef _NORMALMAP
	half3 normalTS = SampleNormalMapTS(input.uv);
	half sgn = input.tangentWS.w;      // should be either +1 or -1
	half3 bitangent = sgn * cross(normalWS.xyz, input.tangentWS.xyz);
	normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, normalWS.xyz));
	normalWS = normalize(normalWS);
	#endif

	half bloom = 1;
	half outlineThreshold = 1;
	//SampleDetailMaskInfo(input.uv, 1, 1, bloom, outlineThreshold);

	//return half4(TransformWorldToViewDir(normalWS) * 0.5 + 0.5, outlineThreshold);
	return half4(EncodeViewNormalStereo(TransformWorldToViewDir(normalWS)), bloom, outlineThreshold);
#endif

    return 0;
}

#endif