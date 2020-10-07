Shader "Hidden/SimpleSeparableBlur"
{
    Properties {
    _MainTex ("", 2D) = "white" {}
    _BlurSize ("", Range(0.0, 1.0)) = 1.0
  }
  
  CGINCLUDE

    #include "UnityCG.cginc"
    
    //float _Threshold, _SoftThreshold;
    uniform float _Intensity;
    uniform sampler2D _MainTex, _SrcTex;
    uniform float4 _MainTex_TexelSize;
    float4 _Filter;
    uniform float _BlurSize;
  
    struct v2f {
        float4 pos : POSITION;
        float2 uv : TEXCOORD0;
      };  

    v2f vert(appdata_img v) {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord;
        return o;
      }

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

  SubShader {
      
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

    Pass { // Pass 0 - Horizontal
      ZTest Always Cull Off ZWrite Off
      Fog { Mode off }
      Blend Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      //#pragma fragmentoption ARB_precision_hint_fastest

      float4 frag(v2f i) : COLOR {
        float4 color = 0.16 * tex2D(_MainTex, i.uv);
        color += 0.15 * tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * float2(1.0 * _BlurSize, 0.0));
        color += 0.15 * tex2D(_MainTex, i.uv - _MainTex_TexelSize.xy * float2(1.0 * _BlurSize, 0.0));
        color += 0.12 * tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * float2(2.0 * _BlurSize, 0.0));
        color += 0.12 * tex2D(_MainTex, i.uv - _MainTex_TexelSize.xy * float2(2.0 * _BlurSize, 0.0));
        color += 0.09 * tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * float2(3.0 * _BlurSize, 0.0));
        color += 0.09 * tex2D(_MainTex, i.uv - _MainTex_TexelSize.xy * float2(3.0 * _BlurSize, 0.0));
        color += 0.06 * tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * float2(4.0 * _BlurSize, 0.0));
        color += 0.06 * tex2D(_MainTex, i.uv - _MainTex_TexelSize.xy * float2(4.0 * _BlurSize, 0.0));
        return color;
      }
      ENDCG
    }

    Pass { // Pass 1 - Vertical
      ZTest Always Cull Off ZWrite Off
      Fog { Mode off }
      Blend Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      //#pragma fragmentoption ARB_precision_hint_fastest

      float4 frag(v2f i) : COLOR {
        float4 color = 0.16 * tex2D(_MainTex, i.uv);
        color += 0.15 * tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * float2(0.0, 1.0 * _BlurSize));
        color += 0.15 * tex2D(_MainTex, i.uv - _MainTex_TexelSize.xy * float2(0.0, 1.0 * _BlurSize));
        color += 0.12 * tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * float2(0.0, 2.0 * _BlurSize));
        color += 0.12 * tex2D(_MainTex, i.uv - _MainTex_TexelSize.xy * float2(0.0, 2.0 * _BlurSize));
        color += 0.09 * tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * float2(0.0, 3.0 * _BlurSize));
        color += 0.09 * tex2D(_MainTex, i.uv - _MainTex_TexelSize.xy * float2(0.0, 3.0 * _BlurSize));
        color += 0.06 * tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * float2(0.0, 4.0 * _BlurSize));
        color += 0.06 * tex2D(_MainTex, i.uv - _MainTex_TexelSize.xy * float2(0.0, 4.0 * _BlurSize));
        return color;
      }
      ENDCG
    }
    
    Pass
        {//2 ApplyBloomPass
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
        {//3 DebugBloomPass
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

  Fallback off
}