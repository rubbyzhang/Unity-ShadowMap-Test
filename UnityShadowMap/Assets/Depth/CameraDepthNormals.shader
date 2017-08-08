Shader "Custom/CameraDepthNormals" 
{
Properties 
{
   _MainTex ("", 2D) = "white" {}
   _HighlightDirection ("Highlight Direction", Vector) = (1, 0,0)
}

SubShader 
{
	//Tags { "RenderType"="Opaque" }

	Pass
	{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"

		sampler2D _CameraDepthNormalsTexture;
		float _StartingTime;
		float _showNormalColors = 0; //when this is 1, show normal values as colors. when 0, show depth values as colors.

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
		float4 _HighlightDirection;

		//Our Fragment Shader
		half4 frag (v2f i) : COLOR
		{

			float3 normalValues;
			float depthValue;

			DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.scrPos.xy), depthValue, normalValues);
			depthValue = depthValue * 20.0f ;
			if (_showNormalColors == 1)
			{
				float4 normalColor = float4(normalValues, 1);
				return normalColor;
			} 
			else 
			{
				float4 depth = float4(depthValue,depthValue,depthValue,1);
				return depth;
			}
		}

		ENDCG
	}
}
FallBack "Diffuse"
}