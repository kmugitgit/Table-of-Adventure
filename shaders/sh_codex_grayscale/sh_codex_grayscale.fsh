varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_collected;
void main()
{
    vec4 colour = texture2D(gm_BaseTexture, v_vTexcoord) * v_vColour;
    float grey = dot(colour.rgb, vec3(0.299, 0.587, 0.114));
    gl_FragColor = vec4(mix(vec3(grey), colour.rgb, u_collected), colour.a);
}
