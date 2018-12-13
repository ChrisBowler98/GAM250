Shader "Custom/Water"
{
	Properties
	{
		_Gravity("Gravity", Float) = 9.8
		_WaveA("Wave A (Direction(x,y), Steepness(z), Wave Length(w))", Vector) = (1,0,0.5,10)
		_WaveB("Wave B", Vector) = (0,1,0.25,20)
		_WaveC("Wave B", Vector) = (1,1,0.15,10)
		_Color("Color", Color) = (1, 1, 1, 0.5)
		_DepthFactor("Depth Factor", float) = 1.0
		_DepthRampTex("Depth Ramp", 2D) = "white" {}
		_BumpTex("Bump", 2D) = "white" {}
		_DistortStrength("Distort Strength", float) = 1.0
	}
	SubShader
	{ 
		// We need to render behind the water first to distort it.
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }

		// Makes the water Transparent:
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Cull Off

		// Grab the screen behind the object into _BackgroundTexture
        GrabPass
        {
            "_BackgroundTexture"
        }

        // Background distortion
        Pass
        {
            Tags
            {
                "Queue" = "Transparent"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // Properties
            sampler2D _BackgroundTexture;
            sampler2D _BumpTex;
            float     _DistortStrength;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 texCoord : TEXCOORD0;
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float4 grabPos : TEXCOORD0;
            };

			// Vertex Shader
            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;

                // convert input to world space
                output.pos = UnityObjectToClipPos(input.vertex);
                float4 normal4 = float4(input.normal, 0.0);
				float3 normal = normalize(mul(normal4, unity_WorldToObject).xyz);

                // use ComputeGrabScreenPos function from UnityCG.cginc
                // to get the correct texture coordinate
                output.grabPos = ComputeGrabScreenPos(output.pos);

                // distort based on bump map
                float3 bump = tex2Dlod(_BumpTex, float4(input.texCoord.xy, 0, 0)).rgb;
                output.grabPos.x += bump.x * _DistortStrength;
                output.grabPos.y += bump.y * _DistortStrength;

                return output;
            }

			// Fragment Shader:
            float4 frag(vertexOutput input) : COLOR
            {
                return tex2Dproj(_BackgroundTexture, input.grabPos);
            }
            ENDCG
        }
		
		// Waves and depth effect
		Pass
	{
			LOD 200
			CGPROGRAM

		// required to use ComputeScreenPos()
		#include "UnityCG.cginc"

		#pragma vertex vert
		#pragma fragment frag

	// Unity built-in - NOT required in Properties
	sampler2D _CameraDepthTexture;
	sampler2D _DepthRampTex;

	// Properties
	float4 _WaveA;
	float4 _WaveB;
	float4 _WaveC;
	float _Gravity;
	float _DepthFactor;
	float4 _Color;

	struct vertexInput 
	{
		float4 vertex : POSITION;
		float4 tangent : TANGENT;
		float3 normal : NORMAL;
		float4 texCoord : TEXCOORD0;
	};

	struct vertexOutput
	{
		float4 pos : SV_POSITION;
		float4 screenPos : TEXCOORD1;
		float4 texCoord : TEXCOORD0;
	};

	// Generates One Gerstner Wave:
	float3 GerstnerWave(
		float4 wave, float3 p, inout float3 tangent, inout float3 binormal
	)
	{
		float steepness = wave.z;
		float wavelength = wave.w;
		float k = 2 * UNITY_PI / wavelength;
		float c = sqrt(_Gravity / k);
		float2 d = normalize(wave.xy);
		float f = k * (dot(d, p.xz) - (c * _Time.y));
		float a = steepness / k;

		// Used the chain rule to get the tangent for the lighting:
		tangent += float3(
			1 - d.x * d.x * (steepness * sin(f)),
			d.x * (steepness * cos(f)),
			-d.x * d.y * (steepness * sin(f))
			);

		// Oppisite of the tangent:
		binormal += float3(
			-d.x * d.y * (steepness * sin(f)),
			d.y * (steepness * cos(f)),
			1 - d.y * d.y * (steepness * sin(f))
			);

		// Return the animation movement:
		return float3(
			d.x * (a * cos(f)),
			a * sin(f),
			d.y * (a * cos(f))
			);
	}

	// Vertex Shader:
	vertexOutput vert(vertexInput input) {

		// Waves:
		float3 gridPoint = input.vertex.xyz;
		float3 tangent = 0;
		float3 binormal = 0;
		float3 p = gridPoint;

		// Create three waves:
		p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
		p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
		p += GerstnerWave(_WaveC, gridPoint, tangent, binormal);

		float3 normal = normalize(cross(binormal, tangent));

		// Wave itself
		input.vertex.xyz = p;
		// Lighting for wave
		input.normal = normal;

		// Depth effect:
		vertexOutput output;

		output.pos = UnityObjectToClipPos(input.vertex);

		output.screenPos = ComputeScreenPos(output.pos);

		output.texCoord = input.texCoord;

		return output;
	}

	// Fragment Shader:
	float4 frag(vertexOutput input) : COLOR
	{
		// Depth foam lines:
		float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, input.screenPos);
		float depth = LinearEyeDepth(depthSample).r;

		float foamLine = 1 - saturate(_DepthFactor * (depth - input.screenPos.w));
		float4 foamRamp = float4(tex2D(_DepthRampTex, float2(foamLine, 0.5)).rgb, 1.0);

		float4 col = _Color * foamRamp;
		return col;
	}
	ENDCG
		}
	}
}