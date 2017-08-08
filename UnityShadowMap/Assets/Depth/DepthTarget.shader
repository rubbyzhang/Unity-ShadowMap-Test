Shader "Custom/DepthtTarget"
{
	Properties
	{
		_Color ("Color", Color) = (0,0,0,0)
	}
	SubShader
	{
		Tags 
		{
			 "RenderType"="Transparent"  
			 "Queue"="AlphaTest"
		}
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color ;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = fixed4(1,1,1,0) ;
				col = _Color ;
				col.a = 0.5f ;
				return col;
			}
			ENDCG
		}


		//Pass 
		//{  
		//	Tags { "LightMode"="ShadowCaster" }  

		//	CGPROGRAM  
		//	#pragma vertex vert  
		//	#pragma fragment frag  
		//	#pragma multi_compile_shadowcaster  
		//	#include "UnityCG.cginc"  
		
		//	sampler2D _Shadow;  
  
		//	struct v2f_shadow
		//	{  
		//		V2F_SHADOW_CASTER; 
		//	};  

		//	v2f_shadow vert(appdata_base v)
		//	{  
		//		v2f_shadow o;  
		//		TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);  
		//		return o;  
		//	}  
  
		//	float4 frag( v2f_shadow i ) : SV_Target  
		//	{  
		//		SHADOW_CASTER_FRAGMENT(i)  
		//	}  
		//	ENDCG  
		//}

	}

	FallBack "Diffuse"
}
