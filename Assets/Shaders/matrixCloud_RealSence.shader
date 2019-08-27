Shader "Custom/MatrixCloud" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _col ("Color",color) = (1.0,1.0,1.0,1.0)
        _size ("Size",range(0.0,1.0)) = 0.1
        _particleSize ("ParticleSize",range(0.0,1.0)) = 1.0
        _mozi ("mozi", 2D) = "white" {}
        [HDR]_mainCol ("MainColor",color) = (0.0,1.0,0.0,1.0)
        _backCol ("BackColor",color) = (0.0,0.0,0.0,1.0)
        _colorpow ("Colorpow",range(0.0,10.0)) = 1.0
        _noiseScale ("NoiseScale",vector) = (10.0,0.1,10.0,1.0)
        _noiseSpeed ("NoiseSpeed",vector) = (0.0,1.0,0.0,1.0)
        _noiseSpeed2 ("NoiseSpeed2(文字種)",vector) = (0.0,1.0,0.0,1.0)
        _seni ("",range(0.0,1.0)) = 1.0
        [IntRange]_pointRate ("PointRate",range(1,100)) = 1
    }
    SubShader {
        Tags { "Queue"="Transparent" "RenderType"="Transparent+50" }
        LOD 100
        ZWrite off
        Blend One One
        Cull off

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex; float4 _MainTex_ST;
            sampler2D _mozi; float4 _mozi_ST;
            uniform float4 _col;
            uniform float _size;
            uniform float _particleSize;
            uniform float4 _noiseScale;
            uniform float4 _noiseSpeed;
            uniform float4 _noiseSpeed2;
            uniform float4 _mainCol;
            uniform float4 _backCol;
            uniform float _seni;
            uniform float _colorpow;
            uniform float _pointRate;

            static float4 offset[4]={   float4(-1.0,-1.0, 0.0, 0.0),
                                        float4( 1.0,-1.0, 0.0, 0.0),
                                        float4(-1.0, 1.0, 0.0, 0.0),
                                        float4( 1.0, 1.0, 0.0, 0.0),};

            struct vinput {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint vid : SV_VertexID;
                float4 color : COLOR;
            };

            struct v2g {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
                float4 color : COLOR;
            };

            struct g2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 offset : TEXCOORD1;
                float3 noise : TEXCOORD3;
                float4 color : COLOR;
            };

            v2g vert (vinput input) {
                v2g output;
                output.vertex = lerp(input.vertex,float4(-1,-1,-1,-1),step(0.5,input.vid%_pointRate));
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.color = input.color;
                return output;
            }

            [maxvertexcount(4)]
            void geom(point v2g input[1], inout TriangleStream<g2f> outStream) {
                g2f output;
                output.uv = input[0].uv;
                float3 wpos = mul(UNITY_MATRIX_M,input[0].vertex).xyz; 
                [unroll]for(int index=0;index<4;index++) {
                    output.offset = offset[index];
                    output.vertex = mul( UNITY_MATRIX_P, mul(UNITY_MATRIX_MV,input[0].vertex) + _size*offset[index]); //パーティクル化
                    output.noise = float3(  rand(float4(floor(wpos*100)+_noiseSpeed2*_Time.y*1e-06,10.0)),
                                            rand(float4(floor(wpos*100)+_noiseSpeed2*_Time.y*1e-06,90.0)),
                                            perlinNoise((wpos*_noiseScale + _Time.y*_noiseSpeed.xyz),_Time.y*_noiseSpeed.z));
                    output.color = input[0].color;
                    outStream.Append(output);
                }
                outStream.RestartStrip();
            }

            fixed4 frag (g2f input) : SV_Target { 
                fixed4 col = tex2D(_MainTex, input.uv);
                col.rgb *= saturate(_particleSize-input.offset.x*input.offset.x-input.offset.y*input.offset.y);
                col *= _col;
                col *= input.color;
                float2 uv = (input.offset*0.5+0.5) * _mozi_ST.xy + _mozi_ST.zw + float2(floor(input.noise.xy/_mozi_ST.xy)*_mozi_ST.xy);
                fixed4 mozi = tex2D(_mozi,uv);
                mozi *= pow(lerp(_mainCol,_backCol,saturate(input.noise.z+1.0)),_colorpow);
                float4 output = lerp(col,mozi,_seni);
                clip(output.a-0.1);
                return output;
            }
            ENDCG
        }

        CGINCLUDE
			//noisebase https://qiita.com/aa_debdeb/items/e1e0ecc2dabb6755ef8f
			float rand(float4 seed){
				return frac(sin(dot(seed.xyzw, float4(12.9898, 78.233, 56.787, 34.648))) * 43758.5453);
			}

			float perlinNoise(float3 P,float w) {
				float x = abs(P.x+500);
				float y = abs(P.y+500);
				float z = abs(P.z+500);
				w = abs(w);
				int xi = (int)x;
				int yi = (int)y;
				int zi = (int)z;
				int wi = (int)w;
				float xf = x - xi;
				float yf = y - yi;
				float zf = z - zi;
				float wf = w - wi;
				float4 f = float4(xf, yf, zf, wf);

				float4 g0000 = rand(float4(xi, yi, zi, wi));
				float4 g1000 = rand(float4(xi + 1, yi, zi, wi));
				float4 g0100 = rand(float4(xi, yi + 1, zi, wi));
				float4 g1100 = rand(float4(xi + 1, yi + 1, zi, wi));
				float4 g0010 = rand(float4(xi, yi, zi + 1, wi));
				float4 g1010 = rand(float4(xi + 1, yi, zi + 1, wi));
				float4 g0110 = rand(float4(xi, yi + 1, zi + 1, wi));
				float4 g1110 = rand(float4(xi + 1, yi + 1, zi + 1, wi));
				float4 g0001 = rand(float4(xi, yi, zi, wi + 1));
				float4 g1001 = rand(float4(xi + 1, yi, zi, wi + 1));
				float4 g0101 = rand(float4(xi, yi + 1, zi, wi + 1));
				float4 g1101 = rand(float4(xi + 1, yi + 1, zi, wi + 1));
				float4 g0011 = rand(float4(xi, yi, zi + 1, wi + 1));
				float4 g1011 = rand(float4(xi + 1, yi, zi + 1, wi + 1));
				float4 g0111 = rand(float4(xi, yi + 1, zi + 1, wi + 1));
				float4 g1111 = rand(float4(xi + 1, yi + 1, zi + 1, wi + 1));

				float4 p0000 = f - float4(0, 0, 0, 0);
				float4 p1000 = f - float4(1, 0, 0, 0);
				float4 p0100 = f - float4(0, 1, 0, 0);
				float4 p1100 = f - float4(1, 1, 0, 0);
				float4 p0010 = f - float4(0, 0, 1, 0);
				float4 p1010 = f - float4(1, 0, 1, 0);
				float4 p0110 = f - float4(0, 1, 1, 0);
				float4 p1110 = f - float4(1, 1, 1, 0);
				float4 p0001 = f - float4(0, 0, 0, 1);
				float4 p1001 = f - float4(1, 0, 0, 1);
				float4 p0101 = f - float4(0, 1, 0, 1);
				float4 p1101 = f - float4(1, 1, 0, 1);
				float4 p0011 = f - float4(0, 0, 1, 1);
				float4 p1011 = f - float4(1, 0, 1, 1);
				float4 p0111 = f - float4(0, 1, 1, 1);
				float4 p1111 = f - float4(1, 1, 1, 1);

				float v0000 = dot(g0000, p0000);
				float v1000 = dot(g1000, p1000);
				float v0100 = dot(g0100, p0100);
				float v1100 = dot(g1100, p1100);
				float v0010 = dot(g0010, p0010);
				float v1010 = dot(g1010, p1010);
				float v0110 = dot(g0110, p0110);
				float v1110 = dot(g1110, p1110);
				float v0001 = dot(g0001, p0001);
				float v1001 = dot(g1001, p1001);
				float v0101 = dot(g0101, p0101);
				float v1101 = dot(g1101, p1101);
				float v0011 = dot(g0011, p0011);
				float v1011 = dot(g1011, p1011);
				float v0111 = dot(g0111, p0111);
				float v1111 = dot(g1111, p1111);

				return
					lerp(
						lerp(
							lerp(lerp(v0000, v1000, xf), lerp(v0100, v1100, xf), yf),
							lerp(lerp(v0010, v1010, xf), lerp(v0110, v1110, xf), yf),
							zf),
						lerp(
							lerp(lerp(v0001, v1001, xf), lerp(v0101, v1101, xf), yf),
							lerp(lerp(v0011, v1011, xf), lerp(v0111, v1111, xf), yf),
							zf),
						wf
					);
			}
        ENDCG
    }
}
