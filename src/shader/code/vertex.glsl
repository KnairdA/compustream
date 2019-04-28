static const std::string VERTEX_SHADER_CODE = R"(
#version 430

layout (location=0) in vec3 VertexPosition;

out VS_OUT {
	vec3 color;
} vs_out;

uniform uint nX;
uniform uint nY;

uniform bool show_fluid_quality;
uniform bool show_curl;
uniform int  palette_factor;

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
		return min(1.0, quality / palette_factor);
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

vec3 blueBlackRedPalette(float x) {
	if ( x < 0.5 ) {
		return mix(
			vec3(0.0, 0.0, 1.0),
			vec3(0.0, 0.0, 0.0),
			2*x
		);
	} else {
		return mix(
			vec3(0.0, 0.0, 0.0),
			vec3(1.0, 0.0, 0.0),
			2*(x - 0.5)
		);
	}
}

vec3 blackGoldPalette(float x) {
	return mix(
		vec3(0.0, 0.0, 0.0),
		vec3(0.5, 0.35, 0.05),
		x
	);
}

vec3 blueRedPalette(float x) {
	return mix(
		vec3(0.0, 0.0, 1.0),
		vec3(1.0, 0.0, 0.0),
		x
	);
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
		if ( show_fluid_quality ) {
			vs_out.color = trafficLightPalette(
				restrictedQuality(VertexPosition.y)
			);
		} else if ( show_curl ) {
			const float factor = 1.0 / float(100*palette_factor);
			if ( abs(VertexPosition.x) > 1.0 ) {
				vs_out.color = blueBlackRedPalette(
					0.5 + (VertexPosition.x * factor)
				);
			} else {
				vs_out.color = vec3(0.0,0.0,0.0);
			}
		} else {
			vs_out.color = blueRedPalette(
				norm(VertexPosition.xy) / palette_factor
			);
		}
	}
}
)";
