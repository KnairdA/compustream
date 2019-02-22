#include "material_buffer.h"

#include <vector>

MaterialBuffer::MaterialBuffer(GLuint nX, GLuint nY):
	_nX(nX), _nY(nY) {
	glGenVertexArrays(1, &_array);
	glGenBuffers(1, &_buffer);

	glBindVertexArray(_array);
	glBindBuffer(GL_ARRAY_BUFFER, _buffer);

	std::vector<GLint> data(nX*nY, GLint{1});

	for ( int x = 0; x < nX; ++x ) {
		data[     0*nX + x] = 0;
		data[(nY-1)*nX + x] = 0;
	}
	for ( int y = 0; y < nY; ++y ) {
		data[y*nX +    0] = 0;
		data[y*nX + nX-1] = 0;
	}

	for ( int x = 1; x < nX-1; ++x ) {
		data[     1*nX + x] = 2;
		data[(nY-2)*nX + x] = 2;
	}
	for ( int y = 1; y < nY-1; ++y ) {
		data[y*nX +    1] = 2;
		data[y*nX + nX-2] = 2;
	}

	glBufferData(
		GL_ARRAY_BUFFER,
		data.size() * sizeof(GLint),
		data.data(),
		GL_STATIC_DRAW
	);

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 1, GL_INT, GL_FALSE, 0, nullptr);
}

MaterialBuffer::~MaterialBuffer() {
	glDeleteBuffers(1, &_buffer);
	glDeleteVertexArrays(1, &_array);
}

GLuint MaterialBuffer::getBuffer() const {
	return _buffer;
}
