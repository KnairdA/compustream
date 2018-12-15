cmake_minimum_required(VERSION 3.10)
project(compustream LANGUAGES CXX)

include_directories(
	src/
)

add_executable(
	compustream
		src/main.cc
		src/timer.cc
		src/glfw/guard.cc
		src/glfw/window.cc
		src/glfw/key_watcher.cc
		src/shader/util.cc
		src/shader/wrap/compute_shader.cc
		src/shader/wrap/graphic_shader.cc
		src/buffer/vertex/lattice_cell_buffer.cc
		src/buffer/vertex/fluid_cell_buffer.cc
)

target_link_libraries(
	compustream
		GL
		glfw
		GLEW
)

target_compile_features(
	compustream
	PUBLIC
		cxx_std_17
)

