Shader "Custom/PlainLinearLighting"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Custom
        #pragma target 4.0

        #include "UnityPBSLighting.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        float4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        inline void LightingCustom_GI (SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
			gi = UnityGlobalIllumination (data, 1.0, s.Normal);
		}

        inline float3 CorrectColorSpace(float3 color)
        {
            #ifdef UNITY_COLORSPACE_GAMMA
            color = GammaToLinearSpace(color);
            #endif
            return color;
        }

		inline float4 LightingCustom(SurfaceOutputStandard s, float3 viewDir, UnityGI gi)
        {
            UnityLight light = gi.light;
            #ifdef UNITY_COLORSPACE_GAMMA
            float3 lightColor = GammaToLinearSpace(light.color);
            #else
            float3 lightColor = light.color;
            #endif
            return float4(dot(s.Normal, light.dir) * lightColor * s.Albedo, 1);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            float3 linearAlbedo = tex2D (_MainTex, IN.uv_MainTex).rgb;
            float3 linearTint = _Color;
            linearAlbedo = CorrectColorSpace(linearAlbedo);
            linearTint = CorrectColorSpace(linearTint);
            o.Albedo = linearAlbedo * linearTint;
            // Metallic and smoothness come from slider variables
            o.Metallic = 0.0f;
            o.Smoothness = 0.0f;
            o.Alpha = 1.0f;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
