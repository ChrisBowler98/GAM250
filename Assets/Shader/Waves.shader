Shader "Custom/Waves" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		//_Amplitude("Amplitude", Float) = 1
		_Gravity("Gravity", Float) = 9.8
		_WaveA("Wave A (Direction(x,y), Steepness(z), Wave Length(w))", Vector) = (1,0,0.5,10)
		_WaveB("Wave B", Vector) = (0,1,0.25,20)
		_WaveC("Wave B", Vector) = (1,1,0.15,10)
		//_Steepness("Steepness", Range(0, 1)) = 0.5
		//_Wavelength("Wavelength", Float) = 1
		//_Direction ("Direction (2D)", Vector) = (1,0,0,0)
		//_WaveSpeed("Wave Speed", Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		//float _Amplitude;
		//float _Steepness;
		//float _Wavelength;
		//float _WaveSpeed;
		//float2 _Direction;
		float4 _WaveA;
		float4 _WaveB;
		float _Gravity;

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

			tangent += float3(
				1 - d.x * d.x * (steepness * sin(f)),
				d.x * (steepness * cos(f)),
				-d.x * d.y * (steepness * sin(f))
				);

			binormal += float3(
				-d.x * d.y * (steepness * sin(f)),
				d.y * (steepness * cos(f)),
				1 - d.y * d.y * (steepness * sin(f))
				);

			return float3(
				d.x * (a * cos(f)),
				a * sin(f),
				d.y * (a * cos(f))
				);
		}

		void vert(inout appdata_full vertexData) {

			float3 gridPoint = vertexData.vertex.xyz;
			float3 tangent = 0;
			float3 binormal = 0;
			float3 p = gridPoint;

			p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
			p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);

			float3 normal = normalize(cross(binormal, tangent));

			// Wave itself
			vertexData.vertex.xyz = p;
			// Lighting for wave
			vertexData.normal = normal;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}