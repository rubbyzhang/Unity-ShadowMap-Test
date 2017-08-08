Shader "Custom/CustomDepth" 
{
Properties 
{
   _MainTex ("", 2D) = "white" {}
   _DepthTexture ("_DepthTexture", 2D) = "white" {}
}

SubShader 
{
	Tags { "RenderType"="Opaque" }

	Pass
	{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"

		sampler2D _DepthTexture;


		struct v2f 
		{
		   float4 pos : SV_POSITION;
		   float4 scrPos: TEXCOORD1;
		};

		//Our Vertex Shader
		v2f vert (appdata_base v)
		{
		   v2f o;
		   o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
		   o.scrPos  = ComputeScreenPos(o.pos);
		   o.scrPos.y =  o.scrPos.y;
		   return o;
		}

		sampler2D _MainTex; 

		//Our Fragment Shader
		half4 frag (v2f i) : COLOR
		{

			float3 normalValues;
			float depthValue;

			DecodeDepthNormal(tex2D(_DepthTexture, i.scrPos.xy), depthValue, normalValues);


			depthValue = depthValue * 20.0f ;
			float4 depth = float4(depthValue,depthValue,depthValue,1);
			return depth;
		}

		ENDCG
	}
}
FallBack "Diffuse"
}