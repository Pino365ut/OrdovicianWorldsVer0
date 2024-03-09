Shader "Noriben/noribenBird"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("Texture(Pigeon)", 2D) = "white" {}
        _MaskTex ("Mask Texture(Pigeon)", 2D) = "white" {}
        _AhoTex ("Texture(Albatross)", 2D) = "white" {}
        _AhoMaskTex ("Mask Texture(Albatross)", 2D) = "white" {}

        [Header(Parameter)]
        _Color ("Base Color", Color) = (1,1,1,1)
        _LightCol ("Light Color Intensity", Range(0, 1)) = 0
        _Cutoff ("Alpha Cutoff", Range(0.001, 1)) = 0.5

        [Space(20)]

        [Enum(Pigeon,0, Albatross,1)]
        _BirdType ("Bird Type", int) = 0

        _Amplify ("Flapping Amplify", Range(0, 2)) = 1
        _FlappingSpeed ("Flapping Speed", Range(0, 20)) = 5
        _BirdPattern ("Bird Tex Intensity", Range(0, 1)) = 0

    }
    SubShader
    {
        Tags { "Queue"="AlphaTest+51" "RenderType"="TransparentCutout"}
        LOD 100
        Cull Off
        
        Pass
        {
            Name "FORWARD"
            Tags {"LightMode"="ForwardBase"}
            AlphaToMask On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR; //頂点カラー
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 vertexColor : COLOR;
                float3 normal : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
            };

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            sampler2D _AhoTex;
            sampler2D _AhoMaskTex;
            float _Amplify;
            float _FlappingSpeed;
            float _BirdPattern;
            float _BirdType;
            float _LightCol;
            float _Cutoff;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

                //羽ばたき
                float vertexCol = v.vertexColor.w;
                float flapTime = sin(_Time.y * (_FlappingSpeed * vertexCol * 1.2) + vertexCol);
                float flapTimeLong = ceil(sin(_Time.y * (1. + vertexCol * 4.) + vertexCol * 2.));
                float flapTimeLong2 = sin(_Time.y * (1. + vertexCol * 4.) + vertexCol * 2.);
                flapTimeLong = lerp(flapTimeLong, flapTimeLong2, .1);
                //flapTime = flapTime * flapTimeLong;
            
                //羽ばたきにおいて、上にあがったときは翼が途中で若干下に折れるように
                //下に下がったときはほどよくカーブして下がるように    
                float gradR = pow(v.uv.x, 5) * flapTime;
                gradR = lerp(gradR, v.uv.x * flapTime - .6, saturate(flapTime));
                float gradL = pow(1.-v.uv.x, 5) * flapTime;
                gradL = lerp(gradL, (1.-v.uv.x) * flapTime, saturate(flapTime));
                //動きをなめらかに
                gradR = lerp(gradR, v.uv.x * flapTime, 0.15);

                //float gradR = pow(v.uv.x, 2.2) * flapTime;
                //float gradL = pow(1.-v.uv.x, 2.2) * flapTime;

                float grad = (gradR + gradL) * _Amplify;
                                            //pigeonの身体部分があまり動かないように
                float bodymaskR = smoothstep(lerp(.57, .52, _BirdType),.75, v.uv);
                float bodymaskL = smoothstep(lerp(.57, .52, _BirdType),.75, 1.-v.uv);
                float bodymask = bodymaskR + bodymaskL;

                v.vertex.y +=  grad * bodymask;

                o.vertexColor = v.vertexColor;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                //ハトのテクスチャ
                fixed4 tex = tex2D(_MainTex, 1.-i.uv);
                float4 maskTex = tex2D(_MaskTex, 1.-i.uv);
                tex = lerp(maskTex, tex, _BirdPattern);

                //アホウドリのテクスチャ
                fixed4 ahoTex = tex2D(_AhoTex, 1.-i.uv);
                float4 ahoMaskTex = tex2D(_AhoMaskTex, 1.-i.uv);
                ahoTex = lerp(ahoMaskTex, ahoTex, _BirdPattern);

                float4 texcol = lerp(tex, ahoTex, _BirdType);
                float4 maskCol = lerp(maskTex, ahoMaskTex, _BirdType);

                //cutoff
                clip(maskCol.x - _Cutoff);

                //ディレクショナルライトの色を受けるかどうか
                float3 LightCol = lerp(1, _LightColor0, _LightCol);

                //環境光(SH9)
                float3 normal = normalize(i.normal);
                float3 ambient = ShadeSH9(float4(normal, 1));

                float3 mainCol = texcol.xyz * i.vertexColor.xyz * _Color * LightCol;
                float3 ambientCol = texcol.xyz * i.vertexColor.xyz * _Color * ambient;

                float4 col = float4(mainCol + ambientCol, maskCol.x);
                col = saturate(col);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                return col;
            }
            ENDCG
            
        }

        //影pass
		Pass 
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile_instancing
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"
            


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR; //頂点カラー 
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			struct v2f 
			{ 
				V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            sampler2D _AhoTex;
            sampler2D _AhoMaskTex;
            float _Amplify;
            float _FlappingSpeed;
            float _BirdPattern;
            float _BirdType;
            float _Cutoff;
	
			v2f vert( appdata v )
			{
				v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

                //羽ばたき
                float vertexCol = v.vertexColor.w;
                float flapTime = sin(_Time.y * (_FlappingSpeed * vertexCol * 1.2) + vertexCol);
                float flapTimeLong = ceil(sin(_Time.y * (1. + vertexCol * 4.) + vertexCol * 2.));
                float flapTimeLong2 = sin(_Time.y * (1. + vertexCol * 4.) + vertexCol * 2.);
                flapTimeLong = lerp(flapTimeLong, flapTimeLong2, .1);
                //flapTime = flapTime * flapTimeLong;
            
                //羽ばたきにおいて、上にあがったときは翼が途中で若干下に折れるように
                //下に下がったときはほどよくカーブして下がるように    
                float gradR = pow(v.uv.x, 5) * flapTime;
                gradR = lerp(gradR, v.uv.x * flapTime - .6, saturate(flapTime));
                float gradL = pow(1.-v.uv.x, 5) * flapTime;
                gradL = lerp(gradL, (1.-v.uv.x) * flapTime, saturate(flapTime));
                //動きをなめらかに
                gradR = lerp(gradR, v.uv.x * flapTime, 0.15);

                //float gradR = pow(v.uv.x, 2.2) * flapTime;
                //float gradL = pow(1.-v.uv.x, 2.2) * flapTime;

                float grad = (gradR + gradL) * _Amplify;
                                            //pigeonの身体部分があまり動かないように
                float bodymaskR = smoothstep(lerp(.57, .52, _BirdType),.75, v.uv);
                float bodymaskL = smoothstep(lerp(.57, .52, _BirdType),.75, 1.-v.uv);
                float bodymask = bodymaskR + bodymaskL;

                v.vertex.y +=  grad * bodymask;

                o.uv = v.uv;
                o.pos = UnityObjectToClipPos(v.vertex);
				TRANSFER_SHADOW_CASTER(o)
				return o;
			}

            
	
			float4 frag( v2f i ) : COLOR
			{
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                //ハトのテクスチャ
                fixed4 tex = tex2D(_MainTex, 1.-i.uv);
                float4 maskTex = tex2D(_MaskTex, 1.-i.uv);
                tex = lerp(maskTex, tex, _BirdPattern);

                //アホウドリのテクスチャ
                fixed4 ahoTex = tex2D(_AhoTex, 1.-i.uv);
                float4 ahoMaskTex = tex2D(_AhoMaskTex, 1.-i.uv);
                ahoTex = lerp(ahoMaskTex, ahoTex, _BirdPattern);

                float4 texcol = lerp(tex, ahoTex, _BirdType);
                float4 maskCol = lerp(maskTex, ahoMaskTex, _BirdType);

                clip(maskCol.x - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
        }
    }
}
