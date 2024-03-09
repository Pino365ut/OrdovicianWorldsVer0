Shader "Noriben/noribenLightShaft"
{
    Properties
    {
        [Header(Main)]
        [HDR]_Color("Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}

        //[Header(Tiling)]
        _TilingX ("Tiling X", Float) = 1
        _TilingY ("Tiling Y", Float) = 1

        [Header(World Position Fade)]
        [Toggle] _FadeOn ("World Position Fade ON", float) = 0
        _WorldPosFade ("World Position Fade Y Height", Float) = 0
        _FadeSoftness ("Fade Softness", Range(0, 10)) = 1

        [Header(Scroll)]
        _Scroll ("Scroll Speed 01", Range(-1, 1)) = 1
        _Scroll2 ("Scroll Speed 02", Range(-1, 1)) = 1

        [Header(Color Effects)]
        _Brightness ("Base Brightness", Range(0, 4)) = 1
        _ColPow ("Gamma", Range(0, 10)) = 1
        _Aberration ("Aberration", Range(0, .05)) = .005
        _SecondMapBrightness ("Second Map Brightness", Range(0, 1)) = 0
        _Flash ("Flash", Range(0, 1)) = 0
        [Header(Mask)]
        _MaskIntensity ("Mask Intensity", Range(0, 1)) = 1
        _MaskGrad ("Mask Gradation", Range(0, 1)) = .5
        _Shape ("Mask Shape(Quad <-> Circle)", Range(0, 1)) = 0

        [Header(Distortion)]
        [HideInInspector][NoScaleOffset]_dTex ("Distortion Texture", 2D) = "white" {}
        [HideInInspector]_Distortion ("Distortion Power", Range(0, 1)) = 1
        [HideInInspector]_DistortionScroll ("Distortion Scroll Speed", Range(-3, 3)) = 0

        [Header(Culling Blend)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Culling", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendSrc("Blend Src", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendDst("Blend Dst", Float) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        LOD 100
        Cull [_Cull]
        //Blend SrcAlpha OneMinusSrcAlpha
        Blend [_BlendSrc][_BlendDst]
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float3 worldPos : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
            };

            float4 _Color;
            sampler2D _MainTex;
            sampler2D _dTex;
            float4 _MainTex_ST;
            float _Distortion;
            float _Scroll;
            float _Aberration;
            float _TilingX;
            float _TilingY;
            float _Shape;
            float _Brightness;
            float _Flash;
            float _ColPow;
            float _Scroll2;
            float _DistortionScroll;
            float _SecondMapBrightness;
            float _MaskIntensity;
            float _MaskGrad;
            float _WorldPosFade;
            float _FadeSoftness;
            float _FadeOn;

            //1D randam
            float rand1d(float t)
            {
                return frac(sin(t) * 100000.);
            }
            
            float noise1d(float t)
            {
                float i = floor(t);
                float f = frac(t);
                return lerp(rand1d(i), rand1d(i + 1.), smoothstep(0., 1., f));
            }

            float remap(float In, float2 InMinMax, float2 OutMinMax)
			{
				return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
			}


            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 vertexColor = i.color;

                float2 uv = i.uv.xy;
                float2 tiling = float2(_TilingX, _TilingY);
                float scrollSpeed = _Scroll;
                float scrollSpeed2 = _Scroll2;

                // Distortion tex
                float4 noiseSpeed = float4(.3, .3, .3, .3) * _DistortionScroll;
                float noise01 = tex2D(_dTex, float2(uv.x + _Time.x * noiseSpeed.x, uv.y)).x;
                float noise02 = tex2D(_dTex, float2(uv.x, uv.y - _Time.x * noiseSpeed.y)).y;
                float noise03 = tex2D(_dTex, uv + _Time.x * noiseSpeed.z).z;
                float noise04 = tex2D(_dTex, uv - _Time.x * noiseSpeed.w).z;

                float4 stimeSpeed = float4(2, 2.1, 2.2, 2.3);
                float stime1 = (sin(_Time.y) + stimeSpeed.x) * .5;
                float stime2 = (sin(_Time.y) + stimeSpeed.y) * .5;
                float stime3 = (sin(_Time.y) + stimeSpeed.z) * .5;
                float stime4 = (sin(_Time.y) + stimeSpeed.w) * .5;

                float mixNoise1 = lerp(noise01, noise02, stime1);
                float mixNoise2 = lerp(noise03, noise04, stime2);
                float mixNoise3 = lerp(noise01, noise03, stime3);
                float mixNoise4 = lerp(noise02, noise04, stime4);

                float mixNoise = (mixNoise1 + mixNoise2 + mixNoise3 + mixNoise4) * .4;
                mixNoise = pow(mixNoise, 1);

                float4 dTex = float4(mixNoise.xxx, 1);



                float distortion = _Distortion;
                float aberration = _Aberration;

                // dUV 01
                float2 dUVR = lerp(uv, dTex.xy, distortion - aberration);
                dUVR.y -= _Time.x * scrollSpeed;
                float2 dUVG = lerp(uv, dTex.xy, distortion);
                dUVG.y -= _Time.x * scrollSpeed;
                float2 dUVB = lerp(uv, dTex.xy, distortion + aberration);
                dUVB.y -= _Time.x * scrollSpeed;

                // dUV 02
                float2 dUVR2 = lerp(uv, dTex.xy, distortion - aberration);
                dUVR2.y -= _Time.x * scrollSpeed2;
                float2 dUVG2 = lerp(uv, dTex.xy, distortion);
                dUVG2.y -= _Time.x * scrollSpeed2;
                float2 dUVB2 = lerp(uv, dTex.xy, distortion + aberration);
                dUVB2.y -= _Time.x * scrollSpeed2;

                //黒枠
                float maskGradQuad = remap(_MaskGrad, float2(0, 1), float2(0.02, 0.49));
                float maskGradCircle = remap(_MaskGrad, float2(0, 1), float2(.49, 0));
                
                float maskQuad = smoothstep(0.02, maskGradQuad, uv.x) * smoothstep(0.02, maskGradQuad, 1.-uv.x)
                            * smoothstep(0.02, maskGradQuad, uv.y) * smoothstep(0.02, maskGradQuad, 1.-uv.y);

                float circleBase = distance(uv, float2(.5, .5));
                float maskCircle = 1.-smoothstep(maskGradCircle, .49, circleBase);

                float Mask = lerp(maskQuad, maskCircle, _Shape);
                Mask = lerp(1, Mask, _MaskIntensity);

                

                //点滅
                float flash = noise1d(_Time.y + pow(mixNoise, 3.));
                flash = lerp(1, flash, _Flash);

                // color 01
                float colR01 = tex2D(_MainTex, dUVR * tiling + vertexColor.a).x * Mask;
                float colG01 = tex2D(_MainTex, dUVG * tiling + vertexColor.a).x * Mask;
                float colB01 = tex2D(_MainTex, dUVB * tiling + vertexColor.a).x * Mask;

                float4 col01 = float4(colR01, colG01, colB01, 1);

                //color 02
                float colR02 = tex2D(_MainTex, (dUVR2 + .3) * tiling + vertexColor.a).x * Mask;
                float colG02 = tex2D(_MainTex, (dUVG2 + .3) * tiling + vertexColor.a).x * Mask;
                float colB02 = tex2D(_MainTex, (dUVB2 + .3) * tiling + vertexColor.a).x * Mask;

                float4 col02 = float4(colR02, colG02, colB02, 1) * _SecondMapBrightness;

                // worldposフェード
                float3 worldPos = i.worldPos;
                float worldPosFade = saturate(smoothstep(0, _FadeSoftness, worldPos.y - _WorldPosFade));
                worldPosFade = lerp(1, worldPosFade, _FadeOn);

                // mix
                float4 col = (col01 + col02) * _Brightness * _Color * flash * vertexColor;

                
                float3 colpow = _ColPow;
                col.xyz = pow(col.xyz, colpow) * worldPosFade;
                col.a = Luminance(col.xyz) * vertexColor.a;


                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
