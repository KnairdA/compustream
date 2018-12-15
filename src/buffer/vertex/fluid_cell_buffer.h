#pragma once

#include <vector>

#include <GL/glew.h>

class FluidCellBuffer {
private:
	std::vector<GLfloat> _data;

	GLuint _array;
	GLuint _buffer;

public:
	FluidCellBuffer();
	~FluidCellBuffer();

	GLuint getBuffer() const;

	void draw() const;
};
