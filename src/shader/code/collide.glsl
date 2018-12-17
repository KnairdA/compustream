static const std::string COLLIDE_SHADER_CODE = R"(
#version 430

layout (local_size_x = 1, local_size_y = 1) in;

layout (std430, binding=1) buffer bufferCollide{ float collideCells[]; };
layout (std430, binding=2) buffer bufferStream{  float streamCells[]; };
layout (std430, binding=3) buffer bufferFluid{   float fluidCells[]; };

uniform uint nX;
uniform uint nY;

const uint  q     = 9;
const float omega = 0.6;

const float displayAmplifier = 10.;

float comp(int x, int y, vec2 v) {
	return x*v.x + y*v.y;
}

float sq(float x) {
	return x*x;
}

float norm(vec2 v) {
	return sqrt(sq(v.x)+sq(v.y));
}

float get(uint x, uint y, int i, int j) {
	return collideCells[q*nX*y + q*x + (i+1)*3 + j+1];
}

void set(uint x, uint y, int i, int j, float v) {
	collideCells[q*nX*y + q*x + (i+1)*3 + j+1] = v;
}

void setFluid(uint x, uint y, vec2 v, float d) {
	fluidCells[3*nX*y + 3*x + 0] = float(x)-nX/2;// + displayAmplifier*v.x;
	fluidCells[3*nX*y + 3*x + 1] = float(y)-nY/2;// + displayAmplifier*v.y;
	fluidCells[3*nX*y + 3*x + 2] = displayAmplifier * norm(v);
}

float density(uint x, uint y) {
	return collideCells[q*nX*y + q*x + 0]
	     + collideCells[q*nX*y + q*x + 1]
	     + collideCells[q*nX*y + q*x + 2]
	     + collideCells[q*nX*y + q*x + 3]
	     + collideCells[q*nX*y + q*x + 4]
	     + collideCells[q*nX*y + q*x + 5]
	     + collideCells[q*nX*y + q*x + 6]
	     + collideCells[q*nX*y + q*x + 7]
	     + collideCells[q*nX*y + q*x + 8];
}

vec2 velocity(uint x, uint y, float d) {
	return 1./d * vec2(
		get(x,y, 1, 0) - get(x,y,-1, 0) + get(x,y, 1, 1) - get(x,y,-1,-1) + get(x,y, 1,-1) - get(x,y,-1,1),
		get(x,y, 0, 1) - get(x,y, 0,-1) + get(x,y, 1, 1) - get(x,y,-1,-1) - get(x,y, 1,-1) + get(x,y,-1,1)
	);
}

float w(int i, int j) {
	if ( i == -1 ) {
		if ( j != 0 ) {
			return 1./36.;
		} else {
			return 1./9.;
		}
	} else if ( i == 0 ) {
		if ( j != 0 ) {
			return 1./9.;
		} else {
			return 4./9.;
		}
	} else {
		if ( j != 0 ) {
			return 1./36.;
		} else {
			return 1./9.;
		}
	}
}

void main() {
	const uint x = gl_GlobalInvocationID.x;
	const uint y = gl_GlobalInvocationID.y;

	const float d = density(x,y);
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
