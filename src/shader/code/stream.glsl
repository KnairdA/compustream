static const std::string STREAM_SHADER_CODE = R"(
#version 430

layout (local_size_x = 1, local_size_y = 1) in;
layout (std430, binding=1) buffer bufferCollide{ float collideCells[]; };
layout (std430, binding=2) buffer bufferStream{  float streamCells[]; };

float get(uint x, uint y, int i, int j) {
	return collideCells[9*128*y + 9*x + (i+1)*3 + j+1];
}

void set(uint x, uint y, int i, int j, float v) {
	streamCells[9*128*y + 9*x + (i+1)*3 + j+1] = v;
}

void main() {
	const uint x = gl_GlobalInvocationID.x;
	const uint y = gl_GlobalInvocationID.y;

	if ( x != 0 && x != 128-1 && y != 0 && y != 128-1 ) {
		for ( int i = -1; i <= 1; ++i ) {
			for ( int j = -1; j <= 1; ++j ) {
				set(x+i,y+j,i,j, get(x,y,i,j));
			}
		}
	} else {

	}
}
)";
