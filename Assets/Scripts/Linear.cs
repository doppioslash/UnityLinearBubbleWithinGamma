using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(LinearRenderer), PostProcessEvent.AfterStack, "Custom/Linear")]
public sealed class Linear : PostProcessEffectSettings
{
    [Range(0f, 1f), Tooltip("Linear effect intensity")]
    public FloatParameter blend = new FloatParameter {value = 0.5f};
}

public sealed class LinearRenderer : PostProcessEffectRenderer<Linear>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/Linear"));
        sheet.properties.SetFloat("_Blend", settings.blend);
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}