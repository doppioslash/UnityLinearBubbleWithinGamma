// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/ImageEffectToGamma"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader {
		Pass{
			name "ToGamma"
			ZTest Always Cull Off ZWrite Off Lighting Off
			Fog { Mode off }
			Blend Off 
			
			CGPROGRAM
			#pragma vertex vert_img_custom
			#pragma fragment frag
			#pragma target 3.0
			//to make tex2Dlod work
			#pragma glsl 
			#include "UnityCG.cginc"
			#include "Includes/ColorConversion.cginc"
			
			uniform sampler2D _MainTex;
			uniform float _InnerVignetting;
			uniform float _OuterVignetting;
			
			v2f_img vert_img_custom( appdata_img v )
			{
				v2f_img o;
				o.pos = UnityObjectToClipPos (v.vertex);
				o.uv = MultiplyUV( UNITY_MATRIX_TEXTURE0, v.texcoord );
				return o;
			}
			
			float4 frag(v2f_img i) : COLOR {
				
				float4 colour = tex2D( _MainTex, i.uv );
				#ifdef UNITY_COLORSPACE_GAMMA
	    		colour = float4(LinearToSRGB(colour.rgb), 1.0);
				#endif
	    		return colour;
			}
							
			ENDCG
		}
	}
	FallBack Off
}
