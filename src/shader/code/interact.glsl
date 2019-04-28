static const std::string INTERACT_SHADER_CODE = R"(
#version 430

layout (local_size_x = 1, local_size_y = 1) in;

layout (std430, binding=3) buffer bufferFluid { float fluidCells[]; };
layout (std430, binding=4) buffer bufferExtra { float extraCells[]; };

uniform uint nX;
uniform uint nY;

/// External influence

uniform bool wall_requested;
uniform bool fluid_requested;

uniform vec2 start;
uniform vec2 end;

/// Vector utilities

float norm(vec2 v) {
	return sqrt(dot(v,v));
}

float distanceToLineSegment(vec2 a, vec2 b, vec2 p) {
	const vec2 ab = b - a;

	const vec2 pa = a - p;
	if ( dot(ab, pa) > 0.0 ) {
		return norm(pa);
	}

	const vec2 bp = p - b;
	if ( dot(ab, bp) > 0.0 ) {
		return norm(bp);
	}

	return norm(pa - ab * (dot(ab, pa) / dot(ab, ab)));
}

bool isNearLine(uint x, uint y, float eps) {
	if ( start == end ) {
		return norm(vec2(x,y) - end) < eps;
	} else {
		return distanceToLineSegment(start, end, vec2(x,y)) < eps;
	}
}

/// Array indexing

uint indexOfFluidVertex(uint x, uint y) {
	return 3*nX*y + 3*x;
}

/// Data access

int getMaterial(uint x, uint y) {
	const uint idx = indexOfFluidVertex(x, y);
	return int(fluidCells[idx + 2]);
}

void setMaterial(uint x, uint y, int m) {
	const uint idx = indexOfFluidVertex(x, y);
	fluidCells[idx + 2] = m;
	extraCells[idx + 2] = m;
}

/// Geometry cleanup

void disableWallInterior(uint x, uint y) {
	int wallNeighbors = 0;

	for ( int i = -1; i <= 1; ++i ) {
		for ( int j = -1; j <= 1; ++j ) {
			const int material = getMaterial(x+i,y+j);
			if ( material  == 0 || material == 2 || material == 3 ) {
				++wallNeighbors;
			}
		}
	}

	if ( wallNeighbors == 9 ) {
		setMaterial(x,y,0);
	}
}

void fixWallExterior(uint x, uint y) {
	for ( int i = -1; i <= 1; ++i ) {
		for ( int j = -1; j <= 1; ++j ) {
			if ( getMaterial(x+i,y+j)== 0 ) {
				setMaterial(x+i,y+j,3);
			}
		}
	}
}

/// Actual interaction kernel

void main() {
	const uint x = gl_GlobalInvocationID.x;
	const uint y = gl_GlobalInvocationID.y;

	if ( !(x < nX && y < nY) ) {
		return;
	}

	const int material = getMaterial(x,y);

	if ( material == 1 ) {
		if ( isNearLine(x, y, 3) ) {
			if ( wall_requested ) {
				setMaterial(x,y,3);
				return;
			}
		}
	}

	if ( material == 0 || material == 3 ) {
		if ( fluid_requested ) {
			if ( isNearLine(x, y, 3) ) {
					setMaterial(x,y,1);
					fixWallExterior(x,y);
					return;
			}
		}
	}


	if ( material == 3 ) {
		disableWallInterior(x,y);
	}
}
)";
