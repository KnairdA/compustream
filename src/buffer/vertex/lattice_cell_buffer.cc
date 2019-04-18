#include "lattice_cell_buffer.h"

#include <vector>

std::vector<GLfloat> makeLattice(GLuint nX, GLuint nY) {
	std::vector<GLfloat> data(9*nX*nY, GLfloat{});

	const GLfloat equilibrium[9] {
		1./36., 1./9., 1./36.,
		1./9. , 4./9., 1./9. ,
		1./36 , 1./9., 1./36.
	};

	for (int i = 0; i < nX*nY; ++i) {
		for (int q = 0; q < 9; ++q) {
			data[9*i+q] = equilibrium[q];
		}
	}

	return data;
}

LatticeCellBuffer::LatticeCellBuffer(GLuint nX, GLuint nY):
	_nX(nX), _nY(nY) {
	glGenBuffers(1, &_buffer);
	init();
}

void LatticeCellBuffer::init() {
	const std::vector<GLfloat> data = makeLattice(_nX, _nY);

	glBindBuffer(GL_ARRAY_BUFFER, _buffer);
	glBufferData(
		GL_ARRAY_BUFFER,
		data.size() * sizeof(GLfloat),
		data.data(),
		GL_DYNAMIC_DRAW
	);
}

LatticeCellBuffer::~LatticeCellBuffer() {
	glDeleteBuffers(1, &_buffer);
}

GLuint LatticeCellBuffer::getBuffer() const {
	return _buffer;
}
