Shader "Hidden/Custom/Linear"
{
    HLSLINCLUDE

    #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    float _Blend;

    float4 Frag(VaryingsDefault i) : SV_Target
    {
        float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
        //float3 toLinear = pow(color, 2.2);
        #ifdef UNITY_COLORSPACE_GAMMA
        float3 toGamma = pow( color.rgb, 0.45454545454 );
        color.rgb = toGamma;
        #endif
        return color;
    }

    ENDHLSL
    
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM 
            #pragma vertex VertDefault
            #pragma fragment Frag
 
            ENDHLSL
        }
    }
}
