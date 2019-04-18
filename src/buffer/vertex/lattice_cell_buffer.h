#pragma once

#include <GL/glew.h>

class LatticeCellBuffer {
private:
	GLuint _nX;
	GLuint _nY;
	GLuint _array;
	GLuint _buffer;

public:
	LatticeCellBuffer(GLuint nX, GLuint nY);
	~LatticeCellBuffer();

	void init();

	GLuint getBuffer() const;
};
