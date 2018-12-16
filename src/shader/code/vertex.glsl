static const std::string VERTEX_SHADER_CODE = R"(
#version 430

layout (location=0) in vec3 VertexPosition;

out VS_OUT {
    vec3 color;
} vs_out;

void main() {
	gl_Position  = vec4(VertexPosition.xy, 0., 1.);
	vs_out.color = vec3(VertexPosition.z, 0., 0.);
}
)";
