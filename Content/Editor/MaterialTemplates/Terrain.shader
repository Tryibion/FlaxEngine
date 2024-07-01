// File generated by Flax Materials Editor
// Version: @0

#define MATERIAL 1
#define USE_PER_VIEW_CONSTANTS 1
@3
// Enables/disables smooth terrain chunks LOD transitions (with morphing higher LOD near edges to the lower LOD in the neighbour)
#define USE_SMOOTH_LOD_TRANSITION 1

// Switches between using 0, 4 or 8 heightmap layers (values: 0, 1, 2)
#define TERRAIN_LAYERS_DATA_SIZE 2
#define USE_TERRAIN_LAYERS (TERRAIN_LAYERS_DATA_SIZE > 0)

#include "./Flax/Common.hlsl"
#include "./Flax/MaterialCommon.hlsl"
#include "./Flax/GBufferCommon.hlsl"
@7
// Primary constant buffer (with additional material parameters)
META_CB_BEGIN(0, Data)
float4x3 WorldMatrix;
float3 WorldInvScale;
float WorldDeterminantSign;
float PerInstanceRandom;
float CurrentLOD;
float ChunkSizeNextLOD;
float TerrainChunkSizeLOD0;
float4 HeightmapUVScaleBias;
float4 NeighborLOD;
float2 OffsetUV;
float2 Dummy0;
float4 LightmapArea;
@1META_CB_END

// Terrain data
Texture2D Heightmap : register(t0);
Texture2D Splatmap0 : register(t1);
Texture2D Splatmap1 : register(t2);

// Shader resources
@2
// Geometry data passed though the graphics rendering stages up to the pixel shader
struct GeometryData
{
	float3 WorldPosition : TEXCOORD0;
	float2 TexCoord : TEXCOORD1;
	float2 LightmapUV : TEXCOORD2;
	float3 WorldNormal : TEXCOORD3;
	float HolesMask : TEXCOORD4;
#if USE_TERRAIN_LAYERS
	float4 Layers[TERRAIN_LAYERS_DATA_SIZE] : TEXCOORD5;
#endif
};

// Interpolants passed from the vertex shader
struct VertexOutput
{
	float4 Position : SV_Position;
	GeometryData Geometry;
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	float4 CustomVSToPS[CUSTOM_VERTEX_INTERPOLATORS_COUNT] : TEXCOORD9;
#endif
#if USE_TESSELLATION
    float TessellationMultiplier : TESS;
#endif
};

// Interpolants passed to the pixel shader
struct PixelInput
{
	float4 Position : SV_Position;
	GeometryData Geometry;
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	float4 CustomVSToPS[CUSTOM_VERTEX_INTERPOLATORS_COUNT] : TEXCOORD9;
#endif
	bool IsFrontFace : SV_IsFrontFace;
};

// Material properties generation input
struct MaterialInput
{
	float3 WorldPosition;
	float TwoSidedSign;
	float2 TexCoord;
#if USE_LIGHTMAP
	float2 LightmapUV;
#endif
	float3x3 TBN;
	float4 SvPosition;
	float3 PreSkinnedPosition;
	float3 PreSkinnedNormal;
	float HolesMask;
	ObjectData Object;
#if USE_TERRAIN_LAYERS
	float4 Layers[TERRAIN_LAYERS_DATA_SIZE];
#endif
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	float4 CustomVSToPS[CUSTOM_VERTEX_INTERPOLATORS_COUNT];
#endif
};

// Extracts geometry data to the material input
MaterialInput GetGeometryMaterialInput(GeometryData geometry)
{
	MaterialInput output = (MaterialInput)0;
	output.WorldPosition = geometry.WorldPosition;
	output.TexCoord = geometry.TexCoord;
#if USE_LIGHTMAP
	output.LightmapUV = geometry.LightmapUV;
#endif
	output.TBN = CalcTangentBasis(geometry.WorldNormal, geometry.WorldPosition, geometry.TexCoord);
	output.HolesMask = geometry.HolesMask;
#if USE_TERRAIN_LAYERS
	output.Layers = geometry.Layers;
#endif
	return output;
}

#if USE_TESSELLATION

// Interpolates the geometry positions data only (used by the tessallation when generating vertices)
#define InterpolateGeometryPositions(output, p0, w0, p1, w1, p2, w2, offset) output.WorldPosition = p0.WorldPosition * w0 + p1.WorldPosition * w1 + p2.WorldPosition * w2 + offset

// Offsets the geometry positions data only (used by the tessallation when generating vertices)
#define OffsetGeometryPositions(geometry, offset) geometry.WorldPosition += offset

