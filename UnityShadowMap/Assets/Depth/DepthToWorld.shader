Shader "Custom/DepthToWorld"
{
    Properties
    {
		_MainTex ("Base (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            ZTest Always 
            Cull Off 
            ZWrite Off

            CGPROGRAM

//            #pragma vertex far_ray_vert
//            #pragma fragment far_ray_frag


            #pragma vertex near_ray_vert
            #pragma fragment near_ray_frag


//            #pragma vertex near_ray_vert
//            #pragma fragment martrix_frag



            #include "UnityCG.cginc"
			#pragma target 3.0   //SV_POSITION 在3.0下会有错误

            uniform sampler2D_float _CameraDepthTexture;
            uniform half4 _MainTex_TexelSize;
            sampler2D _MainTex;
            float4x4  _Matrix_vp_inverse;
            float4x4  _ClipToWorld;

    		float4x4 _FrustumCornersWS;

            struct uinput
            {
                float4 pos : POSITION;
                half2 uv : TEXCOORD0;
            };

            struct uoutput
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                float4 uv_depth : TEXCOORD1;
        		float4 interpolatedRay : TEXCOORD2;
                float4 cameraToFarPlane : TEXCOORD3;

            };

            fixed4 WorldPosTo01(float3 worldPos)
            {
				float dis = length(worldPos.xyz);
    		    float3 worldPos2 = worldPos.xyz/dis;
    		    worldPos2 = worldPos2 * 0.5 + 0.5;
				return fixed4(worldPos2,1);
            }

            uoutput far_ray_vert(uinput i)
            {
            	uoutput o;
                o.pos = mul(UNITY_MATRIX_MVP, i.pos);
                o.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, i.uv);
                o.uv = i.uv ;
                o.uv_depth.xy = o.uv ;
	        	#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
						o.uv_depth.y = 1 - o.uv_depth.y;
				#endif
	
                // Clip space X and Y coords
                float2 clipXY = o.pos.xy / o.pos.w;
                       
                // Position of the far plane in clip space
                float4 farPlaneClip = float4(clipXY, 1, 1);
                       
                // Homogeneous world position on the far plane
                farPlaneClip *= float4(1,_ProjectionParams.x,1,1);   
                float4 farPlaneWorld4 = mul(_ClipToWorld, farPlaneClip);
                       
                // World position on the far plane  ?????
                float3 farPlaneWorld = farPlaneWorld4.xyz / farPlaneWorld4.w;
                       
                // Vector from the camera to the far plane
                o.cameraToFarPlane.xyz = farPlaneWorld - _WorldSpaceCameraPos;
                
                return o;

			}

            uoutput near_ray_vert(uinput i)
            {
                uoutput o;

                o.pos = mul(UNITY_MATRIX_MVP, i.pos);
                o.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, i.uv);
                o.uv = i.uv ;
                o.uv_depth.xy = o.uv ;
	        	#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
						o.uv_depth.y = 1 - o.uv_depth.y;
				#endif
	
				int index = 0;
				if (i.uv.x < 0.5 && i.uv.y < 0.5) 
				{
					index = 0;
				} 
				else if (i.uv.x > 0.5 && i.uv.y < 0.5) 
				{
					index = 1;
				} 
				else if (i.uv.x > 0.5 && i.uv.y > 0.5) 
				{
					index = 2;
				} 
				else 
				{
					index = 3;
				}

                #if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0)
                    index = 3 - index;
                #endif

				o.interpolatedRay = _FrustumCornersWS[(int)index];

                return o;
            }

            fixed4 near_ray_frag(uoutput o) : COLOR
            {
            	float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, o.uv_depth));
				float3 worldPos = _WorldSpaceCameraPos + linearDepth * o.interpolatedRay.xyz;
				return WorldPosTo01(worldPos);
            }


           fixed4 far_ray_frag(uoutput o) : COLOR
           {
             float linearDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, o.uv_depth));

             float3 worldPos = _WorldSpaceCameraPos + linearDepth * o.cameraToFarPlane;

			return WorldPosTo01(worldPos);
           }


   			//逆矩阵方式
 			fixed4 martrix_frag(uoutput o) : COLOR
            {
           		fixed4 col = tex2D(_MainTex, o.uv);

           		//Depth 
        		float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, o.uv_depth));
  
    		    float4 ndcPos = float4(o.uv.x* 2 - 1  ,o.uv.y * 2 - 1 ,depth , 1);


    		    float4 worldHPos = mul(_Matrix_vp_inverse,ndcPos);
    		    float4 worldPos  = worldHPos / worldHPos.w;

				return WorldPosTo01(worldPos);
            }
          
            ENDCG
        }

	}

	       FallBack off
}