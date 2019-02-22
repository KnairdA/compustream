#pragma once

#include <GL/glew.h>

class MaterialBuffer {
private:
	const GLuint _nX;
	const GLuint _nY;

	GLuint _array;
	GLuint _buffer;

public:
	MaterialBuffer(GLuint nX, GLuint nY);
	~MaterialBuffer();

	GLuint getBuffer() const;
};
