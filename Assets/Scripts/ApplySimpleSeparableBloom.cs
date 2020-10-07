using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class ApplySimpleSeparableBloom : MonoBehaviour
{
    public Shader bloomShader;
    public Material bloom;
    [Range(0, 10)] public float blurSize = 1.0f; 
    
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    { 
        if (bloom == null)
        {
            bloom = new Material(bloomShader);
            bloom.hideFlags = HideFlags.HideAndDontSave;
        }
        int w = src.width / 2;
        int h = src.height / 2;
        var format = src.format;
        
        bloom.SetFloat("_BlurSize", blurSize);
        
        RenderTexture blurHRenderTexture =  RenderTexture.GetTemporary(w,h,0, format);
        Graphics.Blit(src, blurHRenderTexture, bloom, 0);
        RenderTexture blurVRenderTexture =  RenderTexture.GetTemporary(w,h,0, format);
        Graphics.Blit(blurHRenderTexture, blurVRenderTexture, bloom, 1);
        RenderTexture.ReleaseTemporary(blurHRenderTexture);
        
        Graphics.Blit(blurVRenderTexture, dest);
        RenderTexture.ReleaseTemporary(blurVRenderTexture);
        
    }
}
