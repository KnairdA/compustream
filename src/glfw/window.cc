#include "window.h"

bool Window::updateSize() {
	const int old_width  = _width;
	const int old_height = _height;

	glfwGetWindowSize(_handle, &_width, &_height);

	return old_width  != _width
	    || old_height != _height;
}

Window::Window(const std::string& title):
	_handle(glfwCreateWindow(_width, _height, title.c_str(), NULL, NULL)) {
	if ( _handle != nullptr ) {
		glfwMakeContextCurrent(_handle);
		if ( glewInit() == GLEW_OK ) {
			_good = true;
		}
		glfwMakeContextCurrent(nullptr);
	}
}

Window::~Window() {
	glfwDestroyWindow(_handle);
}

bool Window::isGood() const {
	return _good;
}

int Window::getWidth() const {
	return _width;
}

int Window::getHeight() const {
	return _height;
}

KeyWatcher Window::getKeyWatcher(int key) {
	return KeyWatcher(_handle, key);
}
