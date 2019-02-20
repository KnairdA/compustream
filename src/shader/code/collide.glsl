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
	return 3*(i+1) + (j+1);
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
	float d = 0.;
	for ( int i = 0; i < q; ++i ) {
		d += collideCells[idx + i];
	}
	return d;
}

vec2 velocity(uint x, uint y, float d) {
	return 1./d * vec2(
		get(x,y, 1, 0) - get(x,y,-1, 0) + get(x,y, 1, 1) - get(x,y,-1,-1) + get(x,y, 1,-1) - get(x,y,-1,1),
		get(x,y, 0, 1) - get(x,y, 0,-1) + get(x,y, 1, 1) - get(x,y,-1,-1) - get(x,y, 1,-1) + get(x,y,-1,1)
	);
}

/// Equilibrium distribution

float equilibrium(float d, vec2 v, int i, int j) {
	return w(i,j) * d * (1 + 3*comp(i,j,v) + 4.5*sq(comp(i,j,v)) - 1.5*sq(norm(v)));
}

/// Determine external influence

float getExternalPressureInflux(uint x, uint y) {
	if ( mouseState == 1 && norm(vec2(x,y) - mousePos) < 4 ) {
		return 1.5;
	} else {
		return 0.0;
	}
}

/// Domain description

bool isEndOfWorld(uint x, uint y) {
	return x == 0 || x == nX-1 || y == 0 || y == nY-1;
}

bool isOuterWall(uint x, uint y) {
	return x == 1 || x == nX-2 || y == 1 || y == nY-2;
}

/// Actual collide kernel

void main() {
	const uint x = gl_GlobalInvocationID.x;
	const uint y = gl_GlobalInvocationID.y;

	if ( !(x < nX && y < nY) ) {
		return;
	}

	if ( isEndOfWorld(x,y) ) {
		return;
	}

	if ( isOuterWall(x,y) ) {
		return;
	}

	const float d = max(getExternalPressureInflux(x,y), density(x,y));
	const vec2  v = velocity(x,y,d);

	setFluid(x,y,v,d);

	for ( int i = -1; i <= 1; ++i ) {
		for ( int j = -1; j <= 1; ++j ) {
			set(x,y,i,j, get(x,y,i,j) + omega * (equilibrium(d,v,i,j) - get(x,y,i,j)));
		}
	}
}
)";
