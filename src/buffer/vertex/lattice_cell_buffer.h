#pragma once

#include <vector>

#include <GL/glew.h>

class LatticeCellBuffer {
private:
	std::vector<GLfloat> _data;

	GLuint _array;
	GLuint _buffer;

public:
	LatticeCellBuffer();
	~LatticeCellBuffer();

	GLuint getBuffer() const;
};
