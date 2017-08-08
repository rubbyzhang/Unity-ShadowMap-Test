Shader "Custom/CameraDepth"
{
    Properties
    {
        _DepthLevel ("Depth Level", Range(1, 3)) = 2
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            uniform sampler2D_float _CameraDepthTexture;
            uniform fixed _DepthLevel;
            uniform half4 _MainTex_TexelSize;

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
                float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, o.uv));
                depth = Linear01Depth(depth) * 10.0f;
                return fixed4(depth,depth,depth,1);
				
            }
            ENDCG
        }
	}
}