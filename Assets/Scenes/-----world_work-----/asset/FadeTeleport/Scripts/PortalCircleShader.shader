Shader "mmmsys/PortalCircleShader"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _Threshold("Threshold", Range(0,1)) = 0.97
        _Speed("Speed", Range(0,10)) = 1
        _Size("Size", Range(0,10)) = 1
    }
    SubShader
    {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        LOD 200
        CGPROGRAM
        #pragma surface surf Standard alpha:fade
        #pragma target 3.0

        struct Input {
            float3 worldPos;
        };

        fixed4 _Color;
        half _Threshold;
        half _Speed;
        half _Size;

        void surf(Input IN, inout SurfaceOutputStandard o) {
            float3 localPos = IN.worldPos - mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
            float dist = distance(fixed3(0,0,0), localPos);
            float val = abs(sin(dist * 5.0* _Size + _Time * 100* _Speed));
            if (val > _Threshold) {
                o.Albedo = _Color;
                o.Alpha = _Color.a;
            }
            else {
                o.Alpha = 0.f;
            }
        }
    ENDCG
    }
}
