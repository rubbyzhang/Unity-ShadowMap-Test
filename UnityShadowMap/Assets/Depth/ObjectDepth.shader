// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/ObjectTestColor"
{
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

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 clippos : TEXCOORD0;  
				float4 worldPos : TEXCOORD1;  
				float4 depth : TEXCOORD2;  
			};
			
			v2f object_vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.clippos = o.vertex ;
				o.depth.x = COMPUTE_DEPTH_01;
				o.worldPos =  mul(UNITY_MATRIX_MV, v.vertex);
				return o;
			}
			
			fixed4 object_frag (v2f i) : SV_Target
			{

			    //return EncodeFloatRGBA(i.clippos.z/i.clippos.w) ;
				//NDC深度
				float3 ndc = i.clippos.xyz / i.clippos.w ;
    		    ndc = ndc * 0.5 + 0.5;
				return fixed4(ndc,1);

//				//View空间深度
//				float viewdDepth = i.depth.x * 10;
//				return fixed4(viewdDepth,viewdDepth,viewdDepth,1)   ;

//				//世界坐标
//				float dis = length(i.worldPos.xyz);
//			    float3 worldPos2 = i.worldPos.xyz/dis;
//    		    worldPos2 = worldPos2 * 0.5 + 0.5;
//				return fixed4(worldPos2,1);
//
//				float z = i.worldPos.z / i.worldPos.w ;
//				float d = -z / 100 ;
//
//				return fixed4(d,d,d,1);

			}
			ENDCG
		}
	}

	FallBack "Diffuse"
}
