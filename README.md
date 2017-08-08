## Unity基础6  Shadow Map 阴影实现

@(Unity)


这篇实现来的有点墨迹，前前后后折腾零碎的时间折腾了半个月才才实现一个基本的shadow map流程，只能说是对原理理解更深刻一些，但离实际应用估计还需要做很多优化。这篇文章大致分析下shadow map的基本原理、Unity中实现ShadowMap阴影方式以及一些有用的参考。

###1 .  Shadow Map 基本原理

基本的shadow Map 原理， 参考 ["Unity基础(5) Shadow Map 概述"](http://www.cnblogs.com/zsb517/p/6696652.html). 其基本步骤如下：
* 从光源的视角渲染整个场景，获得Shadow Map
* 实际相机渲染物体，将物体从世界坐标转换到光源视角下，与深度纹理对比数据获得阴影信息
* 根据阴影信息渲染场景以及阴影
![](http://ohzzlljrf.bkt.clouddn.com/blog/20170411/010742236.png)

### 2. 采集 Shadow Map 纹理

Unity 获取深度纹理的方式可以参考之前的日记：[Unity Shader 基础（3） 获取深度纹理](http://www.cnblogs.com/zsb517/p/6655546.html)  ,   笔记中给出了三种获取Unity深度纹理的方式。 如果采用自定义的方式来获取深度，可以考虑使用EncodeFloatRGBA对深度进行编码。另外，可以通过增加多个subshader实现对不同RenderType 阴影的支持。
```
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 depth: TEXCOORD0;
			};
		
			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.depth = o.vertex.zw ;
				return o;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				float depth = i.depth.x/i.depth.y ;
				return EncodeFloatRGBA(depth) ;
			}
			ENDCG
		}
	}
```


### 3 创建ShadowMap相机

**1.  类型**
shadow Map的相机会根据光源的不同有所差异，直线光使用平行投影比较合适，点光源和聚光灯带有位置信息，适合使用透视投影， 这篇文章以平行光和平行投影为例来实现。对于平行投影相机而言，主要关于方向、近平面、远平面、视场大小。

**1.  创建**

 以光源为父节点创建相机，设置投影方式以及	RenderTexture对象。其方向与父节点保持一致。
 
**2. 视场匹配**

阴影实现中shadow map占用的空间是最大的，合适的相机视场设置可以在同样资源下获得更好的效果、更高的精度。在[Common Techniques to Improve Shadow Depth Maps](https://msdn.microsoft.com/en-us/library/windows/desktop/ee416324%28v=vs.85%29.aspx)一文中给出相机参数适应场景的两种方式：FIt to scene和  FIt to view.  对于Fit to Scene，其实现流程：
* 利用场景中所有物体mesh的bounds计算整个场景的包围盒AABB，需要注意的是mesh.bounds是相对于模型空间，需转换到世界空间再计算整个场景AABB
* 将包围盒转换到光源空间，这里可以利用transparent.worldToLocalMatrixhguod获得转换矩阵
* 相机参数设置：
	* 取包围盒x、y方向最大、最小值，其差值的一半作为相机size；
	* 包围盒中点作为相机位置
	* 相机方向与光源方向相同
	* 近平面和远平面使用包围盒Z方向最大值、最小值

Fit to Scene方式计算整个场景的AABB来摄像 Shadow Map采集相机参数，但如果场景相机视场比较小的情况下，比如FPS游戏中角色，这种方式就不是很合适。对于这种情况，Fit to VIEW 更合适。

### 4 世界坐标转换到Shadow  Map 相机NDC空间
判断是否为阴影需要比较场景中物体深度与Shadow Map中深度值，这个过程需要确保二者在一个空间中。深度采集保存在shadow map贴图中的数值是NDC空间数值，所以渲染物体时会将物体从世界坐标转换到Shadow Map相机空间下，然后通过投影计算转换到NDC坐标，也就是原理图中的$z_b$ 。投影矩阵参数可以传递到shader'中进行，如下：
```
	//perspective matrix
	void  GetLightProjectMatrix(Camera camera)
	{
		Matrix4x4 worldToView = camera.worldToCameraMatrix;
		Matrix4x4 projection  = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
		Matrix4x4 lightProjecionMatrix =  projection * worldToView;
		Shader.SetGlobalMatrix ("_LightProjection", lightProjecionMatrix);
	}
```
pixel shadow 中 计算NDC坐标：
```
fixed4 object_frag (v2f i) : SV_Target
{
	//计算NDC坐标
	fixed4 ndcpos = mul(_LightProjection , i.worldPos);
	ndcpos.xyz = ndcpos.xyz / ndcpos.w ;
	//从[-1,1]转换到[0,1]
	float3 uvpos = ndcpos * 0.5 + 0.5 ;
	...
	...
}
```
###5.  阴影计算
通过比较场景物体转换到shadow map相机NDC空间深度$z_b$与shadow map贴图中深度值$z_a$即可判断顶点是否在阴影区域。以原理图为例，如果 $z_b$大于$z_a$, 顶点是在遮挡物体之后，处于阴影区域。需要注意的是对shadow map 纹理采样坐标需要将场景物体顶点在shadow map相机NDC空间下的坐标转换到[0,1]的范围。下面的代码没有结合光照：
```
fixed4 object_frag (v2f i) : SV_Target
{
	//计算NDC坐标
	fixed4 ndcpos = mul(_LightProjection , i.worldPos);
	ndcpos.xyz = ndcpos.xyz / ndcpos.w ;
	//从[-1,1]转换到[0,1]
	float3 uvpos = ndcpos * 0.5 + 0.5 ;
	float depth = DecodeFloatRGBA(tex2D(_LightDepthTex, uvpos.xy));
	if(ndcpos.z < depth  ){return 1;}
	else{return 0;}
}
```

###6. Shadow acne 与 Peter Panning
![|](http://ohzzlljrf.bkt.clouddn.com/blog/20170506/152043207.png)

深度纹理分辨率的关系，会存在场景中多个顶点对深度纹理同一个点进行采样来判断是否为处于阴影的情况，再加上不同计算方式的精度问题就会产生图上**Shadow acne**的情况，具体可以参考:https://www.zhihu.com/question/49090321 ,描述的比较详细。
![](http://ohzzlljrf.bkt.clouddn.com/blog/20170411/121210240.png)

####5.1 shadow bias
最简单的做法是对场景深度或者贴图深度做稍微的调整，也就是 **shadow bias**,
![](http://ohzzlljrf.bkt.clouddn.com/blog/20170411/121153952.png)
shadow bias的做法简单粗暴，如果偏移过大就会出现 **Peter Panning**的情况，造成阴影和物体分割开的情况。
![mark](http://ohzzlljrf.bkt.clouddn.com/blog/20170506/154035582.png)

####5.2 Slope-Scale Depth Bias
更好的纠正做法是基于物体与光照方向的夹角，也就是**Slope-Scale Depth Bias**，这种方式的提出主要是基于物体表面和光照的夹角越大， [Perspective Aliasing](http://www.cnblogs.com/zsb517/p/6696652.html)的情况越严重，也就越容易出现Shadow Acne，如下图所以。如果采用统一的shadow bais就会出现物体表面一部分区域存再Peter Panning 一部分区域还存在shadow acne。
![mark](http://ohzzlljrf.bkt.clouddn.com/blog/20170425/101506223.png)
更好的办法是根据这个slope进行计算bias，其计算公式如下，$miniBais + maxBais * SlopeScale$ ,  其中$SlopeScale$可以理解为光线方向与表面法线方向夹角的tan值（也即是水平方向为1的情况下，不同角度对应的矫正量）。
```
float GetShadowBias(float3 lightDir , float3 normal , float maxBias , float baseBias)
{
	 float cos_val = saturate(dot(lightDir, normal));
 			 float sin_val = sqrt(1 - cos_val*cos_val); // sin(acos(L·N))
 			 float tan_val = sin_val / cos_val;    // tan(acos(L·N))

 			 float bias = baseBias + clamp(tan_val,0 , maxBias) ;

 			 return bias ;
}
```
不过Bias数值是个有点感性的数据，[也可以采用其他方式，只要考虑到这个slopescale就行](http://www.sunandblackcat.com/tipFullView.php?l=eng&topicid=35)，比如：
```
// dot product returns cosine between N and L in [-1, 1] range
// then map the value to [0, 1], invert and use as offset
float offsetMod = 1.0 - clamp(dot(N, L), 0, 1)
float offset = minOffset + maxSlopeOffset * offsetMod;

// another method to calculate offset
// gives very large offset for surfaces parallel to light rays
float offsetMod2 = tan(acos(dot(N, L)))
float offset2 = minOffset + clamp(offsetMod2, 0, maxSlopeOffset);
```
###7. Shadow Map Aliasing
![mark](http://ohzzlljrf.bkt.clouddn.com/blog/20170506/162303522.png)
解决完shadow acne后，放大阴影边缘就会看到这种锯齿现象，其主要原因还在于shadow map的分辨率。物体多个点会采集深度纹理同一个点进行阴影计算。这个问题一般可以通过滤波紧进行处理，比如多重采样。

**Pencentage close Filtering（PCF）**,最简单的一种处理方式，当前点是否为阴影区域需要考虑周围顶点的情况，处理中需要对当前点周围几个像素进行采集，而且这个采集单位越大PCF的效果会越好，当然性能也越差。现在的GPU一般支持2*2的PCF滤波, 也就是Unity设置中的Hard Shadow 。
```
//PCF滤波
float PercentCloaerFilter(float2 xy , float sceneDepth , float bias)
{
	float shadow = 0.0;
	float2 texelSize = float2(_TexturePixelWidth,_TexturePixelHeight);
	texelSize = 1 / texelSize;

	for(int x = -_FilterSize; x <= _FilterSize; ++x)
	{
	    for(int y = -_FilterSize; y <= _FilterSize; ++y)
	    {
	    	
	    	float2 uv_offset = float2(x ,  y) * texelSize;
	    	float depth = DecodeFloatRGBA(tex2D(_LightDepthTex, xy + uv_offset));
	        shadow += (sceneDepth - bias > depth ? 1.0 : 0.0);   
	             
	    }    
	}
	float total = (_FilterSize * 2 + 1) * (_FilterSize * 2 + 1);
	shadow /= total;

	return shadow;
}
```
![mark](http://ohzzlljrf.bkt.clouddn.com/blog/20170506/163151496.png)

**改进算法**
[Shadow Map Antialiasing](http://http.developer.nvidia.com/GPUGems/gpugems_ch11.html)  对PCF做了一些改进，可以更快的执行。[Improvements for shadow mapping in OpenGL and GLSL][] 结合PCF和泊松滤波处理，使用PCF相对少的采样数，就可以获得很好的效果[OpenGl Tutorial 16 : Shadow mapping][]也采用了类似的方式。类似的算法还有很多，不一一列举。


###7 其他
#### 7.1  Perspective Aliasing
pixels close to the near plane are closer together and require a higher shadow map resolution. Perspective shadow maps (PSMs) and light space perspective shadow maps (LSPSMs) attempt to address perspective aliasing by skewing the light's projection matrix in order to place more texels near the eye where they are needed. Cascaded shadow maps (CSMs) are the most popular technique for dealing with perspective aliasing. 
![mark](http://ohzzlljrf.bkt.clouddn.com/blog/20170506/165609393.png)
参考：[Cascaded Shadow Maps][] , 具体实现可以参考：http://blog.csdn.net/ronintao/article/details/51649664

#### 7.2 [Screem space shadow map][]
Unity 5.4版本之后阴影的基本原理类似，但是处理方式有点差异，具体可以查看：  [Screem space shadow map][]

###8 总结
阴影的处理有很多方式，有本专著《实时阴影技术》对阴影处理做了很多介绍，翻了下果断放弃了，总是获得一个效果好、性能好的阴影效果还是需要费点时间。


工程下载：https://git.oschina.net/rubbyzhang/UnityShader

挺赞的一篇文章：
 [Unity移动端动态阴影总结][]
 [Unity Shadow Map实现](http://blog.csdn.net/ronintao/article/details/51649664)
   
### 参考
[Unity基础(5) Shadow Map 概述](http://www.cnblogs.com/zsb517/p/6696652.html)
[OpenGL Shadow Mapping][]
[OpenGl Tutorial 16 : Shadow mapping][]
[Shadow Map Wiki][]
[Shadow Acne知乎][]
[Common Techniques to Improve Shadow Depth Maps][]
[Cascaded Shadow Maps][]
[Percentage Closer Filtering][]
[Variance Shadow Map Papper][]
[Shadow Mapping Summary][]
[Improvements for shadow mapping in OpenGL and GLSL][]
 [Screem space shadow map][]
  [Unity移动端动态阴影总结][]
 




 [Unity移动端动态阴影总结]:https://zhuanlan.zhihu.com/p/26662359
[Shadow Mapping Summary]: http://the-witness.net/news/2013/09/shadow-mapping-summary-part-1/
[Improvements for shadow mapping in OpenGL and GLSL]:http://www.sunandblackcat.com/tipFullView.php?l=eng&topicid=35
[平行投影和透视投影]:https://docs.unity3d.com/ScriptReference/Camera-projectionMatrix.html
[Variance Shadow Map Papper]:https://graphics.stanford.edu/~mdfisher/Shadows.html
 [Screem space shadow map]: https://github.com/candycat1992/Unity_Shaders_Book/issues/49)

[OpenGL Shadow Mapping]:   https://learnopengl.com/#!Advanced-Lighting/Shadows/Shadow-Mapping 
[OpenGl Tutorial 16 : Shadow mapping]:   http://www.opengl-tutorial.org/cn/intermediate-tutorials/tutorial-16-shadow-mapping/    
[Shadow Map Wiki]: https://en.wikipedia.org/wiki/Shadow_mapping 
[Shadow Acne知乎]: https://www.zhihu.com/question/49090321
[Percentage Closer Filtering]: http://http.developer.nvidia.com/GPUGems/gpugems_ch11.html
[Common Techniques to Improve Shadow Depth Maps]: https://msdn.microsoft.com/en-us/library/windows/desktop/ee416324(v=vs.85).aspx
[Shadow Mapping 的原理与实践]: http://blog.csdn.net/xiaoge132/article/details/51458489
[Shadow Volume Wiki]: https://en.wikipedia.org/wiki/Shadow_volume
[Cascaded Shadow Maps]: https://msdn.microsoft.com/en-us/library/windows/desktop/ee416307%28v=vs.85%29.aspx


