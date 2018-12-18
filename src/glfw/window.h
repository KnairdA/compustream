#pragma once

#include <tuple>
#include <string>

#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include "key_watcher.h"

class Window {
private:
	bool _good   = false;
	int  _width  = 800;
	int  _height = 600;

	GLFWwindow* const _handle;

	bool updateSize();

public:
	Window(const std::string& title);
	~Window();

	bool isGood() const;

	int getWidth() const;
	int getHeight() const;

	std::tuple<bool,int,int> getMouse() const;

	KeyWatcher getKeyWatcher(int key) const;

	template <class F>
	void init(F f);

	template <class F>
	void render(F loop);
};

template <class F>
void Window::init(F f) {
	glfwMakeContextCurrent(_handle);
	f();
	glfwMakeContextCurrent(nullptr);
}

template <class F>
void Window::render(F loop) {
	glfwMakeContextCurrent(_handle);

	while ( glfwGetKey(_handle, GLFW_KEY_ESCAPE) != GLFW_PRESS &&
	        glfwWindowShouldClose(_handle)       == 0 ) {
		const bool window_size_changed = updateSize();

		if ( window_size_changed ) {
			glViewport(0, 0, getWidth(), getHeight());
		}

		loop(window_size_changed);

		glfwSwapBuffers(_handle);
		glfwPollEvents();
	}

	glfwMakeContextCurrent(nullptr);
}
