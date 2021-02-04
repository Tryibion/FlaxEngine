// File generated by Flax Materials Editor
// Version: @0

#define MATERIAL 1
@3

#include "./Flax/Common.hlsl"
#include "./Flax/MaterialCommon.hlsl"
#include "./Flax/GBufferCommon.hlsl"
@7
// Primary constant buffer (with additional material parameters)
META_CB_BEGIN(0, Data)
float4x4 ViewMatrix;
float3 ViewPos;
float ViewFar;
float3 ViewDir;
float TimeParam;
float4 ViewInfo;
float4 ScreenSize;
float4 TemporalAAJitter;
@1META_CB_END

// Material shader resources
@2
// Interpolants passed to the pixel shader
struct PixelInput
{
	float4 Position      : SV_Position;
	float3 WorldPosition : TEXCOORD0;
	float2 TexCoord      : TEXCOORD1;
	bool IsFrontFace     : SV_IsFrontFace;
};

// Material properties generation input
struct MaterialInput
{
	float3 WorldPosition;
	float TwoSidedSign;
	float2 TexCoord;
#if USE_VERTEX_COLOR
	half4 VertexColor;
#endif
	float3x3 TBN;
	float4 SvPosition;
	float3 PreSkinnedPosition;
	float3 PreSkinnedNormal;
};

MaterialInput GetMaterialInput(PixelInput input)
{
	MaterialInput result = (MaterialInput)0;
	result.WorldPosition = input.WorldPosition;
	result.TexCoord = input.TexCoord;
#if USE_VERTEX_COLOR
	result.VertexColor = float4(0, 0, 0, 1);
#endif
	result.TBN[0] = float3(1, 0, 0);
	result.TBN[1] = float3(0, 1, 0);
	result.TBN[2] = float3(0, 0, 1);
	result.TwoSidedSign = input.IsFrontFace ? 1.0 : -1.0;
	result.SvPosition = input.Position;
	return result;
}

// Transforms a vector from tangent space to world space
float3 TransformTangentVectorToWorld(MaterialInput input, float3 tangentVector)
{
	return mul(tangentVector, input.TBN);
}

// Transforms a vector from world space to tangent space
float3 TransformWorldVectorToTangent(MaterialInput input, float3 worldVector)
{
	return mul(input.TBN, worldVector);
}

// Transforms a vector from world space to view space
float3 TransformWorldVectorToView(MaterialInput input, float3 worldVector)
{
	return mul(worldVector, (float3x3)ViewMatrix);
}

// Transforms a vector from view space to world space
float3 TransformViewVectorToWorld(MaterialInput input, float3 viewVector)
{
	return mul((float3x3)ViewMatrix, viewVector);
}

// Transforms a vector from local space to world space
float3 TransformLocalVectorToWorld(MaterialInput input, float3 localVector)
{
	return localVector;
}

// Transforms a vector from local space to world space
float3 TransformWorldVectorToLocal(MaterialInput input, float3 worldVector)
{
	return worldVector;
}

// Gets the current object position (supports instancing)
float3 GetObjectPosition(MaterialInput input)
{
	return float3(0, 0, 0);
}

// Gets the current object size
float3 GetObjectSize(MaterialInput input)
{
	return float3(1, 1, 1);
}

// Get the current object random value supports instancing)
float GetPerInstanceRandom(MaterialInput input)
{
	return 0;
}

// Get the current object LOD transition dither factor (supports instancing)
float GetLODDitherFactor(MaterialInput input)
{
	return 0;
}

// Gets the interpolated vertex color (in linear space)
float4 GetVertexColor(MaterialInput input)
{
	return 1;
}

@8

// Get material properties function (for pixel shader)
Material GetMaterialPS(MaterialInput input)
{
@4
}

// Fix line for errors/warnings for shader code from template
#line 1000

// Pixel Shader function for PostFx materials rendering
META_PS(true, FEATURE_LEVEL_ES2)
float4 PS_PostFx(PixelInput input) : SV_Target0
{
	// Get material parameters
	MaterialInput materialInput = GetMaterialInput(input);
	Material material = GetMaterialPS(materialInput);

	return float4(material.Emissive, material.Opacity);
}

@9
