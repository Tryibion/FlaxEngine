// File generated by Flax Materials Editor
// Version: @0

#define MATERIAL 1
#define MAX_LOCAL_LIGHTS 4
@3

#include "./Flax/Common.hlsl"
#include "./Flax/MaterialCommon.hlsl"
#include "./Flax/GBufferCommon.hlsl"
#include "./Flax/LightingCommon.hlsl"
#if USE_REFLECTIONS
#include "./Flax/ReflectionsCommon.hlsl"
#endif
#include "./Flax/Lighting.hlsl"
#include "./Flax/ShadowsSampling.hlsl"
#include "./Flax/ExponentialHeightFog.hlsl"
#include "./Flax/Matrix.hlsl"
@7
struct SpriteInput
{
	float2 Position : POSITION;
	float2 TexCoord : TEXCOORD;
};

// Primary constant buffer (with additional material parameters)
META_CB_BEGIN(0, Data)
float4x4 ViewProjectionMatrix;
float4x4 WorldMatrix;
float4x4 ViewMatrix;
float3 ViewPos;
float ViewFar;
float3 ViewDir;
float TimeParam;
float4 ViewInfo;
float4 ScreenSize;
uint SortedIndicesOffset;
float PerInstanceRandom;
int ParticleStride;
int PositionOffset;
int SpriteSizeOffset;
int SpriteFacingModeOffset;
int SpriteFacingVectorOffset;
int VelocityOffset;
int RotationOffset;
int ScaleOffset;
int ModelFacingModeOffset;
float RibbonUVTilingDistance;
float2 RibbonUVScale;
float2 RibbonUVOffset;
int RibbonWidthOffset;
int RibbonTwistOffset;
int RibbonFacingVectorOffset;
uint RibbonSegmentCount;
float4x4 WorldMatrixInverseTransposed;
@1META_CB_END

// Secondary constantant buffer (for lighting)
META_CB_BEGIN(1, LightingData)
LightData DirectionalLight;
LightShadowData DirectionalLightShadow;
LightData SkyLight;
ProbeData EnvironmentProbe;
ExponentialHeightFogData ExponentialHeightFog;
float3 Dummy1;
uint LocalLightsCount;
LightData LocalLights[MAX_LOCAL_LIGHTS];
META_CB_END

DECLARE_LIGHTSHADOWDATA_ACCESS(DirectionalLightShadow);

// Particles attributes buffer
ByteAddressBuffer ParticlesData : register(t0);

// Ribbons don't use sorted indices so overlap the segment distances buffer on the slot
#define HAS_SORTED_INDICES (!defined(_VS_Ribbon))

#if HAS_SORTED_INDICES

// Sorted particles indices
Buffer<uint> SortedIndices : register(t1);

#else

// Ribbon particles segments distances buffer
Buffer<float> SegmentDistances : register(t1);

#endif

// Shader resources
TextureCube EnvProbe : register(t2);
TextureCube SkyLightTexture : register(t3);
Texture2DArray DirectionalLightShadowMap : register(t4);
@2

// Interpolants passed from the vertex shader
struct VertexOutput
{
	float4 Position          : SV_Position;
	float3 WorldPosition     : TEXCOORD0;
	float2 TexCoord          : TEXCOORD1;
	uint ParticleIndex       : TEXCOORD2;
#if USE_VERTEX_COLOR
	half4 VertexColor        : COLOR;
#endif
	float3x3 TBN             : TEXCOORD3;
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	float4 CustomVSToPS[CUSTOM_VERTEX_INTERPOLATORS_COUNT] : TEXCOORD9;
#endif
	float3 InstanceOrigin    : TEXCOORD6;
	float InstanceParams     : TEXCOORD7; // x-PerInstanceRandom
};

// Interpolants passed to the pixel shader
struct PixelInput
{
	float4 Position          : SV_Position;
	float3 WorldPosition     : TEXCOORD0;
	float2 TexCoord          : TEXCOORD1;
	uint ParticleIndex       : TEXCOORD2;
#if USE_VERTEX_COLOR
	half4 VertexColor        : COLOR;
#endif
	float3x3 TBN             : TEXCOORD3;
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	float4 CustomVSToPS[CUSTOM_VERTEX_INTERPOLATORS_COUNT] : TEXCOORD9;
#endif
	float3 InstanceOrigin    : TEXCOORD6;
	float InstanceParams     : TEXCOORD7; // x-PerInstanceRandom
	bool IsFrontFace         : SV_IsFrontFace;
};

