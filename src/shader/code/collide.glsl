static const std::string COLLIDE_SHADER_CODE = R"(
#version 430

layout (local_size_x = 1, local_size_y = 1) in;

layout (std430, binding=1) buffer bufferCollide{ float collideCells[]; };
layout (std430, binding=2) buffer bufferStream{  float streamCells[]; };
layout (std430, binding=3) buffer bufferFluid{   float fluidCells[]; };

/// external influence

uniform int  mouseState;
uniform vec2 mousePos;

/// LBM constants

uniform uint nX;
uniform uint nY;

const uint  q         = 9;
const float weight[q] = float[](
	1./36., 1./9., 1./36.,
	1./9. , 4./9., 1./9. ,
	1./36 , 1./9., 1./36.
);

const float tau   = 0.8;
const float omega = 1/tau;

/// Vector utilities

float comp(int i, int j, vec2 v) {
	return i*v.x + j*v.y;
}

float sq(float x) {
	return x*x;
}

float norm(vec2 v) {
	return sqrt(sq(v.x)+sq(v.y));
}

/// Array indexing

uint indexOfDirection(int i, int j) {
	return 3*(j+1) + (i+1);
}

uint indexOfLatticeCell(uint x, uint y) {
	return q*nX*y + q*x;
}

uint indexOfFluidVertex(uint x, uint y) {
	return 3*nX*y + 3*x;
}

/// Data access

float w(int i, int j) {
	return weight[indexOfDirection(i,j)];
}

float get(uint x, uint y, int i, int j) {
	return collideCells[indexOfLatticeCell(x,y) + indexOfDirection(i,j)];
}

void set(uint x, uint y, int i, int j, float v) {
	collideCells[indexOfLatticeCell(x,y) + indexOfDirection(i,j)] = v;
}

void setFluid(uint x, uint y, vec2 v, float d) {
	const uint idx = indexOfFluidVertex(x, y);
	fluidCells[idx + 0] = v.x;
	fluidCells[idx + 1] = v.y;
	fluidCells[idx + 2] = d;
}

/// Moments

float density(uint x, uint y) {
	const uint idx = indexOfLatticeCell(x, y);
	return collideCells[idx + 0]
	     + collideCells[idx + 1]
	     + collideCells[idx + 2]
	     + collideCells[idx + 3]
	     + collideCells[idx + 4]
	     + collideCells[idx + 5]
	     + collideCells[idx + 6]
	     + collideCells[idx + 7]
	     + collideCells[idx + 8];
}

vec2 velocity(uint x, uint y, float d) {
	return 1./d * vec2(
		get(x,y, 1, 0) - get(x,y,-1, 0) + get(x,y, 1, 1) - get(x,y,-1,-1) + get(x,y, 1,-1) - get(x,y,-1,1),
		get(x,y, 0, 1) - get(x,y, 0,-1) + get(x,y, 1, 1) - get(x,y,-1,-1) - get(x,y, 1,-1) + get(x,y,-1,1)
	);
}

/// Determine external influence

float getExternalPressureInflux(uint x, uint y) {
	if ( mouseState == 1 && norm(vec2(x,y) - mousePos) < 4 ) {
		return 1.5;
	} else {
		return 0.0;
	}
}

/// Actual collide kernel

void main() {
	const uint x = gl_GlobalInvocationID.x;
	const uint y = gl_GlobalInvocationID.y;

	if ( !(x < nX && y < nY) ) {
		return;
	}

	const float d = max(getExternalPressureInflux(x,y), density(x,y));
	const vec2  v = velocity(x,y,d);

	setFluid(x,y,v,d);

	for ( int i = -1; i <= 1; ++i ) {
		for ( int j = -1; j <= 1; ++j ) {
			const float eq = w(i,j) * d * (1 + 3*comp(i,j,v) + 4.5*sq(comp(i,j,v)) - 1.5*sq(norm(v)));
			set(x,y,i,j, get(x,y,i,j) + omega * (eq - get(x,y,i,j)));
		}
	}
}
)";
