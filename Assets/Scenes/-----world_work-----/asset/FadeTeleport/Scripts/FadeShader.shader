Shader "mmmsys/FadeShader"
{
    Properties
    {
        _fade("Fade", range(0,1.)) = 0.
    }
    SubShader
    {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent+4000" 
        }
        LOD 100
        ZTest Always
        Cull front
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"
            float _fade;

            fixed4 frag () : SV_Target
            {
                return float4(0, 0, 0, _fade);
            }
            ENDCG
        }
    }
}
