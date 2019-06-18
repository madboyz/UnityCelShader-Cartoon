Shader "Custom/pikachu"
{
    Properties
    {
        _MainTex("Texture",2D) = "white" {}
        _UnlitColor("Shadow Color",Color) = (0.5,0.5,0.5,1)
        _UnlitThreshold("Shadow Range",Range(0,1)) = 0.1
        _Tint ("Tint",Color) = (1,1,1,1)
        
        _RimLightSampler("Rim sampler",2D) = "white"{}
        _RimColor("Rim Color",Color) = (0.5,0.5,0.5,1)
        _RimIntensity("Rim Intensity",Range(0.0,100)) = 5.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
        LOD 200

        
        Pass {
            Tags { "LightMode" = "ForwardBase"}
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwd_base
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _LightColor0;
            float4 _Tint;
            float4 _UnlitColor;
            float _UnlitThreshold;
            float4 _RimColor;
            float _RimIntensity;
            sampler2D _RimLightSampler;

            struct appdata
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float4 pos: SV_POSITION;
                float4 posWorld: TEXCOORD0;
                float3 normal:TEXCOORD1;
                float2 uv:TEXCOORD2;
                float3 eyeDir:TEXCOORD3;
                float3 lightDir:TEXCOORD4;
                LIGHTING_COORDS(5,6)
            };

            v2f vert(appdata v) {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld,v.vertex);
                o.normal = normalize(mul(float4(v.normal,0.0),unity_WorldToObject).xyz);
                o.eyeDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld).xyz;
                o.lightDir = WorldSpaceLightDir(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag(v2f i):COLOR {
                fixed4 col = tex2D(_MainTex , i.uv)*_Tint;
                float3 normalDirection = normalize(i.normal);
                float3 lightDirection;
                float3 framentColor;

                float att = LIGHT_ATTENUATION(i);
                lightDirection = normalize(_WorldSpaceLightPos0).xyz;
                framentColor = _LightColor0.rgb *_UnlitColor.rgb*_Tint.rgb;
                if(att *max(0.0,dot(normalDirection,lightDirection)) >= _UnlitThreshold)
                {
                    framentColor = _LightColor0.rgb * _Tint.rgb;
                }
                float normalDotEye = dot(i.normal,i.eyeDir.xyz);
                float fall = clamp(1.0 - abs(normalDotEye), 0.2,0.8);
                float rimLightDot = saturate(0.5*(dot(i.normal,i.lightDir + float3(-1,0,0)) + 1.5 ));
                fall = saturate(rimLightDot * fall);
                fall = tex2D(_RimLightSampler,float2(fall,0.25)).r;
                float3 rimCol = fall * col * _RimColor * _RimIntensity;
                return float4(col * framentColor + rimCol , 1.0);
            }

            ENDCG

        }
        
    }
    FallBack "VertexLit"
}
