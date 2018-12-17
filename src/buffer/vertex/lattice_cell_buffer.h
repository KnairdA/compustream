#pragma once

#include <GL/glew.h>

class LatticeCellBuffer {
private:
	GLuint _array;
	GLuint _buffer;

public:
	LatticeCellBuffer(GLuint nX, GLuint nY);
	~LatticeCellBuffer();

	GLuint getBuffer() const;
};
