#include <metal_stdlib>
using namespace metal;

// Animated water-flow effect for MOKO dark-mode backgrounds.
// Renders flowing waves/distortion in the upper area with a soft bottom fade.
[[ stitchable ]] half4 mokoWaterFlow(float2 position,
                                     half4 currentColor,
                                     float2 size,
                                     float time,
                                     half4 colorA,
                                     half4 colorB,
                                     half4 accent) {
    if (size.y <= 0.0) { return currentColor; }

    float2 uv = position / size;
    // Focus motion in the upper half and fade out toward the middle.
    float verticalMask = 1.0 - smoothstep(0.05, 0.58, uv.y);

    float drift = time * 0.22;
    float wave1 = sin((uv.x * 7.0) + drift * 2.4 + (uv.y * 5.0));
    float wave2 = cos((uv.x * 13.0) - drift * 1.8 + (uv.y * 7.0));
    float wave3 = sin(((uv.x + uv.y * 1.3) * 9.0) + drift * 1.2);
    float flow = (wave1 * 0.45 + wave2 * 0.35 + wave3 * 0.20);

    float distortion = sin((uv.y * 16.0) + flow * 1.4 + drift * 1.6) * 0.03;
    float bands = 0.5 + 0.5 * sin((uv.x * 10.0 + distortion * 18.0) + drift * 2.0 + flow);
    float caustic = 0.5 + 0.5 * sin((uv.x * 4.5 - uv.y * 6.0) - drift * 1.3 + flow * 1.5);

    float t = clamp(bands * 0.6 + caustic * 0.4, 0.0, 1.0);
    half3 base = mix(colorA.rgb, colorB.rgb, half(t));
    half highlight = half(0.18 + 0.22 * caustic) * half(0.6 + 0.4 * (0.5 + 0.5 * flow));
    base += accent.rgb * highlight;

    half alpha = half(0.42 * verticalMask) * half(0.75 + 0.25 * bands);
    half4 effect = half4(base, alpha);
    // Composite over the existing background color.
    return half4(mix(currentColor.rgb, effect.rgb, effect.a), 1.0h);
}
