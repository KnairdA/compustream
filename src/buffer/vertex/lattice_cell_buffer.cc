#include "lattice_cell_buffer.h"

#include <fstream>

LatticeCellBuffer::LatticeCellBuffer():
	_data(9*128*128, GLfloat{1./9.}) {
	glGenVertexArrays(1, &_array);
	glGenBuffers(1, &_buffer);

	for (int x = 50; x < 128-50; x++) {
		for (int y = 50; y < 128-50; y++) {
			for ( int i = -1; i <= 1; ++i ) {
				for ( int j = -1; j <= 1; ++j ) {
					_data[9*128*y + 9*x + (i+1)*3 + j+1] = 1./128.;
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
