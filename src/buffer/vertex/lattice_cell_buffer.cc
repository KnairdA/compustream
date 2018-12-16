#include "lattice_cell_buffer.h"

#include <fstream>

LatticeCellBuffer::LatticeCellBuffer(GLuint nX, GLuint nY):
	_data(9*nX*nY, GLfloat{1./9.}) {
	glGenVertexArrays(1, &_array);
	glGenBuffers(1, &_buffer);

	const int inset = 0.4*nX;

	for (int x = inset; x < nX-inset; x++) {
		for (int y = inset; y < nY-inset; y++) {
			for ( int i = -1; i <= 1; ++i ) {
				for ( int j = -1; j <= 1; ++j ) {
					_data[9*nX*y + 9*x + (i+1)*3 + j+1] = 1./64.;
				}
			}
		}
	}

	glBindVertexArray(_array);
	glBindBuffer(GL_ARRAY_BUFFER, _buffer);
	glBufferData(
		GL_ARRAY_BUFFER,
		_data.size() * sizeof(GLfloat),
		_data.data(),
		GL_DYNAMIC_DRAW
	);

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 1, GL_FLOAT, GL_FALSE, 0, nullptr);
}

LatticeCellBuffer::~LatticeCellBuffer() {
	glDeleteBuffers(1, &_buffer);
	glDeleteVertexArrays(1, &_array);
}

GLuint LatticeCellBuffer::getBuffer() const {
	return _buffer;
}