// Applies the Phong tessallation to the geometry positions (used by the tessallation when doing Phong tess)
#define ApplyGeometryPositionsPhongTess(geometry, p0, p1, p2, U, V, W) \
	float3 posProjectedU = TessalationProjectOntoPlane(p0.WorldNormal, p0.WorldPosition, geometry.WorldPosition); \
	float3 posProjectedV = TessalationProjectOntoPlane(p1.WorldNormal, p1.WorldPosition, geometry.WorldPosition); \
	float3 posProjectedW = TessalationProjectOntoPlane(p2.WorldNormal, p2.WorldPosition, geometry.WorldPosition); \
	geometry.WorldPosition = U * posProjectedU + V * posProjectedV + W * posProjectedW

// Interpolates the geometry data except positions (used by the tessallation when generating vertices)
GeometryData InterpolateGeometry(GeometryData p0, float w0, GeometryData p1, float w1, GeometryData p2, float w2)
{
	GeometryData output = (GeometryData)0;
	output.TexCoord = p0.TexCoord * w0 + p1.TexCoord * w1 + p2.TexCoord * w2;
	output.LightmapUV = p0.LightmapUV * w0 + p1.LightmapUV * w1 + p2.LightmapUV * w2;
	output.WorldNormal = p0.WorldNormal * w0 + p1.WorldNormal * w1 + p2.WorldNormal * w2;
	output.WorldNormal = normalize(output.WorldNormal);
	output.HolesMask = p0.HolesMask * w0 + p1.HolesMask * w1 + p2.HolesMask * w2;
#if USE_TERRAIN_LAYERS
	UNROLL
	for (int i = 0; i < TERRAIN_LAYERS_DATA_SIZE; i++)
		output.Layers[i] = p0.Layers[i] * w0 + p1.Layers[i] * w1 + p2.Layers[i] * w2;
#endif
	return output;
}

#endif

ObjectData GetObject()
{
    ObjectData object = (ObjectData)0;
    object.WorldMatrix = ToMatrix4x4(WorldMatrix);
    object.PrevWorldMatrix = object.WorldMatrix;
    object.GeometrySize = float3(1, 1, 1);
    object.PerInstanceRandom = PerInstanceRandom;
    object.WorldDeterminantSign = WorldDeterminantSign;
    object.LODDitherFactor = 0.0f;
    object.LightmapArea = LightmapArea;
    return object;
}

MaterialInput GetMaterialInput(PixelInput input)
{
	MaterialInput output = GetGeometryMaterialInput(input.Geometry);
	output.Object = GetObject();
	output.TwoSidedSign = WorldDeterminantSign * (input.IsFrontFace ? 1.0 : -1.0);
	output.SvPosition = input.Position;
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	output.CustomVSToPS = input.CustomVSToPS;
#endif
	return output;
}

// Removes the scale vector from the local to world transformation matrix
float3x3 RemoveScaleFromLocalToWorld(float3x3 localToWorld)
{
	localToWorld[0] *= WorldInvScale.x;
	localToWorld[1] *= WorldInvScale.y;
	localToWorld[2] *= WorldInvScale.z;
	return localToWorld;
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
	float3x3 localToWorld = (float3x3)ToMatrix4x4(WorldMatrix);
	//localToWorld = RemoveScaleFromLocalToWorld(localToWorld);
	return mul(localVector, localToWorld);
}

// Transforms a vector from local space to world space
float3 TransformWorldVectorToLocal(MaterialInput input, float3 worldVector)
{
	float3x3 localToWorld = (float3x3)ToMatrix4x4(WorldMatrix);
	//localToWorld = RemoveScaleFromLocalToWorld(localToWorld);
	return mul(localToWorld, worldVector);
}

// Gets the current object position
float3 GetObjectPosition(MaterialInput input)
{
	return ToMatrix4x4(WorldMatrix)[3].xyz;
}

// Gets the current object size
float3 GetObjectSize(MaterialInput input)
{
	return float3(1, 1, 1);
}

// Get the current object random value
float GetPerInstanceRandom(MaterialInput input)
{
	return PerInstanceRandom;
}

// Get the current object LOD transition dither factor
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

// Get material properties function (for vertex shader)
Material GetMaterialVS(MaterialInput input)
{
@5
}

// Get material properties function (for domain shader)
Material GetMaterialDS(MaterialInput input)
{
@6
}

// Get material properties function (for pixel shader)
Material GetMaterialPS(MaterialInput input)
{
@4
}

