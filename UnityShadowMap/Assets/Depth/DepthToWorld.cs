using UnityEngine;
using System.Collections;


[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DepthToWorld : MonoBehaviour
{
    private Material mMat;
    private bool mOldUsingDepthNormal = false;
    private Camera mCam;
    private Shader mDepthShader;

    void Awake()
    {
        mCam = GetComponent<Camera>();
        mDepthShader = Shader.Find("Custom/DepthToWorld");
        mCam.depthTextureMode = DepthTextureMode.Depth;
        mMat = new Material(mDepthShader);
    }

	Matrix4x4 GetFrustumCorners()
	{
		Matrix4x4 frustumCorners = Matrix4x4.identity;
		Camera camera = mCam;
		Transform cameraTransform = mCam.gameObject.transform;

		float fov = camera.fieldOfView;
		float near = camera.nearClipPlane;
		float aspect = camera.aspect;

		float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
		Vector3 toRight = cameraTransform.right * halfHeight * aspect;
		Vector3 toTop = cameraTransform.up * halfHeight;

		Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
		float scale = topLeft.magnitude / near;

		topLeft.Normalize();
		topLeft *= scale;

		Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
		topRight.Normalize();
		topRight *= scale;

		Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
		bottomLeft.Normalize();
		bottomLeft *= scale;

		Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
		bottomRight.Normalize();
		bottomRight *= scale;

		frustumCorners.SetRow(0, bottomLeft);
		frustumCorners.SetRow(1, bottomRight);
		frustumCorners.SetRow(2, topRight);
		frustumCorners.SetRow(3, topLeft);

		return frustumCorners;
	}

	
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (null != mMat)
        {
			Matrix4x4 temp = mCam.projectionMatrix * mCam.worldToCameraMatrix;
			temp = temp.inverse;

			mMat.SetMatrix("_Matrix_vp_inverse", temp);
			mMat.SetMatrix("_FrustumCornersWS", GetFrustumCorners());
			mMat.SetMatrix("_ClipToWorld", (mCam.cameraToWorldMatrix * mCam.projectionMatrix).inverse);
            Graphics.Blit(source, destination, mMat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}