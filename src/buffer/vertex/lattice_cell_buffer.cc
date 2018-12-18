#include "lattice_cell_buffer.h"

#include <vector>

LatticeCellBuffer::LatticeCellBuffer(GLuint nX, GLuint nY) {
	glGenVertexArrays(1, &_array);
	glGenBuffers(1, &_buffer);

	std::vector<GLfloat> data(9*nX*nY, GLfloat{1./9.});
	/*const int insetX = 0.45*nX;
	const int insetY = 0.45*nY;

	for (int x = insetX; x < nX-insetX; x++) {
		for (int y = insetY; y < nY-insetY; y++) {
			for ( int i = -1; i <= 1; ++i ) {
				for ( int j = -1; j <= 1; ++j ) {
					data[9*nX*y + 9*x + (i+1)*3 + j+1] = 0.5;
				}
			}
		}
	}*/

	glBindVertexArray(_array);
	glBindBuffer(GL_ARRAY_BUFFER, _buffer);
	glBufferData(
		GL_ARRAY_BUFFER,
		data.size() * sizeof(GLfloat),
		data.data(),
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
