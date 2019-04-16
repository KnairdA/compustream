static const std::string COLLIDE_SHADER_CODE = R"(
#version 430

layout (local_size_x = 1, local_size_y = 1) in;

layout (std430, binding=1) buffer bufferCollide  { float collideCells[];  };
layout (std430, binding=2) buffer bufferStream   { float streamCells[];   };
layout (std430, binding=3) buffer bufferFluid    { float fluidCells[];    };

uniform uint nX;
uniform uint nY;
uniform uint iT;

uniform bool fluidQuality;

/// Fluid characteristics

const float physCharLength   = 1.0;
const float physCharVelocity = 1.0;
const float physViscosity    = 0.1;

/// LBM constants

const uint  q         = 9;
const float weight[q] = float[](
	1./36., 1./9., 1./36.,
	1./9. , 4./9., 1./9. ,
	1./36 , 1./9., 1./36.
);
const float invCs2 = 1./3.;

const float relaxationTime      = 0.6;
const float relaxationFrequency = 1 / relaxationTime;

/// Unit conversion

const float convLength    = physCharLength / nX;
const float convTime      = (relaxationTime - 0.5) / invCs2 * convLength*convLength / physViscosity;
const float convVelocity  = convLength / convTime;
const float convViscosity = convLength * convLength / convTime;

const float latticeCharVelocity = physCharVelocity / convVelocity;

/// Emergent fluid numbers

const float Re = physCharVelocity * physCharLength / physViscosity;
const float Ma = latticeCharVelocity * sqrt(invCs2);
const float Kn = Ma / Re;

/// Vector utilities

float comp(int i, int j, vec2 v) {
	return i*v.x + j*v.y;
}

float sq(float x) {
	return x*x;
}

float norm(vec2 v) {
	return sqrt(dot(v,v));
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
	streamCells[indexOfLatticeCell(x,y) + indexOfDirection(i,j)] = v;
}

void setFluidVelocity(uint x, uint y, vec2 v) {
	const uint idx = indexOfFluidVertex(x, y);
	fluidCells[idx + 0] = v.x;
	fluidCells[idx + 1] = v.y;
}

void setFluidQuality(uint x, uint y, float knudsen, int quality) {
	const uint idx = indexOfFluidVertex(x, y);
	fluidCells[idx + 0] = knudsen;
	fluidCells[idx + 1] = quality;
}

int getMaterial(uint x, uint y) {
	const uint idx = indexOfFluidVertex(x, y);
	return int(fluidCells[idx + 2]);
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

/// Material number meaning (geometry is only changed by the interaction shader)

bool isBulkFluidCell(int material) {
	return material == 1 || material == 4 || material == 5 || material == 6;
}

bool isBounceBackCell(int material) {
	return material == 2 || material == 3;
}

bool isInflowCell(int material) {
	return material == 5;
}

bool isOutflowCell(int material) {
	return material == 6;
}

float getExternalMassInflux(int material) {
	if ( material == 4 ) {
		return 1.5;
	} else {
		return 0.0;
	}
};

float getLocalKnudsenApproximation(uint x, uint y, float d, vec2 v) {
	float knudsen = 0.0;

	for ( int i = -1; i <= 1; ++i ) {
		for ( int j = -1; j <= 1; ++j ) {
			const float feq  = equilibrium(d,v,i,j);
			const float fneq = get(x,y,i,j) - feq;
			knudsen += abs(fneq / feq);
		}
	}

	return knudsen / q;
}

/// Actual collide&stream kernel

void main() {
	const uint x = gl_GlobalInvocationID.x;
	const uint y = gl_GlobalInvocationID.y;

	if ( !(x < nX && y < nY) ) {
		return;
	}

	const int material = getMaterial(x,y);

	float d = max(density(x,y), getExternalMassInflux(material));
	vec2  v = velocity(x,y,d);

	if ( isBulkFluidCell(material) ) {
		if ( isInflowCell(material) ) {
			d = min(1.0+float(iT)*0.2/1000.0, 1.2);
		}
		if ( isOutflowCell(material) ) {
			d = 1.0;
		}

		if ( fluidQuality ) {
			const float approxKn = getLocalKnudsenApproximation(x,y,d,v);
			setFluidQuality(x,y, approxKn, int(round(log2(approxKn / Kn))));
		} else {
			setFluidVelocity(x,y,v);
		}

		for ( int i = -1; i <= 1; ++i ) {
			for ( int j = -1; j <= 1; ++j ) {
				set(x+i,y+j,i,j,
				    get(x,y,i,j) + relaxationFrequency * (equilibrium(d,v,i,j) - get(x,y,i,j)));
			}
		}
	}

	if ( isBounceBackCell(material) ) {
		for ( int i = -1; i <= 1; ++i ) {
			for ( int j = -1; j <= 1; ++j ) {
				set(x+(-1)*i,y+(-1)*j,(-1)*i,(-1)*j,
				    get(x,y,i,j) + relaxationFrequency * (equilibrium(d,v,i,j) - get(x,y,i,j)));
			}
		}
	}
}
)";