// Calculates LOD value (with fractional part for blending)
float CalcLOD(float2 xy, float4 morph)
{
#if USE_SMOOTH_LOD_TRANSITION
	// Use LOD value based on Barycentric coordinates to morph to the lower LOD near chunk edges
	float4 lodCalculated = morph * CurrentLOD + NeighborLOD * (float4(1, 1, 1, 1) - morph);

	// Pick a quadrant (top, left, right or bottom)
	float lod;
	if ((xy.x + xy.y) > 1)
	{
		if (xy.x < xy.y)
			lod = lodCalculated.w;
		else
			lod = lodCalculated.z;
	}
	else
	{
		if (xy.x < xy.y)
			lod = lodCalculated.y;
		else
			lod = lodCalculated.x;
	}

	return lod;
#else
	return CurrentLOD;
#endif
}

float3x3 CalcTangentToWorld(float4x4 world, float3x3 tangentToLocal)
{
	float3x3 localToWorld = RemoveScaleFromLocalToWorld((float3x3)world);
	return mul(tangentToLocal, localToWorld); 
}

// Must match structure defined in TerrainManager.cpp
struct TerrainVertexInput
{
	float2 TexCoord : TEXCOORD0;
	float4 Morph : TEXCOORD1;
};

// Vertex Shader function for terrain rendering
META_VS(true, FEATURE_LEVEL_ES2)
META_VS_IN_ELEMENT(TEXCOORD, 0, R32G32_FLOAT,   0, ALIGN, PER_VERTEX, 0, true)
META_VS_IN_ELEMENT(TEXCOORD, 1, R8G8B8A8_UNORM, 0, ALIGN, PER_VERTEX, 0, true)
VertexOutput VS(TerrainVertexInput input)
{
	VertexOutput output;

	// Calculate terrain LOD for this chunk
	float lodCalculated = CalcLOD(input.TexCoord, input.Morph);
	float lodValue = CurrentLOD;
	float morphAlpha = lodCalculated - CurrentLOD;

	// Sample heightmap
	float2 heightmapUVs = input.TexCoord * HeightmapUVScaleBias.xy + HeightmapUVScaleBias.zw;
#if USE_SMOOTH_LOD_TRANSITION
	float4 heightmapValueThisLOD = Heightmap.SampleLevel(SamplerPointClamp, heightmapUVs, lodValue);
	float2 nextLODPos = round(input.TexCoord * ChunkSizeNextLOD) / ChunkSizeNextLOD;
	float2 heightmapUVsNextLOD = nextLODPos * HeightmapUVScaleBias.xy + HeightmapUVScaleBias.zw;
	float4 heightmapValueNextLOD = Heightmap.SampleLevel(SamplerPointClamp, heightmapUVsNextLOD, lodValue + 1);
	float4 heightmapValue = lerp(heightmapValueThisLOD, heightmapValueNextLOD, morphAlpha);
	bool isHole = max(heightmapValueThisLOD.b + heightmapValueThisLOD.a, heightmapValueNextLOD.b + heightmapValueNextLOD.a) >= 1.9f;
#if USE_TERRAIN_LAYERS
	float4 splatmapValueThisLOD = Splatmap0.SampleLevel(SamplerPointClamp, heightmapUVs, lodValue);
	float4 splatmapValueNextLOD = Splatmap0.SampleLevel(SamplerPointClamp, heightmapUVsNextLOD, lodValue + 1);
	float4 splatmap0Value = lerp(splatmapValueThisLOD, splatmapValueNextLOD, morphAlpha);
#if TERRAIN_LAYERS_DATA_SIZE > 1
	splatmapValueThisLOD = Splatmap1.SampleLevel(SamplerPointClamp, heightmapUVs, lodValue);
	splatmapValueNextLOD = Splatmap1.SampleLevel(SamplerPointClamp, heightmapUVsNextLOD, lodValue + 1);
	float4 splatmap1Value = lerp(splatmapValueThisLOD, splatmapValueNextLOD, morphAlpha);
#endif
#endif
#else
	float4 heightmapValue = Heightmap.SampleLevel(SamplerPointClamp, heightmapUVs, lodValue);
	bool isHole = (heightmapValue.b + heightmapValue.a) >= 1.9f;
#if USE_TERRAIN_LAYERS
	float4 splatmap0Value = Splatmap0.SampleLevel(SamplerPointClamp, heightmapUVs, lodValue);
#if TERRAIN_LAYERS_DATA_SIZE > 1
	float4 splatmap1Value = Splatmap1.SampleLevel(SamplerPointClamp, heightmapUVs, lodValue);
#endif
#endif
#endif
	float height = (float)((int)(heightmapValue.x * 255.0) + ((int)(heightmapValue.y * 255) << 8)) / 65535.0;

	// Extract normal and the holes mask
	float2 normalTemp = float2(heightmapValue.b, heightmapValue.a) * 2.0f - 1.0f;
	float3 normal = float3(normalTemp.x, sqrt(1.0 - saturate(dot(normalTemp, normalTemp))), normalTemp.y);
	normal = normalize(normal);
	output.Geometry.HolesMask = isHole ? 0 : 1;
	if (isHole)
	{
		normal = float3(0, 1, 0);
	}

	// Construct vertex position
#if USE_SMOOTH_LOD_TRANSITION
	float2 positionXZThisLOD = input.TexCoord * TerrainChunkSizeLOD0;
	float2 positionXZNextLOD = nextLODPos * TerrainChunkSizeLOD0;
	float2 positionXZ = lerp(positionXZThisLOD, positionXZNextLOD, morphAlpha);
#else
	float2 positionXZ = input.TexCoord * TerrainChunkSizeLOD0;
#endif
	float3 position = float3(positionXZ.x, height, positionXZ.y);

	// Compute world space vertex position
	float4x4 worldMatrix = ToMatrix4x4(WorldMatrix);
	output.Geometry.WorldPosition = mul(float4(position, 1), worldMatrix).xyz;

	// Compute clip space position
	output.Position = mul(float4(output.Geometry.WorldPosition, 1), ViewProjectionMatrix);

	// Pass vertex attributes
#if USE_SMOOTH_LOD_TRANSITION
	float2 texCoord = lerp(input.TexCoord, nextLODPos, morphAlpha);
#else
	float2 texCoord = input.TexCoord;
#endif
	output.Geometry.TexCoord = positionXZ * (1.0f / TerrainChunkSizeLOD0) + OffsetUV;
	output.Geometry.LightmapUV = texCoord * LightmapArea.zw + LightmapArea.xy;

	// Extract terrain layers weights from the splatmap
#if USE_TERRAIN_LAYERS
	output.Geometry.Layers[0] = splatmap0Value;
#if TERRAIN_LAYERS_DATA_SIZE > 1
	output.Geometry.Layers[1] = splatmap1Value;
#endif
#endif

	// Compute world space normal vector
	float3x3 tangentToLocal = CalcTangentBasisFromWorldNormal(normal);
	float3x3 tangentToWorld = CalcTangentToWorld(worldMatrix, tangentToLocal);
	output.Geometry.WorldNormal = tangentToWorld[2];

	// Get material input params if need to evaluate any material property
#if USE_POSITION_OFFSET || USE_TESSELLATION || USE_CUSTOM_VERTEX_INTERPOLATORS
	MaterialInput materialInput = (MaterialInput)0;
	materialInput.Object = GetObject();
	materialInput.WorldPosition = output.Geometry.WorldPosition;
	materialInput.TexCoord = output.Geometry.TexCoord;
#if USE_LIGHTMAP
	materialInput.LightmapUV = output.Geometry.LightmapUV;
#endif
	materialInput.TBN = tangentToWorld;
	materialInput.TwoSidedSign = WorldDeterminantSign;
	materialInput.SvPosition = output.Position;
	materialInput.PreSkinnedPosition = position;
	materialInput.PreSkinnedNormal = normal;
	materialInput.HolesMask = output.Geometry.HolesMask;
#if USE_TERRAIN_LAYERS
	materialInput.Layers = output.Geometry.Layers;
#endif
	Material material = GetMaterialVS(materialInput);
#endif

	// Apply world position offset per-vertex
#if USE_POSITION_OFFSET
	output.Geometry.WorldPosition += material.PositionOffset;
	output.Position = mul(float4(output.Geometry.WorldPosition, 1), ViewProjectionMatrix);
#endif

	// Get tessalation multiplier (per vertex)
#if USE_TESSELLATION
    output.TessellationMultiplier = material.TessellationMultiplier;
#endif

	// Copy interpolants for other shader stages
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	output.CustomVSToPS = material.CustomVSToPS;
#endif

	return output;
}

// Pixel Shader function for Depth Pass
META_PS(true, FEATURE_LEVEL_ES2)
void PS_Depth(PixelInput input)
{
#if MATERIAL_MASKED
	// Perform per pixel clipping if material requries it
	MaterialInput materialInput = GetMaterialInput(input);
	Material material = GetMaterialPS(materialInput);
	clip(material.Mask - MATERIAL_MASK_THRESHOLD);
#endif
}

#if _PS_QuadOverdraw

#include "./Flax/Editor/QuadOverdraw.hlsl"

// Pixel Shader function for Quad Overdraw Pass (editor-only)
[earlydepthstencil]
META_PS(USE_EDITOR, FEATURE_LEVEL_SM5)
void PS_QuadOverdraw(float4 svPos : SV_Position, uint primId : SV_PrimitiveID)
{
	DoQuadOverdraw(svPos, primId);
}

#endif

@9
