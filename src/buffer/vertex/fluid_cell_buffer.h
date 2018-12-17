#pragma once

#include <GL/glew.h>

class FluidCellBuffer {
private:
	const GLuint _nX;
	const GLuint _nY;

	GLuint _array;
	GLuint _buffer;

public:
	FluidCellBuffer(GLuint nX, GLuint nY);
	~FluidCellBuffer();

	GLuint getBuffer() const;

	void draw() const;
};
