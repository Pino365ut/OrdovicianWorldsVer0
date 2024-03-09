Shader "Pya/RaymarchSky"
{
	Properties
	{
		[MaterialToggle] _IsDisplay ("Display Object", Float) = 1 
		[NoScaleOffset] _FrontTex ("Front [+Z]", 2D) = "grey" {}
		[NoScaleOffset] _BackTex ("Back [-Z]", 2D) = "grey" {}
		[NoScaleOffset] _LeftTex ("Left [+X]", 2D) = "grey" {}
		[NoScaleOffset] _RightTex ("Right [-X]", 2D) = "grey" {}
		[NoScaleOffset] _UpTex ("Up [+Y]", 2D) = "grey" {}
		[NoScaleOffset] _DownTex ("Down [-Y]", 2D) = "grey" {}
		_Scale("SkyBox Scale", Float) = 50.0
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque"  "LightMode" = "ForwardBase" }
		LOD 100

		Cull Front

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag


			#include "UnityCG.cginc"

			#define RAY_LOOP  30

			#define SKB_FRONT 1.0
			#define SKB_BACK  2.0
			#define SKB_LEFT  3.0
			#define SKB_RIGHT 4.0
			#define SKB_UP    5.0
			#define SKB_DOWN  6.0

			float _IsDisplay;
			sampler2D _FrontTex;
			sampler2D _BackTex;
			sampler2D _LeftTex;
			sampler2D _RightTex;
			sampler2D _UpTex;
			sampler2D _DownTex;
			float _Scale;

            //カメラとオブジェクトの距離を計算
			float3 CalcDistance() {
				float3 objPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
				return abs(objPos - _WorldSpaceCameraPos);
			}

			float2x2 rot(float r) {
				float2x2 m = float2x2(cos(r),sin(r),-sin(r),cos(r));
				return m;
			}

			float2 opU(float2 d1, float2 d2)
			{
				return (d1.x<d2.x) ? d1 : d2;
			}

			float box(float3 p, float3 b) {
				float3 d = abs(p) - b;
				return length(max(d, 0.0));
			}

			float2 dist(float3 p, float SkyboxScale, float3 ObjScale) {
				float2 d1,d2,d3,d4,d5,d6;
				float3 p1,p2,p3,p4,p5,p6;
				float2 result;
				float maxsize = max(ObjScale.x, max(ObjScale.y, ObjScale.z));
				float minsize = min(ObjScale.x, min(ObjScale.y, ObjScale.z));

				//FrontTex
				p1 = p;
				p1.z = p1.z - SkyboxScale * (maxsize / ObjScale.z);
			    d1 = float2(box(p1, float3(1.0 * SkyboxScale * (maxsize / minsize), 1.0 * SkyboxScale * (maxsize / minsize), 0.001)), SKB_FRONT);

				//BackTex
				p2 = p;
				p2.z = p2.z + SkyboxScale * (maxsize / ObjScale.z);
				d2 = float2(box(p2, float3(1.0 * SkyboxScale * (maxsize / minsize), 1.0 * SkyboxScale * (maxsize / minsize), 0.001)), SKB_BACK);

				//LeftTex
				p3 = p;
				p3.x = p3.x - SkyboxScale * (maxsize / ObjScale.x);
				p3.xz = mul(p3.xz, rot(UNITY_PI * 90 / 180));
				d3 = float2(box(p3, float3(1.0 * SkyboxScale * (maxsize / ObjScale.z), 1.0 * SkyboxScale * (maxsize / minsize), 0.001)), SKB_LEFT);

				//RightTex
				p4 = p;
				p4.x = p4.x + SkyboxScale * (maxsize / ObjScale.x);
				p4.xz = mul(p4.xz, rot(UNITY_PI * 90 / 180));
				d4 = float2(box(p4, float3(1.0 * SkyboxScale * (maxsize / ObjScale.z), 1.0 * SkyboxScale * (maxsize / minsize), 0.001)), SKB_RIGHT);

				//UpTex
				p5 = p;
				p5.y = p5.y - SkyboxScale * (maxsize / ObjScale.y);
				p5.xz = mul(p5.yz, rot(UNITY_PI * 90 / 180));
				d5 = float2(box(p5, float3(1.0 * SkyboxScale * (maxsize / ObjScale.z), 1.0 * SkyboxScale * (maxsize / ObjScale.x), 0.001)), SKB_UP);

				//DownTex
				p6 = p;
				p6.y = p6.y + SkyboxScale * (maxsize / ObjScale.y);
				p6.xz = mul(p6.yz, rot(UNITY_PI * 90 / 180));
				d6 = float2(box(p6, float3(1.0 * SkyboxScale * (maxsize / ObjScale.z), 1.0 * SkyboxScale * (maxsize / ObjScale.x), 0.001)), SKB_DOWN);


				result = d1;
				result.x = min(result, d2);
				result = opU(result, d2);
				result.x = min(result, d3);
				result = opU(result, d3);
				result.x = min(result, d4);
				result = opU(result, d4);
				result.x = min(result, d5);
				result = opU(result, d5);
				result.x = min(result, d6);
				result = opU(result, d6);

				return result;
			
			}

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 pos: TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos = v.vertex;
				o.uv = v.uv;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 col = 0;

				//オブジェクトとカメラ距離を取得
				float3 distance = CalcDistance();

				//オブジェクトのスケールを取得
				float3 ObjScale;
				ObjScale.x = 1/sqrt(pow(unity_WorldToObject[0].x, 2) + pow(unity_WorldToObject[0].y, 2) + pow(unity_WorldToObject[0].z, 2));
				ObjScale.y = 1/sqrt(pow(unity_WorldToObject[1].x, 2) + pow(unity_WorldToObject[1].y, 2) + pow(unity_WorldToObject[1].z, 2));
				ObjScale.z = 1/sqrt(pow(unity_WorldToObject[2].x, 2) + pow(unity_WorldToObject[2].y, 2) + pow(unity_WorldToObject[2].z, 2));

				//Skybox表示がON もしくは カメラがオブジェクト内にある場合描画
				if (_IsDisplay || (distance.x <= ObjScale.x/2 && distance.y <= ObjScale.y/2 && distance.z <= ObjScale.z/2)) {

					float maxsize = max(ObjScale.x, max(ObjScale.y, ObjScale.z));
					float SkyboxScale = _Scale;

					float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;
					float3 rd = normalize(i.pos.xyz - mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz);
					float2 d;
					float3 p = 0.0;
					float t = 0.001;

					[unroll]
					for (int i = 0; i < RAY_LOOP; i++) {
						p = ro + rd * t;
						d = dist(p, SkyboxScale, ObjScale);

						t += d.x * 1.0;
						if (t > 1000.0) {break;}
					}

					if (d.x > 0.01) {
						discard;
					} else {
						float texscale = 1.0/(SkyboxScale * 2 * maxsize);
						float3 maintex;
						if (d.y == SKB_FRONT) {
							maintex = tex2D(_FrontTex, float2((p.x*ObjScale.x+SkyboxScale*maxsize) * texscale, (p.y*ObjScale.y+SkyboxScale*maxsize) * texscale));
							col = maintex;
						} else if(d.y == SKB_BACK) {
							p.x = SkyboxScale - (p.x + SkyboxScale);
							maintex = tex2D(_BackTex, float2((p.x*ObjScale.x+SkyboxScale*maxsize) * texscale, (p.y*ObjScale.y+SkyboxScale*maxsize) * texscale));
							col = maintex;
						} else if (d.y == SKB_LEFT) {
							p.z = SkyboxScale - (p.z + SkyboxScale);
							maintex = tex2D(_LeftTex, float2((p.z*ObjScale.z+SkyboxScale*maxsize) * texscale, (p.y*ObjScale.y+SkyboxScale*maxsize) * texscale));
							col = maintex;
						} else if (d.y == SKB_RIGHT) {
							maintex = tex2D(_RightTex, float2((p.z*ObjScale.z+SkyboxScale * maxsize) * texscale, (p.y*ObjScale.y+SkyboxScale*maxsize) * texscale));
							col = maintex;
						} else if (d.y == SKB_UP) {
							p.z = SkyboxScale - (p.z + SkyboxScale);
							maintex = tex2D(_UpTex, float2((p.x*ObjScale.x+SkyboxScale*maxsize) * texscale, (p.z*ObjScale.z+SkyboxScale*maxsize) * texscale));
							col = maintex;
						} else if (d.y == SKB_DOWN) {
							maintex = tex2D(_DownTex, float2((p.x*ObjScale.x+SkyboxScale*maxsize) * texscale, (p.z*ObjScale.z+SkyboxScale*maxsize) * texscale));
							col = maintex;
						}
					}
				} else {
					discard;
				}

				return fixed4(col, 1);
			}
			ENDCG
		}
	}
}