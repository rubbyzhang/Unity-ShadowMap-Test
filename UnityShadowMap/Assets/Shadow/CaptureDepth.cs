using UnityEngine;
using System.Collections;

public class CaptureDepth : MonoBehaviour
{
	public RenderTexture depthTexture;

	private Camera mCam;
	private Shader mSampleDepthShader ;

	void Awake()
	{
		mCam = GetComponent<Camera>();
		mSampleDepthShader = Shader.Find("ShadowMap/CaptureDepth");

		if (mCam != null) 
		{
			mCam.backgroundColor = Color.white;
			mCam.clearFlags = CameraClearFlags.Color; ;
			mCam.targetTexture = depthTexture;
			mCam.enabled = false;

			Shader.SetGlobalTexture ("_LightDepthTex", depthTexture);

			mCam.RenderWithShader(mSampleDepthShader, "RenderType");

			//mCam.SetReplacementShader (mSampleDepthShader, "RenderType");

			Debug.Log ("_____________________________SampleDepthShader");
		}
	}

	void Start()
	{
		if (mCam != null) 
		{
			
		//	mCam.SetReplacementShader (mSampleDepthShader, "RenderType");		
		}
	}
}