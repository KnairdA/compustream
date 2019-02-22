#pragma once

#include <GL/glew.h>

#include <functional>

class MaterialBuffer {
private:
	const GLuint _nX;
	const GLuint _nY;

	GLuint _array;
	GLuint _buffer;

public:
	MaterialBuffer(GLuint nX, GLuint nY, std::function<int(int,int)>&& geometry);
	~MaterialBuffer();

	GLuint getBuffer() const;
};
