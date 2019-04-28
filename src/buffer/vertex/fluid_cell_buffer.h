#pragma once

#include <GL/glew.h>

#include <functional>

class FluidCellBuffer {
private:
	const GLuint _nX;
	const GLuint _nY;

	GLuint _array;
	GLuint _buffer;

public:
	FluidCellBuffer(GLuint nX, GLuint nY, std::function<int(int,int)>&& geometry);
	~FluidCellBuffer();

	void enable();
	void init(std::function<int(int,int)>&& geometry);

	GLuint getBuffer() const;

	void draw() const;
};
