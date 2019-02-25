static const std::string VERTEX_SHADER_CODE = R"(
#version 430

layout (location=0) in vec3 VertexPosition;

out VS_OUT {
	vec3 color;
} vs_out;

uniform uint nX;
uniform uint nY;

const float displayAmplifier = 4.0;

float unit(float x) {
	return 1.0/(1.0+exp(-x));
}

float sq(float x) {
	return x*x;
}

float norm(vec2 v) {
	return sqrt(sq(v.x)+sq(v.y));
}

vec2 fluidVertexAtIndex(uint i) {
	const float y = floor(float(i) / float(nX));
	return vec2(
		i - nX*y,
		y
	);
}

bool isInactive(int material) {
	return material == 0;
}

bool isWallFrontier(int material) {
	return material == 2 || material == 3;
}

void main() {
	const vec2 idx = fluidVertexAtIndex(gl_VertexID);

	gl_Position  = vec4(
		idx.x - nX/2,
		idx.y - nY/2,
		0.,
		1.
	);

	const int material = int(round(VertexPosition.z));

	if ( isInactive(material) ) {
		vs_out.color = vec3(0.5, 0.5, 0.5);
	} else if ( isWallFrontier(material) ) {
		vs_out.color = vec3(0.0, 0.0, 0.0);
	} else {
		vs_out.color = mix(
			vec3(-0.5, 0.0, 1.0),
			vec3( 1.0, 0.0, 0.0),
			displayAmplifier * norm(VertexPosition.xy)
		);
	}
}
)";
