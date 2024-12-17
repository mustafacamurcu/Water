// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/SimpleUnlitTexturedShader"
{
    Properties
    {
    }
    SubShader
    {
        CGINCLUDE
            #pragma enable_d3d11_debug_symbols
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"
            struct appdata
            {
                float4 vertex : POSITION; // vertex position
            };
            
            struct Wave {
                float3 direction;
                float freq;
                float amp;
                float speed;
                float timeOffset;
            };

            StructuredBuffer<Wave> _Waves;
            int _WaveCount;
            int _ShowNormals;
            float3 _SunDirection;
            float3 _WaterColor;

            static const float E = 2.7;

            float getWaveCoord(Wave wave, float3 v) {
                return wave.direction.x * v.x + wave.direction.z * v.z;
            }

            float displacement(Wave wave, float waveCoord) {
                float time = (_Time.y + wave.timeOffset) * wave.speed;
                return wave.amp * (pow(E, sin(time + waveCoord * wave.freq) - 1) - 0.5);
                // return wave.amp * sin(time + waveCoord * wave.freq);
            }

            float tangent(Wave wave, float waveCoord) {
                float time = (_Time.y + wave.timeOffset) * wave.speed;
                return wave.amp * wave.freq * wave.direction.z * pow(E, sin(time + waveCoord * wave.freq)-1) * cos(time + waveCoord * wave.freq);
            }

            float bitangent(Wave wave, float waveCoord) {
                float time = (_Time.y + wave.timeOffset) * wave.speed;
                return wave.amp * wave.freq * wave.direction.x * pow(E, sin(time + waveCoord * wave.freq)-1) * cos(time + waveCoord * wave.freq);
            }

        ENDCG
        
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct v2f
            {
                float4 pos : SV_POSITION; // clip space position
                float3 world_pos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                for (int i = 0 ; i < _WaveCount ; i++) {
                    float waveCoord = getWaveCoord(_Waves[i], v.vertex);
                    v.vertex.y += displacement(_Waves[i], waveCoord);
                }
                o.pos = UnityObjectToClipPos(v.vertex);
                o.world_pos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float tangent_delta = 0;
                float bitangent_delta = 0;
                for (int j = 0 ; j < _WaveCount ; j++) {
                    float waveCoord = getWaveCoord(_Waves[j], i.world_pos);
                    tangent_delta += tangent(_Waves[j], waveCoord);
                    bitangent_delta += bitangent(_Waves[j], waveCoord);
                }
                float3 T = float3(0,tangent_delta,1);
                float3 B = float3(1,bitangent_delta,0);
                float3 normal = normalize(UnityObjectToWorldNormal(normalize(cross(T,B))));

                float3 light_dir = normalize(-_SunDirection);
                float3 diffuse = DotClamped(light_dir, normal) * _WaterColor;

                float3 view_dir = normalize(_WorldSpaceCameraPos - i.world_pos);
                float3 halfway = normalize(light_dir + view_dir);
                float3 specular = pow(DotClamped(halfway, normal), 32) * float3(1,0.9,0.6);
                return float4(GammaToLinearSpace(diffuse + specular), 1.0);
            }
            ENDCG
        }

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            struct v2g
            {
                float4 vertex : SV_POSITION; // clip space position
                float3 normal : TEXCOORD1;
                float3 tangent: TEXCOORD2;
                float3 bitangent: TEXCOORD3;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION; // clip space position
                fixed4 color : COLOR;
            };

            v2g vert (appdata v)
            {
                v2g o;
                o.normal = float3(0,0,0);
                float tangent_delta = 0;
                float bitangent_delta = 0;
                for (int i = 0 ; i < _WaveCount ; i++) {
                    float waveCoord = getWaveCoord(_Waves[i], v.vertex);
                    v.vertex.y += displacement(_Waves[i], waveCoord);
                    tangent_delta += tangent(_Waves[i], waveCoord);
                    bitangent_delta += bitangent(_Waves[i], waveCoord);
                }
                float3 T = float3(0,tangent_delta,1);
                float3 B = float3(1,bitangent_delta,0);
                o.normal = normalize(cross(T,B));
                o.vertex = v.vertex;
                o.tangent = normalize(T);
                o.bitangent = normalize(B);
                return o;
            }

            [maxvertexcount(6)]
            void geom(triangle v2g input[3], inout LineStream<g2f> lineStream) {
                if (!_ShowNormals) {
                    return;
                }

                g2f o;
                for (int i = 0; i < 3; i++) {
                    // Yellow is Normal
                    o.color = float4(.9,.9,.2,1.0);
                    o.vertex = UnityObjectToClipPos(input[i].vertex);
                    lineStream.Append(o);
                    o.vertex = UnityObjectToClipPos(input[i].vertex + 0.08*float4(input[i].normal, 0));
                    lineStream.Append(o);
                    lineStream.RestartStrip();

                    // Pink is Tangent
                    o.color = float4(.9,.2,.9,1.0);
                    o.vertex = UnityObjectToClipPos(input[i].vertex);
                    lineStream.Append(o);
                    o.vertex = UnityObjectToClipPos(input[i].vertex + 0.08*float4(input[i].tangent, 0));
                    lineStream.Append(o);
                    lineStream.RestartStrip();

                    // Teal is Bitangent
                    o.color = float4(.2,.9,.9,1.0);
                    o.vertex = UnityObjectToClipPos(input[i].vertex);
                    lineStream.Append(o);
                    o.vertex = UnityObjectToClipPos(input[i].vertex + 0.08*float4(input[i].bitangent, 0));
                    lineStream.Append(o);
                    lineStream.RestartStrip();
                }
            }

            fixed4 frag (g2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
}