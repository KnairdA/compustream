static const std::string COLLIDE_SHADER_CODE = R"(
#version 430

layout (local_size_x = 1, local_size_y = 1) in;

layout (std430, binding=1) buffer bufferCollide  { float collideCells[];  };
layout (std430, binding=2) buffer bufferStream   { float streamCells[];   };
layout (std430, binding=3) buffer bufferFluid    { float fluidCells[];    };
layout (std430, binding=4) buffer bufferGeometry { int   materialCells[]; };

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

int getMaterial(uint x, uint y) {
	return materialCells[nX*y + x];
}

void setMaterial(uint x, uint y, int m) {
	materialCells[nX*y + x] = m;
}

void disableFluid(uint x, uint y) {
	const uint idx = indexOfFluidVertex(x, y);
	fluidCells[idx + 0] = 0.0;
	fluidCells[idx + 1] = 0.0;
	fluidCells[idx + 2] = -2.0;
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
	if ( mouseState == 1 && norm(vec2(x,y) - mousePos) < 2 ) {
		return 1.5;
	} else {
		return 0.0;
	}
}

bool getExternalWallRequest(uint x, uint y) {
	if ( mouseState == 2 && norm(vec2(x,y) - mousePos) < 4 ) {
		return true;
	} else {
		return false;
	}
}

/// Actual collide kernel

void main() {
	const uint x = gl_GlobalInvocationID.x;
	const uint y = gl_GlobalInvocationID.y;

	if ( !(x < nX && y < nY) ) {
		return;
	}

	if ( getExternalWallRequest(x,y) ) {
		setMaterial(x,y,2);
		disableFluid(x,y);
	}

	const int material = getMaterial(x,y);

	if ( material == 2 ) {
		int wallNeighbors = 0;
		for ( int i = -1; i <= 1; ++i ) {
			for ( int j = -1; j <= 1; ++j ) {
				const int material = getMaterial(x+i,y+j);
				if ( material  == 0 || material == 2 ) {
					++wallNeighbors;
				}
			}
		}
		if ( wallNeighbors == 9 ) {
			setMaterial(x,y,0);
		}
	}

	if ( material == 1 ) { // fluid
		const float d = max(getExternalPressureInflux(x,y), density(x,y));
		const vec2  v = velocity(x,y,d);

		setFluid(x,y,v,d);

		for ( int i = -1; i <= 1; ++i ) {
			for ( int j = -1; j <= 1; ++j ) {
				set(x,y,i,j, get(x,y,i,j) + omega * (equilibrium(d,v,i,j) - get(x,y,i,j)));
			}
		}
	}
}
)";
