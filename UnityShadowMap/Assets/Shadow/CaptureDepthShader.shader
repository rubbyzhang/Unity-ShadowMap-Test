Shader "ShadowMap/CaptureDepth"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 depth: TEXCOORD0;
			};
		
			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.depth = o.vertex.zw ;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return EncodeFloatRGBA(i.depth.x/i.depth.y) ;
			}
			ENDCG
		}
	}
}
//{
//	Properties 
//	{
//		//_MainTex ("", 2D) = "white" {}
//		//_Cutoff ("", Float) = 0.5
//		//_Color ("", Color) = (1,1,1,1)
//	}
//	//Category {Fog { Mode Off }
//
//	SubShader 
//	{
//		Tags { "RenderType"="Opaque" }
//		Pass 
//		{
//				CGPROGRAM
//				#pragma vertex vert
//				#pragma fragment frag
//				#include "UnityCG.cginc"
//
//				struct v2f 
//				{
//				    float4 pos : POSITION;
//				    float2 depth : TEXCOORD0;
//				};
//				v2f vert( appdata_base v ) 
//				{
//				    v2f o;
//				    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
//				    //UNITY_TRANSFER_DEPTH(o.depth);
//				    o.depth = o.pos.zw ;
//				    return o;
//				}
//				fixed4 frag(v2f i) : COLOR 
//				{
//					float depth = i.depth.x/i.depth.y ;
//					//return  fixed4(depth,depth,depth,1) * 10;
//				    //UNITY_OUTPUT_DEPTH(i.depth) * 0.5 + 0.5 ;
//
//				    return EncodeFloatRGBA(depth);
//				}
//				ENDCG
//		 }
//	}
//}