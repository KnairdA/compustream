#include <memory>
#include <algorithm>
#include <iostream>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include "glfw/guard.h"
#include "glfw/window.h"

#include "buffer/vertex/fluid_cell_buffer.h"
#include "buffer/vertex/lattice_cell_buffer.h"

#include "shader/wrap/graphic_shader.h"
#include "shader/wrap/compute_shader.h"

#include "shader/code/geometry.glsl"
#include "shader/code/vertex.glsl"
#include "shader/code/fragment.glsl"

#include "shader/code/collide.glsl"
#include "shader/code/stream.glsl"

#include "timer.h"

constexpr GLuint nX = 128;
constexpr GLuint nY = 128;

float getWorldHeight(int window_width, int window_height, float world_width) {
	return world_width / window_width * window_height;
}

glm::mat4 getMVP(float world_width, float world_height) {
	const glm::mat4 projection = glm::ortho(
		-(world_width/2),  world_width/2,
		-(world_height/2), world_height/2,
		0.1f, 100.0f
	);

	const glm::mat4 view = glm::lookAt(
		glm::vec3(0,0,1),
		glm::vec3(0,0,0),
		glm::vec3(0,1,0)
	);

	return projection * view;
}

int renderWindow() {
	Window window("compustream");

	if ( !window.isGood() ) {
		std::cerr << "Failed to open GLFW window." << std::endl;
		return -1;
	}

	int window_width  = window.getWidth();
	int window_height = window.getHeight();

	float world_width  = 2*nX;
	float world_height = getWorldHeight(window_width, window_height, world_width);

	glm::mat4 MVP = getMVP(world_width,  world_height);

	std::unique_ptr<GraphicShader> scene_shader;

	std::unique_ptr<LatticeCellBuffer> lattice_a;
	std::unique_ptr<LatticeCellBuffer> lattice_b;
	std::unique_ptr<FluidCellBuffer>   fluid;

	std::unique_ptr<ComputeShader> collide_shader;
	std::unique_ptr<ComputeShader> stream_shader;

	window.init([&]() {
		scene_shader = std::make_unique<GraphicShader>(
			VERTEX_SHADER_CODE, GEOMETRY_SHADER_CODE, FRAGMENT_SHADER_CODE);

		lattice_a = std::make_unique<LatticeCellBuffer>(nX, nY);
		lattice_b = std::make_unique<LatticeCellBuffer>(nX, nY);
		fluid     = std::make_unique<  FluidCellBuffer>(nX, nY);

		collide_shader = std::make_unique<ComputeShader>(COLLIDE_SHADER_CODE);
		stream_shader  = std::make_unique<ComputeShader>(STREAM_SHADER_CODE);
	});

	if ( !collide_shader->isGood() || !stream_shader->isGood() ) {
		std::cerr << "Compute shader error." << std::endl;
		return -1;
	}

	auto last_frame = timer::now();

	bool update_lattice = true;
	bool tick           = true;

	auto pause_key = window.getKeyWatcher(GLFW_KEY_SPACE);

	auto tick_buffers = { lattice_a->getBuffer(), lattice_b->getBuffer(), fluid->getBuffer() };
	auto tock_buffers = { lattice_b->getBuffer(), lattice_a->getBuffer(), fluid->getBuffer() };

	window.render([&]() {
		if ( pause_key.wasClicked() ) {
			update_lattice = !update_lattice;
		}

		if (    window.getWidth()  != window_width
		     || window.getHeight() != window_height ) {
			window_width  = window.getWidth();
			window_height = window.getHeight();

			glViewport(0, 0, window_width, window_height);

			world_height = getWorldHeight(window_width, window_height, world_width);
			MVP = getMVP(world_width, world_height);
		}

		if ( update_lattice ) {
			if ( timer::millisecondsSince(last_frame) >= 1000/25 ) {
				if ( tick ) {
					collide_shader->workOn(tick_buffers);
					stream_shader->workOn(tick_buffers);
					tick = false;
				} else {
					collide_shader->workOn(tock_buffers);
					stream_shader->workOn(tock_buffers);
					tick = true;
				}

				{
					auto guard = collide_shader->use();
					collide_shader->dispatch(nX, nY);
				}
				{
					auto guard = stream_shader->use();
					stream_shader->dispatch(nX, nY);
				}

				last_frame = timer::now();
			}
		}

		{
			auto guard = scene_shader->use();

			scene_shader->setUniform("MVP", MVP);

			glClear(GL_COLOR_BUFFER_BIT);
			fluid->draw();
		}
	});

	return 0;
}

int main(int argc, char* argv[]) {
	GlfwGuard glfw;

	if( !glfw.isGood() ) {
		std::cerr << "Failed to initialize GLFW." << std::endl;
		return -1;
	}

	return renderWindow();
}
