using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class ApplyBloom : MonoBehaviour
{
    
    public BlurType blurTypeChoice;
    [Space(20)]
    [Range(1, 8)] public int iterations = 1;
    public Shader bloomShader;
    public Material bloom;
    [Range(0, 10)] public float blurSize = 1.0f; 
    [Range(0, 10)] public float threshold = 1;
    public bool debug;
    [Range(0, 1)] public float softThreshold = 0.5f;
    [Range(0, 1)] public float intensity = 1;


    private const int BoxDownPrefilterPass = 0;
    private const int BoxDownPass = 1;
    private const int BoxUpPass = 2;
    private const int ApplyBloomPass = 3;
    private const int DebugBloomPass = 4;
    
    public enum BlurType
    {
        SeparableSimple,
        Box
    }

    private void ApplySeparable(RenderTexture src, RenderTexture dest)
    {
        if (bloom == null || bloom.shader != Shader.Find("Hidden/SimpleSeparableBlur") )
        {
            bloomShader = Shader.Find("Hidden/SimpleSeparableBlur");
            bloom = new Material(bloomShader);
            bloom.hideFlags = HideFlags.HideAndDontSave;
        }
        
        int w = src.width / 2;
        int h = src.height / 2;
        var format = src.format;

        RenderTexture prefiltered = RenderTexture.GetTemporary(w, h, 0, format);

        Graphics.Blit(src, prefiltered, bloom, 0);
        
        bloom.SetFloat("_BlurSize", blurSize);
        
        RenderTexture blurHRenderTexture =  RenderTexture.GetTemporary(w,h,0, format);
        Graphics.Blit(prefiltered, blurHRenderTexture, bloom, 1);
        RenderTexture.ReleaseTemporary(prefiltered);
        
        RenderTexture blurVRenderTexture =  RenderTexture.GetTemporary(w,h,0, format);
        Graphics.Blit(blurHRenderTexture, blurVRenderTexture, bloom, 2);
        RenderTexture.ReleaseTemporary(blurHRenderTexture);
        
        float knee = threshold * softThreshold;
        Vector4 filter;
        filter.x = threshold;
        filter.y = filter.x - knee;
        filter.z = 2f * knee;
        filter.w = 0.25f / (knee + 0.00001f);
        bloom.SetVector("_Filter", filter);
        bloom.SetFloat("_Intensity", Mathf.GammaToLinearSpace(intensity));
        //bloom.SetFloat("_Threshold", threshold);
        bloom.SetTexture("_SrcTex", src);
        
        if (debug)
        {
            Graphics.Blit(blurVRenderTexture, dest, bloom, 3);
        }
        else
        {
            Graphics.Blit(blurVRenderTexture, dest, bloom, 2);
        }
        RenderTexture.ReleaseTemporary(blurVRenderTexture);
        
    }

    private void ApplyBox(RenderTexture src, RenderTexture dest)
    {
        if (bloom == null || bloom.shader != Shader.Find("Hidden/BoxBloom") )
        {
            bloomShader = Shader.Find("Hidden/BoxBloom");
            bloom = new Material(bloomShader);
            bloom.hideFlags = HideFlags.HideAndDontSave;
        }

        RenderTexture[] rtexs = new RenderTexture[iterations];

        int w = src.width / 2;
        int h = src.height / 2;
        var format = src.format;

        RenderTexture currentDest = rtexs[0] = RenderTexture.GetTemporary(w, h, 0, format);

        Graphics.Blit(src, currentDest, bloom, BoxDownPrefilterPass);
        RenderTexture currentSrc = currentDest;

        int i = 1;
        for (; i < iterations; i++)
        {
            w /= 2;
            h /= 2;
            if (h < 2 || w < 2)
                break;
            currentDest = rtexs[i] = RenderTexture.GetTemporary(w, h, 0, format);
            Graphics.Blit(currentSrc, currentDest, bloom, BoxDownPass);
            //RenderTexture.ReleaseTemporary(currentSrc);
            currentSrc = currentDest;
        }

        for (i -= 2; i > 0; i--)
        {
            currentDest = rtexs[i];
            rtexs[i] = null;
            Graphics.Blit(currentSrc, currentDest, bloom, BoxUpPass);
            RenderTexture.ReleaseTemporary(currentSrc);
            currentSrc = currentDest;
        }

        float knee = threshold * softThreshold;
        Vector4 filter;
        filter.x = threshold;
        filter.y = filter.x - knee;
        filter.z = 2f * knee;
        filter.w = 0.25f / (knee + 0.00001f);
        bloom.SetVector("_Filter", filter);
        bloom.SetFloat("_Intensity", Mathf.GammaToLinearSpace(intensity));
        //bloom.SetFloat("_Threshold", threshold);
        bloom.SetTexture("_SrcTex", src);
        //bloom.SetFloat("_SoftThreshold", softThreshold);
        
        if (debug)
        {
            Graphics.Blit(currentSrc, dest, bloom, DebugBloomPass);
        }
        else
        {
            Graphics.Blit(currentSrc, dest, bloom, ApplyBloomPass);
        }
        RenderTexture.ReleaseTemporary(currentSrc);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (blurTypeChoice == BlurType.Box)
        {
            ApplyBox(src, dest);
        } else if (blurTypeChoice == BlurType.SeparableSimple)
        {
            ApplySeparable(src, dest);
        }
        
    }
}