// Material properties generation input
struct MaterialInput
{
	float3 WorldPosition;
	float TwoSidedSign;
	float2 TexCoord;
	uint ParticleIndex;
#if USE_VERTEX_COLOR
	half4 VertexColor;
#endif
	float3x3 TBN;
	float4 SvPosition;
	float3 PreSkinnedPosition;
	float3 PreSkinnedNormal;
	float3 InstanceOrigin;
	float InstanceParams;
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	float4 CustomVSToPS[CUSTOM_VERTEX_INTERPOLATORS_COUNT];
#endif
};

MaterialInput GetMaterialInput(PixelInput input)
{
	MaterialInput result = (MaterialInput)0;
	result.WorldPosition = input.WorldPosition;
	result.TexCoord = input.TexCoord;
	result.ParticleIndex = input.ParticleIndex;
#if USE_VERTEX_COLOR
	result.VertexColor = input.VertexColor;
#endif
	result.TBN = input.TBN;
	result.TwoSidedSign = input.IsFrontFace ? 1.0 : -1.0;
	result.InstanceOrigin = input.InstanceOrigin;
	result.InstanceParams = input.InstanceParams;
	result.SvPosition = input.Position;
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	result.CustomVSToPS = input.CustomVSToPS;
#endif
	return result;
}

// Gets the local to world transform matrix (supports instancing)
float4x4 GetInstanceTransform(ModelInput input)
{
	return WorldMatrix;
}
float4x4 GetInstanceTransform(MaterialInput input)
{
	return WorldMatrix;
}

// Removes the scale vector from the local to world transformation matrix (supports instancing)
float3x3 RemoveScaleFromLocalToWorld(float3x3 localToWorld)
{
	// Extract per axis scales from localToWorld transform
	float scaleX = length(localToWorld[0]);
	float scaleY = length(localToWorld[1]);
	float scaleZ = length(localToWorld[2]);
	float3 invScale = float3(
		scaleX > 0.00001f ? 1.0f / scaleX : 0.0f,
		scaleY > 0.00001f ? 1.0f / scaleY : 0.0f,
		scaleZ > 0.00001f ? 1.0f / scaleZ : 0.0f);
	localToWorld[0] *= invScale.x;
	localToWorld[1] *= invScale.y;
	localToWorld[2] *= invScale.z;
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
	float3x3 localToWorld = (float3x3)GetInstanceTransform(input);
	//localToWorld = RemoveScaleFromLocalToWorld(localToWorld);
	return mul(localVector, localToWorld);
}

// Transforms a vector from local space to world space
float3 TransformWorldVectorToLocal(MaterialInput input, float3 worldVector)
{
	float3x3 localToWorld = (float3x3)GetInstanceTransform(input);
	//localToWorld = RemoveScaleFromLocalToWorld(localToWorld);
	return mul(localToWorld, worldVector);
}

// Gets the current object position (supports instancing)
float3 GetObjectPosition(MaterialInput input)
{
	return input.InstanceOrigin.xyz;
}

// Gets the current object size
float3 GetObjectSize(MaterialInput input)
{
	return float3(1, 1, 1);
}

// Get the current object random value (supports instancing)
float GetPerInstanceRandom(MaterialInput input)
{
	return input.InstanceParams;
}

// Get the current object LOD transition dither factor (supports instancing)
float GetLODDitherFactor(MaterialInput input)
{
	return 0;
}

// Gets the interpolated vertex color (in linear space)
float4 GetVertexColor(MaterialInput input)
{
#if USE_VERTEX_COLOR
	return input.VertexColor;
#else
	return 1;
#endif
}

uint GetParticleUint(uint particleIndex, int offset)
{
	return ParticlesData.Load(particleIndex * ParticleStride + offset);
}

int GetParticleInt(uint particleIndex, int offset)
{
	return asint(ParticlesData.Load(particleIndex * ParticleStride + offset));
}

