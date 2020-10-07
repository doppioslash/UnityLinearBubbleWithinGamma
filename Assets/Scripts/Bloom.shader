Shader "Hidden/BoxBloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    
    CGINCLUDE

    #include "UnityCG.cginc"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        return o;
    }
    
    //float _Threshold, _SoftThreshold;
    float _Intensity;
    sampler2D _MainTex, _SrcTex;
    float4 _MainTex_TexelSize;
    float4 _Filter;

    float3 Prefilter (float3 c)
    {
        float brightness = max(c.r, max(c.g, c.b));

        //float knee = _Threshold * _SoftThreshold;
        float soft = brightness - _Filter.y;//_Threshold + knee;
        soft = clamp(soft, 0, _Filter.z);//2 * knee);
        soft = soft * soft * _Filter.w;/// (4 * knee + 0.00001);
        
        float contribution = max(soft, brightness - _Filter.x);//_Threshold);
        contribution /= max(brightness, 0.0001);
        return c * contribution;
    }

    float3 Sample(float2 uv)
    {
        return tex2D(_MainTex, uv).rgb;
    }

    float3 SampleBox(float2 uv, float delta)
    {
        float4 o = _MainTex_TexelSize.xyxy * float2(-delta, delta).xxyy;

        float3 s = Sample(uv + o.xy) + Sample(uv + o.zy) + Sample(uv + o.xw) + Sample(uv + o.zw);
        
        return s * 0.25f;
    }
    ENDCG
    
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {//0 BoxDownPrefilterPass
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag (v2f i) : SV_Target
            {
                return float4(Prefilter(SampleBox(i.uv, 1)), 1);
            }
            ENDCG
        }
        
        Pass
        {//1 BoxDownPass
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            float4 frag (v2f i) : SV_Target
            {
                return float4(SampleBox(i.uv, 1), 1);
            }
            ENDCG
        }
        
        Pass
        {//2 BoxUpPass
            Blend One One
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag (v2f i) : SV_Target
            {
                float4 col = float4(SampleBox(i.uv, 0.5), 1);
                return col;
            }
            ENDCG
        }
        
        Pass
        {//3 ApplyBloomPass
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            float4 frag (v2f i) : SV_Target
            {
                float4 src = tex2D(_SrcTex, i.uv);
                src.rgb += _Intensity * SampleBox(i.uv, 0.5);
                return src;
            }
            ENDCG
        }
        Pass
        {//4 DebugBloomPass
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag (v2f i) : SV_Target
            {
                return float4(_Intensity * SampleBox(i.uv, 0.5), 1);
            }
            ENDCG
        }
    }
}
