Shader "Custom/minecraftShader" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _BlockRU ("BlockRU", 2D) = "white" {}
        _BlockRD ("BlockRD", 2D) = "white" {}
        _BlockGU ("BlockGU", 2D) = "white" {}
        _BlockGD ("BlockGD", 2D) = "white" {}
        _BlockBU ("BlockBU", 2D) = "white" {}
        _BlockBD ("BlockBD", 2D) = "white" {}
        _size ("Size",range(0.0,1.0)) = 0.1
        [IntRange]_pointRate ("PointRate",range(1,100)) = 1
    }
    SubShader {
        Tags { "Queue"="Geometry" "RenderType"="Opaque" }
        LOD 100
        Cull off

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex; float4 _MainTex_ST;
            sampler2D _BlockRU, _BlockRD;
            sampler2D _BlockGU, _BlockGD;
            sampler2D _BlockBU, _BlockBD;
            uniform float4 _col;
            uniform float _size;
            uniform float _pointRate;

            static float3 offset[8] = { float3(-0.5,-0.5,-0.5),
                                        float3(-0.5,-0.5, 0.5),
                                        float3(-0.5, 0.5,-0.5),
                                        float3(-0.5, 0.5, 0.5),
                                        float3( 0.5,-0.5,-0.5),
                                        float3( 0.5,-0.5, 0.5),
                                        float3( 0.5, 0.5,-0.5),
                                        float3( 0.5, 0.5, 0.5),};
            static int4 quads[6] = {int4(3,7,2,6),
                                    int4(0,4,1,5),
                                    int4(2,6,0,4),
                                    int4(6,7,4,5),
                                    int4(7,3,5,1),
                                    int4(3,2,1,0),};
            static float2 uvs[4] = {float2(0,1),
                                    float2(1,1),
                                    float2(0,0),
                                    float2(1,0),};

            struct vinput {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint vid : SV_VertexID;
            };

            struct v2g {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
            };

            struct g2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                int blockR : BLOCKR;
                int blockG : BLOCKG;
                int blockB : BLOCKB;
                int upside : UPSIDE;
            };

            v2g vert (vinput input) {
                v2g output;
                output.vertex = lerp(input.vertex,float4(-1,-1,-1,-1),step(0.5,input.vid%_pointRate));
                //output.vertex = input.vertex;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return output;
            }

            [maxvertexcount(64)]
            void geom(point v2g input[1], inout TriangleStream<g2f> outStream) {
                g2f output;

                fixed4 pointcol = tex2Dlod(_MainTex,float4(input[0].uv,0.0,0.0));
                output.blockR = step(max(pointcol.g,pointcol.b),pointcol.r);
                output.blockG = step(max(pointcol.r,pointcol.b),pointcol.g);
                output.blockB = step(max(pointcol.g,pointcol.r),pointcol.b);

                float3 wpos = mul(UNITY_MATRIX_M,input[0].vertex).xyz;
                wpos = floor(wpos/_size)*_size;

                output.upside = 0;
                [unroll]for(int n=0;n<4;n++){
                    output.vertex = mul(UNITY_MATRIX_VP, float4(wpos+offset[quads[0][n]]*_size,1.0));
                    output.uv = uvs[n];
                    outStream.Append(output);
                }
                outStream.RestartStrip();

                output.upside = 1;
                [unroll]for(int m=1;m<6;m++){
                    [unroll]for(int n=0;n<4;n++){
                        output.vertex = mul(UNITY_MATRIX_VP, float4(wpos+offset[quads[m][n]]*_size,1.0));
                        output.uv = uvs[n];
                        outStream.Append(output);
                    }
                    outStream.RestartStrip();
                }
            }

            fixed4 frag (g2f input) : SV_Target { 
                fixed4 rTex = lerp(tex2D(_BlockRU, input.uv),tex2D(_BlockRD, input.uv),input.upside);
                fixed4 gTex = lerp(tex2D(_BlockGU, input.uv),tex2D(_BlockGD, input.uv),input.upside);
                fixed4 bTex = lerp(tex2D(_BlockBU, input.uv),tex2D(_BlockBD, input.uv),input.upside);
                fixed4 col = rTex*input.blockR + gTex*input.blockG + bTex*input.blockB;
                return col;
            }
            ENDCG
        }
    }
}
