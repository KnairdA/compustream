static const std::string VERTEX_SHADER_CODE = R"(
#version 430

layout (location=0) in vec3 VertexPosition;

out VS_OUT {
	vec3 color;
} vs_out;

uniform uint nX;
uniform uint nY;

uniform bool fluidQuality;

const float velocityDisplayAmplifier = 3.0;
const int   qualityDisplayRestrictor = 6;

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

float restrictedQuality(float quality) {
	if ( quality < 0.0 ) {
		return 0.0;
	} else {
		return min(1.0, quality / qualityDisplayRestrictor);
	}
}

vec3 trafficLightPalette(float x) {
	if ( x < 0.5 ) {
		return mix(
			vec3(0.0, 1.0, 0.0),
			vec3(1.0, 1.0, 0.0),
			2*x
		);
	} else {
		return mix(
			vec3(1.0, 1.0, 0.0),
			vec3(1.0, 0.0, 0.0),
			2*(x - 0.5)
		);
	}
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
		if ( fluidQuality ) {
			vs_out.color = trafficLightPalette(restrictedQuality(VertexPosition.y));
		} else {
			vs_out.color = mix(
				vec3(-0.5, 0.0, 1.0),
				vec3( 1.0, 0.0, 0.0),
				velocityDisplayAmplifier * norm(VertexPosition.xy)
			);
		}
	}
}
)";
