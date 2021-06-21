Shader "Hybrid/Toon" 
{
    Properties 
    {
        [space(5)][Header(Texture)]
		[Texture(_Tint)]_BaseMap("BaseColor", 2D) = "white" {}

		//_LightTint("LightTint", Color) = (1,1,1,1)
        [HideInInspector][HDR]_Tint("Tint", Color) = (1,1,1,1)
		[HDR]_MidTint("MidTint",Color) = (1,0,0,1)
        _ShadowTint("ShadowTint",Color) = (0.6,0.6,0.6,1)
		_DarkTint("DarkTint", Color) = (0.5,0.5,0.5,1)
		//_LightThreshold("LightThreshold",Range(0,1)) = 0.5
        _ShadowThreshold("ShadowThreshold",Range(0,1)) = 0.5
		_DarkThreshold("DarkThreshold",Range(0,1)) = 0.5
        _ShadowFeather("ShadowFeather",Range(0,1)) = 0.02

		//[Texture]_RampTex("Ramp", 2D) = "white" {}
		[Texture]_MixTex("MixTex(R:Metallic, G:Roughness, B:Occlusion)", 2D) = "white" {}
		[Toggle(_PARALLAXMAP)]_ParallaxMap("Use ParallaxMap", Float) = 0
		[Toggle(_LIGHTOCCLUSION)]_LightOcclusion("LightOcclusion", Float) = 1
		_Parallax("Parallax", Float ) = 0
		[Texture]_NormalMap("NormalMap", 2D) = "bump" {}
		[Toggle(_USENORMALMAP)]_UseNormalMap("Use NormalMap",Float) = 1
		_NormalScale("NormalScale",Range(0,3)) = 1
		[Texture(_EmissionTint)]_EmissionTex("EmissionTex",2D) = "black" {}
		[HideInInspector][HDR]_EmissionTint("EmissionTint",Color) = (1,1,1,1)
		[Texture]_SpecularDetailMap("SpecularDetailMap", 2D) = "white"
		_SpecularDetailMapTile("DetailTile", Float) = 1
		//[Texture]_MatCap("MatCap", 2D) = "black" {}
		//[Texture]_NonmetalMatCap("NonmetalMatCap", 2D) = "black" {}
		[Toggle(_FIXTANGENT)]_FixTangent("FixTangent",Float) = 0
		[Toggle(_USEFLOWMAP)]_UseFlowMap("Use FlowMap",Float) = 0
		[Texture]_TangentNoise("TangentNoise", 2D) = "white" {}
		//[NoScaleOffset]_KelemenLUT("KelemenLUT", 2D) = "white" {}
		[Toggle(_DEBUG)]_DEBUG("Debug",Float) = 0

		[space(5)][Header(Diffuse)]
		[Toggle(_USENOV)]_UseNoV("Use NoV",Float) = 0

		[space(5)][Header(Specular)]
		[Toggle(_PBRMETAL)]_PBRMetal("PBR Metal",Float) = 0
		_SpecularTint("SpecularTint",Color) = (1,1,1,1)
		[Gamma]_Metallic("Metallic",Range(0,1)) = 1
		_Roughness("Roughness",Range(0,1)) = 1
		_IBLRoughness("IBL Roughness",Range(0,10)) = 1
		_SpecularIntensity("SpecularIntensity",Range(0,5)) = 1
		_Iridescence("Iridescence",Color) = (0.5,0.5,0.5,0)
		_Anisotropic("Anisotropic",Range(0,1)) = 0
		_TangentDistortion("TangentDistortion",Range(0,10)) = 0
		_TangentRotation("TangentRotation",Range(0,360)) = 0
		_Test1("test1",Float) = 1
		_Test2("test2",Float) = 1

    }
    SubShader
    {
		Tags { "Queue" = "Geometry" "IgnoreProjector" = "True" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        
		LOD 100

        Pass
        {
            Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward"}

			HLSLPROGRAM

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma vertex HybridBaseVertex
			#pragma fragment HybridToonFragment
			#pragma shader_feature _DIFFUSEMODE_RAMP _DIFFUSEMODE_DISNEY _DIFFUSEMODE_LAMBERT _DIFFUSEMODE_FABRIC _DIFFUSEMODE_ORENNAYAR
			#pragma shader_feature _SPECULARMODE_NONE _SPECULARMODE_RAMP _SPECULARMODE_CEL _SPECULARMODE_DISNEY _SPECULARMODE_MOBILE _SPECULARMODE_SKIN _SPECULARMODE_HAIR _SPECULARMODE_CLOTH _SPECULARMODE_BLINNPHONG
			#pragma shader_feature _USENOV
			#pragma shader_feature _PBRMETAL
			#pragma shader_feature _FIXTANGENT
			#pragma shader_feature _USEFLOWMAP
			#pragma shader_feature _USENORMALMAP
			#pragma shader_feature _USECLEARCOAT
			#pragma shader_feature _PARALLAXMAP
			#pragma shader_feature _LIGHTOCCLUSION
			#pragma shader_feature _DEBUG
            #pragma multi_compile _ _SHADOWS_SOFT _SHADOWS_PCSS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
		    #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHTS_FORWARD_PLUS
			#pragma multi_compile _ _MRT_PREPARE_NORMAL
			#pragma multi_compile _ _REFLECTION_ON

			#include "HybridPBRInput.hlsl"
			#include "HybridForwardPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

			//Blend[_SrcBlend][_DstBlend]
			//ZWrite[_ZWrite]
            //ZWrite On
            //ColorMask 0
            //Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _NORMALMAP
			//depth normal depthNormal

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "HybridPBRInput.hlsl"
            #include "HybridDepthPass.hlsl"
            ENDHLSL
        }

		Pass
		{
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}
		
			ZWrite On
			ZTest LEqual
			Cull Back
		
			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			//#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
		
			// -------------------------------------
			// Material Keywords
			#pragma shader_feature _ALPHATEST_ON
			#pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA
		
			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
		
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment
		
			#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
			ENDHLSL
		}

    }
	CustomEditor"HybridGUI"
}
 