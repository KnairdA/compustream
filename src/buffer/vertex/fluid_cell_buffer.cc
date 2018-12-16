#include "fluid_cell_buffer.h"

FluidCellBuffer::FluidCellBuffer(GLuint nX, GLuint nY):
	_data(3*nX*nY, GLfloat{}) {
	glGenVertexArrays(1, &_array);
	glGenBuffers(1, &_buffer);

	glBindVertexArray(_array);
	glBindBuffer(GL_ARRAY_BUFFER, _buffer);
	glBufferData(
		GL_ARRAY_BUFFER,
		_data.size() * sizeof(GLfloat),
		_data.data(),
		GL_DYNAMIC_DRAW
	);

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, nullptr);
}

FluidCellBuffer::~FluidCellBuffer() {
	glDeleteBuffers(1, &_buffer);
	glDeleteVertexArrays(1, &_array);
}

GLuint FluidCellBuffer::getBuffer() const {
	return _buffer;
}

void FluidCellBuffer::draw() const {
	glBindVertexArray(_array);
	glDrawArrays(GL_POINTS, 0, _data.size());
}
