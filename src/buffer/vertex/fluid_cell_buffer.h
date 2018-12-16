#pragma once

#include <vector>

#include <GL/glew.h>

class FluidCellBuffer {
private:
	std::vector<GLfloat> _data;

	GLuint _array;
	GLuint _buffer;

public:
	FluidCellBuffer(GLuint nX, GLuint nY);
	~FluidCellBuffer();

	GLuint getBuffer() const;

	void draw() const;
};
