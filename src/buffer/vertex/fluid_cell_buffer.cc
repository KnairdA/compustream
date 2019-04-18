#include "fluid_cell_buffer.h"

#include <vector>

FluidCellBuffer::FluidCellBuffer(GLuint nX, GLuint nY, std::function<int(int,int)>&& geometry):
	_nX(nX), _nY(nY) {
	glGenBuffers(1, &_buffer);
	glBindVertexArray(_array);
	init(std::forward<decltype(geometry)>(geometry));
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, nullptr);

}

FluidCellBuffer::~FluidCellBuffer() {
	glDeleteBuffers(1, &_buffer);
	glDeleteVertexArrays(1, &_array);
}

void FluidCellBuffer::init(std::function<int(int,int)>&& geometry) {
	glBindBuffer(GL_ARRAY_BUFFER, _buffer);

	std::vector<GLfloat> data(3*_nX*_nY, GLfloat{});

	for ( int x = 0; x < _nX; ++x ) {
		for ( int y = 0; y < _nY; ++y ) {
			data[3*_nX*y + 3*x + 2] = geometry(x,y);
		}
	}

	glBufferData(
		GL_ARRAY_BUFFER,
		data.size() * sizeof(GLfloat),
		data.data(),
		GL_DYNAMIC_DRAW
	);
}

GLuint FluidCellBuffer::getBuffer() const {
	return _buffer;
}

void FluidCellBuffer::draw() const {
	glBindVertexArray(_array);
	glDrawArrays(GL_POINTS, 0, _nX*_nY);
}
