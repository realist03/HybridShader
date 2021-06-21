#ifndef HYBRID_TOONBXDF_INCLUDED
#define HYBRID_TOONBXDF_INCLUDED
#include "HybridPBRInput.hlsl"
#include "HybridBxDF.hlsl"

half3 RGBToHSV(half3 c)
{
	half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	half4 p = lerp( half4( c.bg, K.wz ), half4( c.gb, K.xy ), step( c.b, c.g ) );
	half4 q = lerp( half4( p.xyw, c.r ), half4( c.r, p.yzx ), step( p.x, c.r ) );
	half d = q.x - min( q.w, q.y );
	half e = 1.0e-10;
	return half3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVToRGB( float3 c )
{
	float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
	float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
	return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
}

half GetLuminance(half3 color)
{
    return .3*color[0] + .6*color[1]  + .1*color[2];
}

half3 Toon_Diffuse(NPRSurfaceData surfaceData , Light light, half NoL, half NoV, out half shadowStep)
{
    float halfLambert = NoL * 0.5 + 0.5;
    //float lightStep = saturate(1.0 - (halfLambert - (_LightThreshold - _ShadowFeather)) / max(_ShadowFeather,HALF_MIN));
    shadowStep = saturate(1.0 - (halfLambert - (_ShadowThreshold - _ShadowFeather)) / max(_ShadowFeather,HALF_MIN));
#ifdef _LIGHTOCCLUSION
	float baseStep = (1 - shadowStep) * surfaceData.occlusion;
#else
	float baseStep = (1 - shadowStep);
#endif
	shadowStep = 1 - baseStep;
    float3 midColor = shadowStep * (1- shadowStep) * _MidTint;
    half3 color = lerp(surfaceData.baseColor, surfaceData.shadowTint, shadowStep) + midColor;
    //Shadow
	half3 radiance = light.shadowAttenuation;
	radiance *= light.distanceAttenuation;
	half3 lightTerm = color * radiance;
	half3 darkTerm = surfaceData.shadowTint * (1-radiance);
	color = lightTerm + darkTerm;

    float darkStep = saturate((halfLambert - (_ShadowThreshold*_DarkThreshold - _ShadowFeather)) / max(_ShadowFeather,HALF_MIN));
    color = lerp(color*_DarkTint, color, darkStep);
	
	#ifdef _PBRMETAL
	  color *= max(1-surfaceData.metallic,HALF_MIN);
	#endif

    return color;
}

half3 StylizedSpecular(half3 specular, half3 specularColor)
{
    specular = saturate(specular);
	half lum =GetLuminance(specular);
    lum = smoothstep(_Test1,_Test2,lum);
    specular = lum * specularColor;
    return specular;
}

half3 HybridToonLit(NPRInputData inputData, NPRSurfaceData surfaceData, Light light)
{
    half3 N = inputData.normalWS;
	half3 L = light.direction;
	half3 V = inputData.viewDirWS;
	half3 X = inputData.tangentWS;
	half3 Y = inputData.bitangentWS;
	half3 H = normalize(L + V);

    BxDFContext Context;
	InitializeBxDFContext(inputData,L,Context);

	half NoV = Context.NoV;
	half NoH = Context.NoH;
	half LoH = Context.LoH;
	half VoH = Context.VoH;
	half NoL = Context.NoL;
	half XoL = Context.XoL;
	half YoL = Context.YoL;
	half XoV = Context.XoV;
	half YoV = Context.YoV;
	half XoH = Context.XoH;
	half YoH = Context.YoH;

    half3 color = 0;

//Pre Light
    half3 hLightCol = RGBToHSV(saturate(light.color.rgb));
    hLightCol.r += 0.495;
    half3 rLightCol = HSVToRGB(hLightCol);
	//rLightCol = Hue(_Test2);
    surfaceData.baseColor *= light.color*light.distanceAttenuation;
    surfaceData.shadowTint *= rLightCol*light.distanceAttenuation*2;
	_DarkTint *= rLightCol*light.distanceAttenuation*2;
	//_MidTint *= light.color;

//Diffuse
	half difNoL = dot(inputData.difNormalWS,L);
	half shadowStep;
    color += Toon_Diffuse(surfaceData, light, difNoL, NoV, shadowStep);
//Specular
    half3 specular = 0;
	specular = DisneyBRDF(surfaceData,NoL,NoV,NoH,LoH,XoL,YoL,XoV,YoV,XoH,YoH);
    specular *= light.color * light.shadowAttenuation * light.distanceAttenuation * NoL*(1-shadowStep) * surfaceData.occlusion * PI;
    specular = StylizedSpecular(specular,surfaceData.specular);
    color += specular * surfaceData.specularDetail;

	color += surfaceData.emission;
    //color *= light.color;
    //color.rgb = N;

    return color;
}

half4 HybridToon(NPRInputData inputData, NPRSurfaceData surfaceData)
{
    Light light = GetMainLight(inputData.shadowCoord);

	half4 color = half4(HybridToonLit(inputData,surfaceData,light),1);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        color +=  half4(HybridToonLit(inputData,surfaceData,light),1);
    }
#endif

//IndirectLight
	//half3 indirectColor = IndirectLighting(inputData.bakedGI,inputData,surfaceData);
	//indirectColor = StylizedSpecular(indirectColor,1);
	half3 indirectColor = SampleSH(0) * color.rgb;
	color.rgb += indirectColor;
    return color;
}

#endif