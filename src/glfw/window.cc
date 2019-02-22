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

std::tuple<int,int,int> Window::getMouse() const {
	double x, y;
	glfwGetCursorPos(_handle, &x, &y);
	x = int(x -  getWidth()/2);
	y = int(getHeight()/2 - y);

	if ( glfwGetMouseButton(_handle, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS ) {
		return std::make_tuple(1, x, y);
	}

	if ( glfwGetMouseButton(_handle, GLFW_MOUSE_BUTTON_RIGHT) == GLFW_PRESS ) {
		return std::make_tuple(2, x, y);
	}

	return std::make_tuple(0, x, y);
}

KeyWatcher Window::getKeyWatcher(int key) const {
	return KeyWatcher(_handle, key);
}
