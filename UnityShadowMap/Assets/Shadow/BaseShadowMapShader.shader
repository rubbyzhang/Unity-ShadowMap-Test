// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Shadow/BaseShadowMapShader"
{
    Properties
    {
		_MainTex ("Base (RGB)", 2D) = "white" {}
    }

	SubShader
	{
		Tags
		{
		 	"RenderType"="Opaque" 
	 	}
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex object_vert
			#pragma fragment object_frag
		
			#include "UnityCG.cginc"

            uniform half4 _MainTex_TexelSize;
            sampler2D _MainTex;

            sampler2D _LightDepthTex;

            float4x4 _LightProjection;

			struct appdata
			{
				float4 vertex : POSITION;
				float4 worldPos: TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 worldPos: TEXCOORD0; 
			};
			
			v2f object_vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);

				float4 worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.worldPos.xyz = worldPos.xyz ;
				o.worldPos.w = 1 ;
				return o;
			}
			
			fixed4 object_frag (v2f i) : SV_Target
			{
				// convert to light camera space
				fixed4 lightClipPos = mul(_LightProjection , i.worldPos);
			    lightClipPos.xyz = lightClipPos.xyz / lightClipPos.w ;
				float3 pos = lightClipPos * 0.5 + 0.5 ;


			//	return fixed4(lightClipPos.z,lightClipPos.z,lightClipPos.z,1) * 10;

//    		    float3 worldPos2 = pos * 0.5 + 0.5;
//				return fixed4(worldPos2,1);
//		
//				//get depth
				fixed4 depthRGBA = tex2D(_LightDepthTex,pos.xy);

				float depth = DecodeFloatRGBA(depthRGBA);

				//return fixed4(depth,depth,depth,1) * 10;


				if(lightClipPos.z + 0.005 < depth  )
				{
					return fixed4(1,0,0,1);
				}
				else
				{
					return fixed4(1,1,1,1);
				}
				//return fixed4(depth,depth,depth,1);
			}
			ENDCG
		}
	}

	FallBack "Diffuse"
}
