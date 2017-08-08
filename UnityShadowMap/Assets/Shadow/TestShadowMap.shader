// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Shadow/TestShdowMap"
{
    Properties
    {
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            uniform sampler2D_float _LightDepthTex;

            struct uinput
            {
                float4 pos : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct uoutput
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
            };

            uoutput vert(uinput i)
            {
                uoutput o;
                o.pos = mul(UNITY_MATRIX_MVP, i.pos);
                o.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, i.uv);
                return o;
            }

            fixed4 frag(uoutput o) : COLOR
            {
            	//return fixed4(1,1,1,1) ;
                float4 depthColor = tex2D(_LightDepthTex, o.uv);

            	//return depthColor;

                float  depth = DecodeFloatRGBA(depthColor) ;
                depth = depth * 0.5f + 0.5f ;
                return fixed4(depth,depth,depth,1);
            }
            ENDCG
        }
	}
}