float GetParticleFloat(uint particleIndex, int offset)
{
	return asfloat(ParticlesData.Load(particleIndex * ParticleStride + offset));
}

float2 GetParticleVec2(uint particleIndex, int offset)
{
	return asfloat(ParticlesData.Load2(particleIndex * ParticleStride + offset));
}

float3 GetParticleVec3(uint particleIndex, int offset)
{
	return asfloat(ParticlesData.Load3(particleIndex * ParticleStride + offset));
}

float4 GetParticleVec4(uint particleIndex, int offset)
{
	return asfloat(ParticlesData.Load4(particleIndex * ParticleStride + offset));
}

float3 TransformParticlePosition(float3 input)
{
	return mul(float4(input, 1.0f), WorldMatrix).xyz;
}

float3 TransformParticleVector(float3 input)
{
	return mul(float4(input, 0.0f), WorldMatrixInverseTransposed).xyz;
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

// Fix line for errors/warnings for shader code from template
#line 1000

// Calculates the transform matrix from mesh tangent space to local space
half3x3 CalcTangentToLocal(ModelInput input)
{
	float bitangentSign = input.Tangent.w ? -1.0f : +1.0f;
	float3 normal = input.Normal.xyz * 2.0 - 1.0;
	float3 tangent = input.Tangent.xyz * 2.0 - 1.0;
	float3 bitangent = cross(normal, tangent) * bitangentSign;
	return float3x3(tangent, bitangent, normal);
}

half3x3 CalcTangentToWorld(in float4x4 world, in half3x3 tangentToLocal)
{
	half3x3 localToWorld = RemoveScaleFromLocalToWorld((float3x3)world);
	return mul(tangentToLocal, localToWorld); 
}

float3 GetParticlePosition(uint ParticleIndex)
{
	return TransformParticlePosition(GetParticleVec3(ParticleIndex, PositionOffset));
}

// Vertex Shader function for Sprite Rendering
META_VS(true, FEATURE_LEVEL_ES2)
META_VS_IN_ELEMENT(POSITION, 0, R32G32_FLOAT, 0, 0,     PER_VERTEX, 0, true)
META_VS_IN_ELEMENT(TEXCOORD, 0, R32G32_FLOAT, 0, ALIGN, PER_VERTEX, 0, true)
VertexOutput VS_Sprite(SpriteInput input, uint particleIndex : SV_InstanceID)
{
	VertexOutput output;

#if HAS_SORTED_INDICES
	// Sorted particles mapping
	if (SortedIndicesOffset != 0xFFFFFFFF)
	{
		particleIndex = SortedIndices[SortedIndicesOffset + particleIndex];
	}
#endif

	// Read particle data	
	float3 particlePosition = GetParticleVec3(particleIndex, PositionOffset);
	float3 particleRotation = GetParticleVec3(particleIndex, RotationOffset);
	float2 spriteSize = GetParticleVec2(particleIndex, SpriteSizeOffset);
	int spriteFacingMode = SpriteFacingModeOffset != -1 ? GetParticleInt(particleIndex, SpriteFacingModeOffset) : -1;

	float4x4 world = WorldMatrix;
	float3x3 eulerMatrix = EulerMatrix(radians(particleRotation));
	float3x3 viewRot = transpose((float3x3)ViewMatrix);
	float3 position = mul(float4(particlePosition, 1), world).xyz;

	// Orient sprite
	float3 axisX, axisY, axisZ;
	if (spriteFacingMode == 0)
	{
		// Face Camera Position
		axisZ = normalize(ViewPos - position);
		axisX = -normalize(cross(viewRot[1].xyz, axisZ));
		axisY = cross(axisZ, axisX);
	}
	else if (spriteFacingMode == 1)
	{
		// Face Camera Plane
		axisX = viewRot[0].xyz;
		axisY = -viewRot[1].xyz;
		axisZ = viewRot[2].xyz;
	}
	else if (spriteFacingMode == 2)
	{
		// Along Velocity
		float3 velocity = GetParticleVec3(particleIndex, VelocityOffset);
		axisY = normalize(velocity);
		axisZ = ViewPos - position;
		axisX = normalize(cross(axisY, axisZ));
		axisZ = cross(axisX, axisY);
	}
	else if (spriteFacingMode == 3)
	{
		// Custom Facing Vector
		float3 spriteFacingVector = GetParticleVec3(particleIndex, SpriteFacingVectorOffset);
		axisZ = spriteFacingVector;
		axisX = normalize(cross(viewRot[1].xyz, axisZ));
		axisY = cross(axisZ, axisX);
	}
	else if (spriteFacingMode == 4)
	{
		// Fixed Axis
		float3 spriteFacingVector = GetParticleVec3(particleIndex, SpriteFacingVectorOffset);
		axisY = spriteFacingVector;
		axisZ = ViewPos - position;
		axisX = normalize(cross(axisY, axisZ));
		axisZ = cross(axisX, axisY);
	}
	else
	{
		// Default
		axisX = float3(1, 0, 0);
		axisY = float3(0, 1, 0);
		axisZ = float3(0, 0, 1);
	}

	// Compute world space vertex position
	float3 spriteVertexPosition = float3(input.Position.xy * spriteSize, 0);
	spriteVertexPosition = mul(spriteVertexPosition, eulerMatrix);
	spriteVertexPosition = mul(spriteVertexPosition, float3x3(axisX, axisY, axisZ));
	output.WorldPosition = position + spriteVertexPosition;

	// Compute clip space position
	output.Position = mul(float4(output.WorldPosition.xyz, 1), ViewProjectionMatrix);

	// Pass vertex attributes
	output.TexCoord = input.TexCoord;
	output.ParticleIndex = particleIndex;
#if USE_VERTEX_COLOR
	output.VertexColor = 1;
#endif
	output.InstanceOrigin = world[3].xyz;
	output.InstanceParams = PerInstanceRandom;

	// Calculate tanget space to world space transformation matrix for unit vectors
	half3x3 tangentToLocal = float3x3(axisX, axisY, axisZ);
	half3x3 tangentToWorld = CalcTangentToWorld(world, tangentToLocal);
	output.TBN = tangentToWorld;

	// Get material input params if need to evaluate any material property
#if USE_POSITION_OFFSET || USE_CUSTOM_VERTEX_INTERPOLATORS
	MaterialInput materialInput = (MaterialInput)0;
	materialInput.WorldPosition = output.WorldPosition;
	materialInput.TexCoord = output.TexCoord;
	materialInput.ParticleIndex = output.ParticleIndex;
#if USE_VERTEX_COLOR
	materialInput.VertexColor = output.VertexColor;
#endif
	materialInput.TBN = output.TBN;
	materialInput.TwoSidedSign = 1;
	materialInput.SvPosition = output.Position;
	materialInput.PreSkinnedPosition = float3(input.Position.xy, 0);
	materialInput.PreSkinnedNormal = tangentToLocal[2].xyz;
	materialInput.InstanceOrigin = output.InstanceOrigin;
	materialInput.InstanceParams = output.InstanceParams;	
	Material material = GetMaterialVS(materialInput);
#endif

	// Apply world position offset per-vertex
#if USE_POSITION_OFFSET
	output.WorldPosition += material.PositionOffset;
	output.Position = mul(float4(output.WorldPosition.xyz, 1), ViewProjectionMatrix);
#endif

	// Copy interpolants for other shader stages
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	output.CustomVSToPS = material.CustomVSToPS;
#endif

	return output;
}

// Vertex Shader function for Model Rendering
META_VS(true, FEATURE_LEVEL_ES2)
META_VS_IN_ELEMENT(POSITION, 0, R32G32B32_FLOAT,   0, 0,     PER_VERTEX, 0, true)
META_VS_IN_ELEMENT(TEXCOORD, 0, R16G16_FLOAT,      1, 0,     PER_VERTEX, 0, true)
META_VS_IN_ELEMENT(NORMAL,   0, R10G10B10A2_UNORM, 1, ALIGN, PER_VERTEX, 0, true)
META_VS_IN_ELEMENT(TANGENT,  0, R10G10B10A2_UNORM, 1, ALIGN, PER_VERTEX, 0, true)
META_VS_IN_ELEMENT(TEXCOORD, 1, R16G16_FLOAT,      1, ALIGN, PER_VERTEX, 0, true)
META_VS_IN_ELEMENT(COLOR,    0, R8G8B8A8_UNORM,    2, 0,     PER_VERTEX, 0, USE_VERTEX_COLOR)
VertexOutput VS_Model(ModelInput input, uint particleIndex : SV_InstanceID)
{
	VertexOutput output;

#if HAS_SORTED_INDICES
	// Sorted particles mapping
	if (SortedIndicesOffset != 0xFFFFFFFF)
	{
		particleIndex = SortedIndices[SortedIndicesOffset + particleIndex];
	}
#endif

	// Read particle data
	float3 particlePosition = GetParticleVec3(particleIndex, PositionOffset);
	float3 particleScale = GetParticleVec3(particleIndex, ScaleOffset);
	float3 particleRotation = GetParticleVec3(particleIndex, RotationOffset);
	int modelFacingMode = ModelFacingModeOffset != -1 ? GetParticleInt(particleIndex, ModelFacingModeOffset) : -1;
	float3 position = mul(float4(particlePosition, 1), WorldMatrix).xyz;

	// Compute final vertex position in the world
	float3x3 eulerMatrix = EulerMatrix(radians(particleRotation));
	float4 transform0 = float4(eulerMatrix[0], particlePosition.x);
	float4 transform1 = float4(eulerMatrix[1], particlePosition.y);
	float4 transform2 = float4(eulerMatrix[2], particlePosition.z);
	float4x4 scaleMatrix = float4x4(float4(particleScale.x, 0.0f, 0.0f, 0.0f), float4(0.0f, particleScale.y, 0.0f, 0.0f), float4(0.0f, 0.0f, particleScale.z, 0.0f), float4(0.0f, 0.0f, 0.0f, 1.0f));
	float4x4 world = float4x4(transform0, transform1, transform2, float4(0.0f, 0.0f, 0.0f, 1.0f));
	if (modelFacingMode == 0)
	{
		// Face Camera Position
		float3 direction = normalize(ViewPos - position);
		float4 alignmentQuat = FindQuatBetween(float3(1.0f, 0.0f, 0.0f), direction);
		float4x4 alignmentMat = QuaternionToMatrix(alignmentQuat);
		world = mul(world, mul(alignmentMat, scaleMatrix));
	}
	else if (modelFacingMode == 1)
	{
		// Face Camera Plane
		float3 direction = -ViewDir;
		float4 alignmentQuat = FindQuatBetween(float3(1.0f, 0.0f, 0.0f), direction);
		float4x4 alignmentMat = QuaternionToMatrix(alignmentQuat);
		world =  mul(world, mul(alignmentMat, scaleMatrix));
	}
	else if (modelFacingMode == 2)
	{
		// Along Velocity
		float3 direction = GetParticleVec3(particleIndex, VelocityOffset);
		float4 alignmentQuat = FindQuatBetween(float3(1.0f, 0.0f, 0.0f), normalize(direction));
		float4x4 alignmentMat = QuaternionToMatrix(alignmentQuat);
		world =  mul(world, mul(alignmentMat, scaleMatrix));
	}
	else
	{
		// Default
		world =  mul(world, scaleMatrix);
	}
	world = transpose(world);
	world =  mul(world, WorldMatrix);

	// Calculate the vertex position in world space
	output.WorldPosition = mul(float4(input.Position, 1), world).xyz;

	// Compute clip space position
	output.Position = mul(float4(output.WorldPosition, 1), ViewProjectionMatrix);

	// Pass vertex attributes
	output.TexCoord = input.TexCoord;
	output.ParticleIndex = particleIndex;
#if USE_VERTEX_COLOR
	output.VertexColor = input.Color;
#endif
	output.InstanceOrigin = WorldMatrix[3].xyz;
	output.InstanceParams = PerInstanceRandom;

	// Calculate tanget space to world space transformation matrix for unit vectors
	half3x3 tangentToLocal = CalcTangentToLocal(input);
	half3x3 tangentToWorld = CalcTangentToWorld(WorldMatrix, tangentToLocal);
	output.TBN = tangentToWorld;

	// Get material input params if need to evaluate any material property
#if USE_POSITION_OFFSET || USE_CUSTOM_VERTEX_INTERPOLATORS
	MaterialInput materialInput = (MaterialInput)0;
	materialInput.WorldPosition = output.WorldPosition;
	materialInput.TexCoord = output.TexCoord;
	materialInput.ParticleIndex = output.ParticleIndex;
#if USE_VERTEX_COLOR
	materialInput.VertexColor = output.VertexColor;
#endif
	materialInput.TBN = output.TBN;
	materialInput.TwoSidedSign = 1;
	materialInput.SvPosition = output.Position;
	materialInput.PreSkinnedPosition = input.Position.xyz;
	materialInput.PreSkinnedNormal = tangentToLocal[2].xyz;
	materialInput.InstanceOrigin = output.InstanceOrigin;
	materialInput.InstanceParams = output.InstanceParams;
	Material material = GetMaterialVS(materialInput);
#endif

	// Apply world position offset per-vertex
#if USE_POSITION_OFFSET
	output.WorldPosition += material.PositionOffset;
	output.Position = mul(float4(output.WorldPosition.xyz, 1), ViewProjectionMatrix);
#endif

	// Copy interpolants for other shader stages
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	output.CustomVSToPS = material.CustomVSToPS;
#endif

	return output;
}

// Vertex Shader function for Ribbon Rendering
META_VS(true, FEATURE_LEVEL_ES2)
VertexOutput VS_Ribbon(uint vertexIndex : SV_VertexID)
{
	VertexOutput output;

	// Get particle data
	uint particleIndex = vertexIndex / 2;
	int vertexSign = (((int)vertexIndex & 0x1) * 2) - 1;
	float3 position = GetParticlePosition(particleIndex);
	float ribbonWidth = RibbonWidthOffset != -1 ? GetParticleFloat(particleIndex, RibbonWidthOffset) : 20.0f;
	float ribbonTwist = RibbonTwistOffset != -1 ? GetParticleFloat(particleIndex, RibbonTwistOffset) : 0.0f;

	// Calculate ribbon direction
	float3 direction;
	if (particleIndex == 0)
	{
		float3 nextParticlePos = GetParticlePosition(particleIndex + 1);
		direction = nextParticlePos - position;
	}
	else
	{
		float3 previousParticlePos = GetParticlePosition(particleIndex - 1);
		direction = position - previousParticlePos;
	}

	// Calculate particle orientation (tangent vectors)
	float3 cameraDirection = SafeNormalize(ViewPos - position);
	float3 tangentUp = SafeNormalize(direction);
	float3 facing = RibbonFacingVectorOffset != -1 ? GetParticleVec3(particleIndex, RibbonFacingVectorOffset) : cameraDirection;
	float twistSine, twistCosine;
	sincos(radians(ribbonTwist), twistSine, twistCosine);
	facing = facing * twistCosine + cross(facing, tangentUp) * twistSine + tangentUp * dot(tangentUp, facing) * (1 - twistCosine);
	float3 tangentRight = SafeNormalize(cross(tangentUp, facing));
	if (!any(tangentRight))
	{
		tangentRight = SafeNormalize(cross(tangentUp, float3(0.0f, 0.0f, 1.0f)));
	}

	// Calculate texture coordinates
	float texCoordU;
#ifdef _VS_Ribbon
	if (RibbonUVTilingDistance != 0.0f)
	{
		texCoordU = SegmentDistances[particleIndex] / RibbonUVTilingDistance;
	}
	else
#endif
	{
		texCoordU = (float)particleIndex / RibbonSegmentCount;
	}
	float texCoordV = (vertexIndex + 1) & 0x1;
	output.TexCoord = float2(texCoordU, texCoordV) * RibbonUVScale + RibbonUVOffset;

	// Compute world space vertex position
	output.WorldPosition = position + tangentRight * vertexSign * (ribbonWidth.xxx * 0.5f);

	// Compute clip space position
	output.Position = mul(float4(output.WorldPosition.xyz, 1), ViewProjectionMatrix);

	// Pass vertex attributes
	output.ParticleIndex = particleIndex;
#if USE_VERTEX_COLOR
	output.VertexColor = 1;
#endif
	output.InstanceOrigin = WorldMatrix[3].xyz;
	output.InstanceParams = PerInstanceRandom;

	// Calculate tanget space to world space transformation matrix for unit vectors
	half3x3 tangentToLocal = float3x3(tangentRight, tangentUp, cross(tangentRight, tangentUp));
	half3x3 tangentToWorld = CalcTangentToWorld(WorldMatrix, tangentToLocal);
	output.TBN = tangentToWorld;

	// Get material input params if need to evaluate any material property
#if USE_POSITION_OFFSET || USE_CUSTOM_VERTEX_INTERPOLATORS
	MaterialInput materialInput = (MaterialInput)0;
	materialInput.WorldPosition = output.WorldPosition;
	materialInput.TexCoord = output.TexCoord;
	materialInput.ParticleIndex = output.ParticleIndex;
#if USE_VERTEX_COLOR
	materialInput.VertexColor = output.VertexColor;
#endif
	materialInput.TBN = output.TBN;
	materialInput.TwoSidedSign = 1;
	materialInput.SvPosition = output.Position;
	materialInput.PreSkinnedPosition = Position;
	materialInput.PreSkinnedNormal = tangentToLocal[2].xyz;
	materialInput.InstanceOrigin = output.InstanceOrigin;
	materialInput.InstanceParams = output.InstanceParams;	
	Material material = GetMaterialVS(materialInput);
#endif

	// Apply world position offset per-vertex
#if USE_POSITION_OFFSET
	output.WorldPosition += material.PositionOffset;
	output.Position = mul(float4(output.WorldPosition.xyz, 1), ViewProjectionMatrix);
#endif

	// Copy interpolants for other shader stages
#if USE_CUSTOM_VERTEX_INTERPOLATORS
	output.CustomVSToPS = material.CustomVSToPS;
#endif

	return output;
}

// Pixel Shader function for Forward Pass
META_PS(USE_FORWARD, FEATURE_LEVEL_ES2)
float4 PS_Forward(PixelInput input) : SV_Target0
{
	float4 output = 0;

	// Get material parameters
	MaterialInput materialInput = GetMaterialInput(input);
	Material material = GetMaterialPS(materialInput);

	// Masking
#if MATERIAL_MASKED
	clip(material.Mask - MATERIAL_MASK_THRESHOLD);
#endif

	// Add emissive light
	output = float4(material.Emissive, material.Opacity);

#if MATERIAL_SHADING_MODEL != SHADING_MODEL_UNLIT

	// Setup GBuffer data as proxy for lighting
	GBufferSample gBuffer;
	gBuffer.Normal = material.WorldNormal;
	gBuffer.Roughness = material.Roughness;
	gBuffer.Metalness = material.Metalness;
	gBuffer.Color = material.Color;
	gBuffer.Specular = material.Specular;
	gBuffer.AO = material.AO;
	gBuffer.ViewPos = mul(float4(materialInput.WorldPosition, 1), ViewMatrix).xyz;
#if MATERIAL_SHADING_MODEL == SHADING_MODEL_SUBSURFACE
	gBuffer.CustomData = float4(material.SubsurfaceColor, material.Opacity);
#elif MATERIAL_SHADING_MODEL == SHADING_MODEL_FOLIAGE
	gBuffer.CustomData = float4(material.SubsurfaceColor, material.Opacity);
#else
	gBuffer.CustomData = float4(0, 0, 0, 0);
#endif
	gBuffer.WorldPos = materialInput.WorldPosition;
	gBuffer.ShadingModel = MATERIAL_SHADING_MODEL;

	// Calculate lighting from a single directional light
	float4 shadowMask = 1.0f;
	if (DirectionalLight.CastShadows > 0)
	{
		LightShadowData directionalLightShadowData = GetDirectionalLightShadowData();
		shadowMask.r = SampleShadow(DirectionalLight, directionalLightShadowData, DirectionalLightShadowMap, gBuffer, shadowMask.g);
	}
	float4 light = GetLighting(ViewPos, DirectionalLight, gBuffer, shadowMask, false, false);

	// Calculate lighting from sky light
	light += GetSkyLightLighting(SkyLight, gBuffer, SkyLightTexture);

	// Calculate lighting from local lights
	LOOP
	for (uint localLightIndex = 0; localLightIndex < LocalLightsCount; localLightIndex++)
	{
		const LightData localLight = LocalLights[localLightIndex];
		bool isSpotLight = localLight.SpotAngles.x > -2.0f;
		shadowMask = 1.0f;
		light += GetLighting(ViewPos, localLight, gBuffer, shadowMask, true, isSpotLight);
	}

#if USE_REFLECTIONS
	// Calculate reflections
	light.rgb += GetEnvProbeLighting(ViewPos, EnvProbe, EnvironmentProbe, gBuffer) * light.a;	
#endif

	// Add lighting (apply ambient occlusion)
	output.rgb += light.rgb * gBuffer.AO;

#if USE_FOG
	// Calculate exponential height fog
	float4 fog = GetExponentialHeightFog(ExponentialHeightFog, materialInput.WorldPosition, ViewPos, 0);

	// Apply fog to the output color
#if MATERIAL_BLEND == MATERIAL_BLEND_OPAQUE
	output = float4(output.rgb * fog.a + fog.rgb, output.a);
#elif MATERIAL_BLEND == MATERIAL_BLEND_TRANSPARENT
	output = float4(output.rgb * fog.a + fog.rgb, output.a);
#elif MATERIAL_BLEND == MATERIAL_BLEND_ADDITIVE
	output = float4(output.rgb * fog.a + fog.rgb, output.a * fog.a);
#elif MATERIAL_BLEND == MATERIAL_BLEND_MULTIPLY
	output = float4(lerp(float3(1, 1, 1), output.rgb, fog.aaa * fog.aaa), output.a);
#endif

#endif

#endif

	return output;
}

#if USE_DISTORTION

// Pixel Shader function for Distortion Pass
META_PS(USE_DISTORTION, FEATURE_LEVEL_ES2)
float4 PS_Distortion(PixelInput input) : SV_Target0
{
	// Get material parameters
	MaterialInput materialInput = GetMaterialInput(input);
	Material material = GetMaterialPS(materialInput);

	// Masking
#if MATERIAL_MASKED
	clip(material.Mask - MATERIAL_MASK_THRESHOLD);
#endif

	float3 viewNormal = normalize(TransformWorldVectorToView(materialInput, material.WorldNormal));
	float airIOR = 1.0f;
#if USE_PIXEL_NORMAL_OFFSET_REFRACTION
	float3 viewVertexNormal = TransformWorldVectorToView(materialInput, TransformTangentVectorToWorld(materialInput, float3(0, 0, 1)));
	float2 distortion = (viewVertexNormal.xy - viewNormal.xy) * (material.Refraction - airIOR);
#else
	float2 distortion = viewNormal.xy * (material.Refraction - airIOR);
#endif

	// Clip if the distortion distance (squared) is too small to be noticed
	clip(dot(distortion, distortion) - 0.00001);

	// Scale up for better precision in low/subtle refractions at the expense of artefacts at higher refraction
	distortion *= 4.0f;

	// Use separate storage for positive and negative offsets
	float2 addOffset = max(distortion, 0);
	float2 subOffset = abs(min(distortion, 0));
	return float4(addOffset.x, addOffset.y, subOffset.x, subOffset.y);
}

#endif

// Pixel Shader function for Depth Pass
META_PS(true, FEATURE_LEVEL_ES2)
void PS_Depth(PixelInput input
#if GLSL
	, out float4 OutColor : SV_Target0
#endif
	)
{
	// Get material parameters
	MaterialInput materialInput = GetMaterialInput(input);
	Material material = GetMaterialPS(materialInput);

	// Perform per pixel clipping
#if MATERIAL_MASKED
	clip(material.Mask - MATERIAL_MASK_THRESHOLD);
#endif
#if MATERIAL_BLEND == MATERIAL_BLEND_TRANSPARENT
	clip(material.Opacity - MATERIAL_OPACITY_THRESHOLD);
#endif

#if GLSL
	OutColor = 0;
#endif
}

@9
