﻿#ifndef COLOR_CONVERSIONS
#define COLOR_CONVERSIONS
//Taken from the Pos Processing stack StdLib
// -----------------------------------------------------------------------------
// Constants

#define HALF_MAX        65504.0 // (2 - 2^-10) * 2^15
#define HALF_MAX_MINUS1 65472.0 // (2 - 2^-9) * 2^15
#define EPSILON         1.0e-4
#define PI              3.14159265359
#define TWO_PI          6.28318530718
#define FOUR_PI         12.56637061436
#define INV_PI          0.31830988618
#define INV_TWO_PI      0.15915494309
#define INV_FOUR_PI     0.07957747155
#define HALF_PI         1.57079632679
#define INV_HALF_PI     0.636619772367

#define FLT_EPSILON     1.192092896e-07 // Smallest positive number, such that 1.0 + FLT_EPSILON != 1.0
#define FLT_MIN         1.175494351e-38 // Minimum representable positive floating-point number
#define FLT_MAX         3.402823466e+38 // Maximum representable floating-point number

// -----------------------------------------------------------------------------
// Using pow often result to a warning like this
// "pow(f, e) will not work for negative f, use abs(f) or conditionally handle negative values if you expect them"
// PositivePow remove this warning when you know the value is positive and avoid inf/NAN.
float PositivePow(float base, float power)
{
    return pow(max(abs(base), float(FLT_EPSILON)), power);
}

float2 PositivePow(float2 base, float2 power)
{
    return pow(max(abs(base), float2(FLT_EPSILON, FLT_EPSILON)), power);
}

float3 PositivePow(float3 base, float3 power)
{
    return pow(max(abs(base), float3(FLT_EPSILON, FLT_EPSILON, FLT_EPSILON)), power);
}

float4 PositivePow(float4 base, float4 power)
{
    return pow(max(abs(base), float4(FLT_EPSILON, FLT_EPSILON, FLT_EPSILON, FLT_EPSILON)), power);
}

//
// sRGB transfer functions
// Fast path ref: http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
//

half SRGBToLinear(half c)
{
    #if USE_VERY_FAST_SRGB
    return c * c;
    #elif USE_FAST_SRGB
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
    #else
    half linearRGBLo = c / 12.92;
    half linearRGBHi = PositivePow((c + 0.055) / 1.055, 2.4);
    half linearRGB = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
    return linearRGB;
    #endif
}

half3 SRGBToLinear(half3 c)
{
    #if USE_VERY_FAST_SRGB
    return c * c;
    #elif USE_FAST_SRGB
    return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
    #else
    half3 linearRGBLo = c / 12.92;
    half3 linearRGBHi = PositivePow((c + 0.055) / 1.055, half3(2.4, 2.4, 2.4));
    half3 linearRGB = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
    return linearRGB;
    #endif
}

half4 SRGBToLinear(half4 c)
{
    return half4(SRGBToLinear(c.rgb), c.a);
}

half LinearToSRGB(half c)
{
    #if USE_VERY_FAST_SRGB
    return sqrt(c);
    #elif USE_FAST_SRGB
    return max(1.055 * PositivePow(c, 0.416666667) - 0.055, 0.0);
    #else
    half sRGBLo = c * 12.92;
    half sRGBHi = (PositivePow(c, 1.0 / 2.4) * 1.055) - 0.055;
    half sRGB = (c <= 0.0031308) ? sRGBLo : sRGBHi;
    return sRGB;
    #endif
}

half3 LinearToSRGB(half3 c)
{
    #if USE_VERY_FAST_SRGB
    return sqrt(c);
    #elif USE_FAST_SRGB
    return max(1.055 * PositivePow(c, 0.416666667) - 0.055, 0.0);
    #else
    half3 sRGBLo = c * 12.92;
    half3 sRGBHi = (PositivePow(c, half3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
    half3 sRGB = (c <= 0.0031308) ? sRGBLo : sRGBHi;
    return sRGB;
    #endif
}

half4 LinearToSRGB(half4 c)
{
    return half4(LinearToSRGB(c.rgb), c.a);
}

#endif