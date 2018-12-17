static const std::string VERTEX_SHADER_CODE = R"(
#version 430

layout (location=0) in vec3 VertexPosition;

out VS_OUT {
	vec3 color;
} vs_out;

float unit(float x) {
	return 1.0/(1.0+exp(-x));
}

vec3 getColor(float x) {
	return x*vec3(1.0,0.0,0.0) + (1-x)*vec3(-0.5,0.0,1.0);
}

void main() {
	gl_Position  = vec4(VertexPosition.xy, 0., 1.);
	vs_out.color = getColor(unit(VertexPosition.z));
}
)";
