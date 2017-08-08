using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class CameraDepth : MonoBehaviour
{

    public bool UsingDepthNormal = false;

    private Material mMat;
    private bool mOldUsingDepthNormal = false;
    private Camera mCam;
    private Shader mDepthShader;
    private Shader mDepthNormalShader;
    private Shader mCustomDepth;

    void Awake()
    {
        mCam = GetComponent<Camera>();
        mDepthNormalShader = Shader.Find("Custom/CameraDepthNormals");
		mDepthShader = Shader.Find("ShadowMap/CaptureDepth");

        ResetCamera();
    }

    void ResetCamera()
    {
        if (mCam == null || mDepthNormalShader == null || mDepthShader == null)
        {
            Debug.LogError("res is miss");
            return;
        }


        if (UsingDepthNormal)
        {
          //  mCam.depthTextureMode = DepthTextureMode.DepthNormals;
            mMat = new Material(mDepthNormalShader);
        }
        else
        {
            //mCam.depthTextureMode = DepthTextureMode.Depth;
            mMat = new Material(mDepthShader);
        }

        mOldUsingDepthNormal = UsingDepthNormal;
    }

    private RenderTexture depthTexture;


    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (mOldUsingDepthNormal != UsingDepthNormal)
        {
            ResetCamera();
        }

        if (null != mMat)
        {
            Graphics.Blit(source, destination, mMat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}