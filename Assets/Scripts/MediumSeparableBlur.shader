Shader "Hidden/MediumSeparableBlur"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurTex ("Blur RenderTexture", 2D) = "white" {}
		//_BlurCoefficient ("Blur Coefficient", Float) = 1.0
		//_BlurDiameter  ("Blur Diameter", Range(0, 100)) = 1.0
	}
	CGINCLUDE
		#include "UnityCG.cginc"
	
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_TexelSize;
		//sampler2D _CameraDepthTexture;
		uniform float _BlurCoefficient;		// Calculated from the blur equation, b = ( f * ms / N )
		uniform float _BlurDiameter;
		
		
 		v2f_img vert_img_custom( appdata_img v )
		{
			v2f_img o;
			o.pos = UnityObjectToClipPos (v.vertex);
			float2 uv = MultiplyUV( UNITY_MATRIX_TEXTURE0, v.texcoord );
 			o.uv = uv;
			return o;
		}
	ENDCG
	
	SubShader {
		Pass{
			name "BlurH"
			ZTest Always Cull Off ZWrite Off  Lighting Off
			Fog { Mode off }
			Blend Off
		
			CGPROGRAM
			#pragma vertex vert_img_custom
			#pragma fragment frag
			//#pragma fragmentoption ARB_precision_hint_fastest 
			#pragma target 3.0
			//to make tex2Dlod work
			#pragma glsl 
			
			
			
			float4 frag(v2f_img i) : COLOR {
				const float MAX_BLUR_RADIUS = 10.0;
				//float2 tempuv = i.uv;
				//float d = UNITY_SAMPLE_DEPTH( tex2D(_CameraDepthTexture, tempuv) );
				float blurAmount = _BlurDiameter * _BlurCoefficient;
				blurAmount = min(floor(blurAmount), MAX_BLUR_RADIUS);
				
				float count = 0.0;
				float4 colour = float4(0.0, 0.0, 0.0, 0.0);
				float2 texelOffsetX = float2(_MainTex_TexelSize.x, 0.0);
				
				if ( blurAmount >= 1.0 ) {
					//bluramount should be at least 1 TODO add limit in 
					float halfBlur = blurAmount * 0.5;
					
					for (int idx = 0; idx < MAX_BLUR_RADIUS; ++idx) {
						//X direction
						if ( idx >= blurAmount )
								break;
								
						float offset = idx - halfBlur;
						float2 vOffset = i.uv + (texelOffsetX * offset);
						colour += tex2Dlod(_MainTex, float4(vOffset,0,0) );
						++count;
					
					}
				}
				float4 fragColor = tex2D (_MainTex, i.uv);

				/*
				if ( count > 0.0 ) {
					fragColor = colour / count;
				}
				fragColor.a = 1;
				return pow(fragColor, 1/2.2);
				*/
				return colour / count;
			}		
			ENDCG
		}
		Pass{
			name "BlurV"
			ZTest Always Cull Off ZWrite Off Lighting Off
			Fog { Mode off }
			Blend Off
		
			CGPROGRAM
			#pragma vertex vert_img_custom
			#pragma fragment frag
			//#pragma fragmentoption ARB_precision_hint_fastest 
			#pragma target 3.0
			//to make tex2Dlod work
			#pragma glsl 
			
			float4 frag(v2f_img i) : COLOR {
				const float MAX_BLUR_RADIUS = 10.0;
				//float2 tempuv = i.uv;
				//float d = UNITY_SAMPLE_DEPTH( tex2D(_CameraDepthTexture, tempuv) );
				float blurAmount = _BlurDiameter * _BlurCoefficient;
				blurAmount = min(floor(blurAmount), MAX_BLUR_RADIUS);
				
				float count = 0.0;
				float4 colour = float4(0.0, 0.0, 0.0, 0.0);
				float2 texelOffsetY = float2(0.0, _MainTex_TexelSize.y);
				
				if ( blurAmount >= 1.0 ) {
					//bluramount should be at least 1 TODO add limit in 
					float halfBlur = blurAmount * 0.5;
					
					for (int idx = 0; idx < MAX_BLUR_RADIUS; ++idx) {
						//X direction
						if ( idx >= blurAmount )
								break;
								
						float offset = idx - halfBlur;
						float2 vOffset = i.uv + (texelOffsetY * offset);
						colour += tex2Dlod(_MainTex, float4(vOffset,0,0));
						++count;
					
					}
				}
				
				float4 fragColor = tex2D (_MainTex, i.uv);
				/*
				if ( count > 0.0 ) {
					fragColor = colour / count;
				}
				fragColor.a = 1;
				*/
				return colour / count;
			}		
			ENDCG
		}
		Pass{
			name "DOFBlend"
			ZTest Always Cull Off ZWrite Off Lighting Off
			Fog { Mode off }
			Blend Off 
			
			CGPROGRAM
			#pragma vertex vert_img_custom
			#pragma fragment frag
			#pragma multi_compile UNITY_GAMMA UNITY_LINEAR 
			#pragma target 3.0
			//to make tex2Dlod work
			#pragma glsl

			sampler2D _BlurTex;
			
			float4 frag(v2f_img i) : COLOR {
				const float MAX_BLUR_RADIUS = 10.0;
				
				// Get the colour, depth, and blur pixels
				float4 colour = pow(tex2D( _MainTex, i.uv ), 1/2.2);
				//float2 tempuv = i.uv;
				//float depth = UNITY_SAMPLE_DEPTH( tex2D(_CameraDepthTexture, tempuv) );
				float blurAmount = _BlurDiameter;
				float4 blur = tex2D(_BlurTex, i.uv);
				
				// Linearly interpolate between the colour and blur pixels based on DOF
				float lerpV = min(blurAmount / MAX_BLUR_RADIUS, 1.0);
				 
				// Blend
				float4 fragColor = (colour * (1.0 - lerpV)) + (blur * lerpV);//lerp(color, blur, lerpV);//
	    		
	    		float4 finalColour;
	    		#if UNITY_LINEAR
	    		finalColour = float4(fragColor.rgb, 1.0);
	    		#else
	    		finalColour = float4(fragColor.rgb, 1/2.2 );
	    		#endif
	    		return finalColour; 
			}
							
			ENDCG
		}
		Pass{
			name "DebugBlit"
			ZTest Always Cull Off ZWrite Off Lighting Off
			Fog { Mode off }
			Blend Off 
			
			CGPROGRAM
			#pragma vertex vert_img_custom
			#pragma fragment frag
			#pragma multi_compile UNITY_GAMMA UNITY_LINEAR 
			#pragma target 3.0
			//to make tex2Dlod work
			#pragma glsl 
			
			float4 frag(v2f_img i) : COLOR {
				// Get the colour, depth, and blur pixels
				float4 colour = tex2D( _MainTex, i.uv );
	    		return colour; 
			}
							
			ENDCG
		}
	}
	FallBack Off
}
