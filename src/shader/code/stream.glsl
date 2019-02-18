static const std::string STREAM_SHADER_CODE = R"(
#version 430

layout (local_size_x = 1, local_size_y = 1) in;

layout (std430, binding=1) buffer bufferCollide{ float collideCells[]; };
layout (std430, binding=2) buffer bufferStream{  float streamCells[]; };

/// LBM constants

uniform uint nX;
uniform uint nY;

const uint q = 9;

// Array indexing

uint indexOfDirection(int i, int j) {
	return 3*(i+1) + (j+1);
}

uint indexOfLatticeCell(uint x, uint y) {
	return q*nX*y + q*x;
}

/// Data access

float get(uint x, uint y, int i, int j) {
	return collideCells[indexOfLatticeCell(x,y) + indexOfDirection(i,j)];
}

void set(uint x, uint y, int i, int j, float v) {
	streamCells[indexOfLatticeCell(x,y) + indexOfDirection(i,j)] = v;
}

/// Actual stream kernel

void main() {
	const uint x = gl_GlobalInvocationID.x;
	const uint y = gl_GlobalInvocationID.y;

	if ( !(x < nX && y < nY) ) {
		return;
	}

	if ( x != 0 && x != nX-1 && y != 0 && y != nY-1 ) {
		for ( int i = -1; i <= 1; ++i ) {
			for ( int j = -1; j <= 1; ++j ) {
				set(x+i,y+j,i,j, get(x,y,i,j));
			}
		}
	} else {
		// rudimentary bounce back boundary handling
		for ( int i = -1; i <= 1; ++i ) {
			for ( int j = -1; j <= 1; ++j ) {
				if ( (x > 0 || i >= 0) && x+i <= nX-1 && (y > 0 || j >= 0) && y+j <= nY-1 ) {
					set(x+i,y+j,i,j, get(x,y,i,j));
				} else {
					set(x,y,i*(-1),j*(-1), get(x,y,i,j));
				}
			}
		}
	}
}
)";
