#pragma once

#include <string>

#include <GL/glew.h>

class ComputeShader {
private:
	const GLuint _id;

	bool _good;

public:
	struct Guard {
		const GLuint _id;

		Guard(GLuint id);
		~Guard();
	};

	Guard use() const;

	ComputeShader(const std::string& src);
	~ComputeShader();

	bool isGood() const;

	GLuint setUniform(const std::string& name, float x, float y) const;
	GLuint setUniform(const std::string& name, unsigned int value) const;

	void workOn(GLuint bufferA, GLuint bufferB, GLuint bufferC) const;
	void dispatch(GLuint nX, GLuint nY) const;
};
