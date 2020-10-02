﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class ApplyPostProcess : MonoBehaviour
{
	
    /// <summary>
    /// The shader that's going to be applied to the screen
    /// </summary>
    #region variables
    private Shader 			curShader;
    /// <summary>
    /// The material will be generated by the script
    /// </summary>
    private Material 		curMaterial;
    #endregion
	
    #region Properties
    Material material
    {
        get
        {
            if (curMaterial == null){
                curMaterial = new Material(curShader);
                curMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return curMaterial;
        }
    }
    #endregion
	
    public void CopyFrom(ApplyPostProcess instance){
        curShader = instance.curShader;
    }

    void Start ()
    {
        curShader = Shader.Find("Hidden/ImageEffectToGamma");
        if (!curShader && !curShader.isSupported){
            enabled = false;
            Debug.Log("not supported");
        }
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.None;
    }
	
    void OnRenderImage(RenderTexture sourceTexture, RenderTexture destTexture){
        if (curShader != null){
            Graphics.Blit(sourceTexture, destTexture, material);
        }
    }
	
    /// <summary>
    /// The material will be destroyed when the object to which the script is attached is deactivated
    /// </summary>
    void OnDisable(){
		
        if(curMaterial){
            DestroyImmediate(curMaterial);
        }
    }

}