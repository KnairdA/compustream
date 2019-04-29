static const std::string EXTRA_SHADER_CODE = R"(
#version 430

layout (local_size_x = 1, local_size_y = 1) in;

layout (std430, binding=3) buffer bufferFluid { float fluidCells[]; };
layout (std430, binding=4) buffer bufferExtra { float extraCells[]; };

uniform uint nX;
uniform uint nY;

const float convLength = 1.0 / float(max(nX,nY));

/// Array indexing

uint indexOfDirection(int i, int j) {
	return 3*(i+1) + (j+1);
}

uint indexOfFluidVertex(uint x, uint y) {
	return 3*nX*y + 3*x;
}

/// Data access

int getMaterial(uint x, uint y) {
	const uint idx = indexOfFluidVertex(x, y);
	return int(extraCells[idx + 2]);
}

vec2 getFluidVelocity(uint x, uint y) {
	const uint idx = indexOfFluidVertex(x, y);
	return vec2(
		fluidCells[idx + 0],
		fluidCells[idx + 1]
	);
}

void setFluidExtra(uint x, uint y, float curl) {
	const uint idx = indexOfFluidVertex(x, y);
	extraCells[idx + 0] = curl;
}

void main() {
	const uint x = gl_GlobalInvocationID.x;
	const uint y = gl_GlobalInvocationID.y;

	if ( !(x < nX && y < nY) ) {
		return;
	}

	if ( getMaterial(x,y)   != 1
	  || getMaterial(x-1,y) != 1
	  || getMaterial(x+1,y) != 1
	  || getMaterial(x,y-1) != 1
	  || getMaterial(x,y+1) != 1 ) {
		setFluidExtra(x, y,	0.0);
		return;
	}

	// simple central difference discretization of the 2d curl operator
	const float dxvy = (getFluidVelocity(x+1,y).y - getFluidVelocity(x-1,y).y)
	                 / (2*convLength);
	const float dyvx = (getFluidVelocity(x,y+1).x - getFluidVelocity(x,y-1).x)
	                 / (2*convLength);

	setFluidExtra(x, y,	dxvy - dyvx);
}
)";
