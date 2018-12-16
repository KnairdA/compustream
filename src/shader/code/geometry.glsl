static const std::string GEOMETRY_SHADER_CODE = R"(
#version 430

layout (points) in;
layout (triangle_strip, max_vertices=4) out;

uniform mat4 MVP;

in VS_OUT {
	vec3 color;
} gs_in[];

out vec3 color;

vec4 project(vec4 v) {
	return MVP * v;
}

void emitSquareAt(vec4 position) {
	const float size = 0.2;

	gl_Position = project(position + vec4(-size, -size, 0.0, 0.0));
	EmitVertex();
	gl_Position = project(position + vec4( size, -size, 0.0, 0.0));
	EmitVertex();
	gl_Position = project(position + vec4(-size,  size, 0.0, 0.0));
	EmitVertex();
	gl_Position = project(position + vec4( size,  size, 0.0, 0.0));
	EmitVertex();
}

void main() {
	color = gs_in[0].color;
	emitSquareAt(gl_in[0].gl_Position);
	EndPrimitive();
}
)";
