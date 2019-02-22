#include "material_buffer.h"

#include <vector>

MaterialBuffer::MaterialBuffer(GLuint nX, GLuint nY, std::function<int(int,int)>&& geometry):
	_nX(nX), _nY(nY) {
	glGenVertexArrays(1, &_array);
	glGenBuffers(1, &_buffer);

	glBindVertexArray(_array);
	glBindBuffer(GL_ARRAY_BUFFER, _buffer);

	std::vector<GLint> data(nX*nY, GLint{1});

	for ( int x = 0; x < nX; ++x ) {
		for ( int y = 0; y < nY; ++y ) {
			data[y*nX + x] = geometry(x,y);
		}
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
