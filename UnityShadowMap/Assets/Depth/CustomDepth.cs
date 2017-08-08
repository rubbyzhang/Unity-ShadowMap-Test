using UnityEngine;
using System.Collections;

[RequireComponent(typeof (Camera))]
public class CustomDepth : MonoBehaviour
{
    public GameObject depthCamObj;

    private Camera mCam;
    private Shader mCustomDepth;
    private Material mMat;
    private RenderTexture depthTexture;

    private Shader mCopyShader ;
    void Awake()
    {
        mCam = GetComponent<Camera>();

        mCustomDepth = Shader.Find("Custom/CustomDepth");
        mCopyShader = Shader.Find("Custom/CopyDepth");
        mMat = new Material(mCustomDepth);


       // mCam.SetReplacementShader(Shader.Find("Custom/CopyDepth"), "RenderType");
    }

    internal void OnPreRender()
    {
        if (depthTexture)
        {
            RenderTexture.ReleaseTemporary(depthTexture);
            depthTexture = null;
        }

        Camera depthCam;
        if (depthCamObj == null)
        {
            depthCamObj = new GameObject("DepthCamera");
            depthCamObj.AddComponent<Camera>();
            depthCam = depthCamObj.GetComponent<Camera>();
            depthCam.enabled = false;
           // depthCamObj.hideFlags = HideFlags.HideAndDontSave;
        }
        else
        {
            depthCam = depthCamObj.GetComponent<Camera>();
        }

        depthCam.CopyFrom(mCam);
        depthTexture = RenderTexture.GetTemporary(mCam.pixelWidth, mCam.pixelHeight, 16, RenderTextureFormat.ARGB32);
        depthCam.backgroundColor = new Color(0, 0, 0, 0);
        depthCam.clearFlags = CameraClearFlags.SolidColor; ;
        depthCam.targetTexture = depthTexture;
        depthCam.RenderWithShader(mCopyShader, "RenderType");
        mMat.SetTexture("_DepthTexture", depthTexture);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
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