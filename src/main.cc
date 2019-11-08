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

#include "shader/code/interact.glsl"
#include "shader/code/collide.glsl"
#include "shader/code/extra.glsl"

#include "timer.h"

GLuint maxLUPF = 100;
GLuint nX = 512;
GLuint nY = 256;

enum DisplayMode {
	VELOCITY,
	QUALITY,
	CURL
};

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

int setupOpenGeometry(int x, int y) {
	if ( x == 0 || y == 0 || x == nX-1 || y == nY-1 ) {
		return 0; // disable end of world
	}
	if ( (x == 1 || x == nX-2) && (y > 0 && y < nY-1) ) {
		if ( x == 1 && y > 1 && y < nY-2 ) {
			return 5; // inflow
		}
		if ( x == nX-2 && y > 1 && y < nY-2 ) {
			return 6; // outflow
		}
		return 2; // bounce back outer walls
	}
	if ( (y == 1 || y == nY-2) && (x > 0 && x < nX-1) ) {
		return 2; // bounce back outer walls
	}
	return 1; // everything else shall be bulk fluid
}

int render() {
	Window window("compustream");

	if ( !window.isGood() ) {
		std::cerr << "Failed to open GLFW window." << std::endl;
		return -1;
	}

	float world_width  = 1.1*nX;
	float world_height = getWorldHeight(window.getWidth(), window.getHeight(), world_width);

	glm::mat4 MVP = getMVP(world_width,  world_height);

	std::unique_ptr<GraphicShader> scene_shader;

	std::unique_ptr<LatticeCellBuffer> lattice_a;
	std::unique_ptr<LatticeCellBuffer> lattice_b;
	std::unique_ptr<FluidCellBuffer>   fluid;
	std::unique_ptr<FluidCellBuffer>   extra;

	std::unique_ptr<ComputeShader> interact_shader;
	std::unique_ptr<ComputeShader> collide_shader;
	std::unique_ptr<ComputeShader> extra_shader;

	window.init([&]() {
		scene_shader = std::make_unique<GraphicShader>(
			VERTEX_SHADER_CODE, GEOMETRY_SHADER_CODE, FRAGMENT_SHADER_CODE);

		lattice_a = std::make_unique<LatticeCellBuffer>(nX, nY);
		lattice_b = std::make_unique<LatticeCellBuffer>(nX, nY);
		extra     = std::make_unique<  FluidCellBuffer>(nX, nY, setupOpenGeometry);
		fluid     = std::make_unique<  FluidCellBuffer>(nX, nY, setupOpenGeometry);

		interact_shader = std::make_unique<ComputeShader>(INTERACT_SHADER_CODE);
		extra_shader    = std::make_unique<ComputeShader>(EXTRA_SHADER_CODE);
		collide_shader  = std::make_unique<ComputeShader>(COLLIDE_SHADER_CODE);
	});

	if ( !interact_shader->isGood() || !collide_shader->isGood() ) {
		std::cerr << "Compute shader error." << std::endl;
		return -1;
	}

	auto reset_key = window.getKeyWatcher(GLFW_KEY_R);

	auto pause_key  = window.getKeyWatcher(GLFW_KEY_SPACE);
	bool update_lattice = true;

	auto velocity_mode_key = window.getKeyWatcher(GLFW_KEY_V);
	auto quality_mode_key  = window.getKeyWatcher(GLFW_KEY_Q);
	auto curl_mode_key     = window.getKeyWatcher(GLFW_KEY_C);
	DisplayMode display_mode = DisplayMode::VELOCITY;

	auto palette_factor_incr  = window.getKeyWatcher(GLFW_KEY_UP);
	auto palette_factor_decr = window.getKeyWatcher(GLFW_KEY_DOWN);
	int  palette_factor = 6;

	int prevMouseState = 0;
	float prevLatticeMouseX;
	float prevLatticeMouseY;

	int currMouseState = 0;
	float currLatticeMouseX;
	float currLatticeMouseY;

	auto tick_buffers = { lattice_a->getBuffer(), lattice_b->getBuffer(), fluid->getBuffer(), extra->getBuffer() };
	auto tock_buffers = { lattice_b->getBuffer(), lattice_a->getBuffer(), fluid->getBuffer(), extra->getBuffer() };

	GLuint iT = 0;
	int statLUPS = 0;

	auto last_lattice_update = timer::now();
	auto last_lups_update    = timer::now();

	bool tick = true;

	window.render([&](bool window_size_changed) {
		if ( reset_key.wasClicked() ) {
			iT = 0;
			lattice_a->init();
			lattice_b->init();
		}
		if ( pause_key.wasClicked() ) {
			update_lattice = !update_lattice;
		}

		if ( velocity_mode_key.wasClicked() ) {
			display_mode = DisplayMode::VELOCITY;
			fluid->enable();
		}
		if ( quality_mode_key.wasClicked() ) {
			display_mode = DisplayMode::QUALITY;
			fluid->enable();
		}
		if ( curl_mode_key.wasClicked() ) {
			display_mode = DisplayMode::CURL;
			extra->enable();
		}

		if ( palette_factor_incr.wasClicked() ) {
			palette_factor += 1;
		}
		if ( palette_factor_decr.wasClicked() ) {
			palette_factor = std::max(1, palette_factor-1);
		}

		if ( window_size_changed ) {
			world_height = getWorldHeight(window.getWidth(), window.getHeight(), world_width);
			MVP = getMVP(world_width, world_height);
		}

		if ( update_lattice ) {
			if ( timer::secondsSince(last_lups_update) >= 1.0 ) {
				std::cout << "\r~ " << nX*nY * statLUPS / timer::secondsSince(last_lups_update) * 1e-6 << " MLUPS" << std::flush;
				statLUPS = 0;
				last_lups_update = timer::now();
			}

			if ( tick ) {
				interact_shader->workOn(tick_buffers);
				extra_shader->workOn(tick_buffers);
			} else {
				interact_shader->workOn(tock_buffers);
				extra_shader->workOn(tock_buffers);
			}

			/// Perform collide & stream steps
			{
				auto guard = collide_shader->use();

				collide_shader->setUniform("show_quality", display_mode == DisplayMode::QUALITY);
				collide_shader->setUniform("iT", iT);
				iT += 1;

				for (auto i=0; i < maxLUPF; ++i) {
					if ( tick ) {
						collide_shader->workOn(tick_buffers);
						tick = false;
					} else {
						collide_shader->workOn(tock_buffers);
						tick = true;
					}

					collide_shader->dispatch(nX, nY);
				}

				statLUPS += maxLUPF;
			}

			if ( display_mode == DisplayMode::CURL ) {
				auto guard = extra_shader->use();
				extra_shader->dispatch(nX, nY);
			}

			last_lattice_update = timer::now();
		}

		/// Update mouse projection
		{
			const auto m = window.getMouse();

			prevMouseState = currMouseState;
			prevLatticeMouseX = currLatticeMouseX;
			prevLatticeMouseY = currLatticeMouseY;

			currMouseState = std::get<0>(m);
			currLatticeMouseX = float(std::get<1>(m)) / window.getWidth()  * world_width  + nX/2;
			currLatticeMouseY = float(std::get<2>(m)) / window.getHeight() * world_height + nY/2;
		}

		/// Handle mouse-based interaction
		if ( currMouseState != 0 || prevMouseState != 0 ) {
			auto guard = interact_shader->use();

			interact_shader->setUniform("wall_requested",  currMouseState == 1);
			interact_shader->setUniform("fluid_requested", currMouseState == 2);

			interact_shader->setUniform("start", prevLatticeMouseX, prevLatticeMouseY);
			interact_shader->setUniform("end",   currLatticeMouseX, currLatticeMouseY);

			interact_shader->dispatch(nX, nY);
		}

		{
			auto guard = scene_shader->use();

			scene_shader->setUniform("MVP", MVP);
			scene_shader->setUniform("nX", nX);
			scene_shader->setUniform("nY", nY);
			scene_shader->setUniform("palette_factor", palette_factor);

			glClear(GL_COLOR_BUFFER_BIT);

			switch ( display_mode ) {
				case DisplayMode::VELOCITY:
					scene_shader->setUniform("show_quality", false);
					scene_shader->setUniform("show_curl",    false);
					fluid->draw();
					break;
				case DisplayMode::QUALITY:
					scene_shader->setUniform("show_quality", true);
					scene_shader->setUniform("show_curl",    false);
					fluid->draw();
					break;
				case DisplayMode::CURL:
					scene_shader->setUniform("show_quality", false);
					scene_shader->setUniform("show_curl",    true);
					extra->draw();
					break;
			}
		}
	});

	std::cout << std::endl;

	return 0;
}

bool parseArguments(int argc, char* argv[]) {
	for ( int i = 1; i < argc; ++i ) {
		const auto& arg = std::string_view(argv[i]);

		if ( arg == "--lupf" ) {
			if ( i+1 < argc ) {
				try {
					i       += 1;
					maxLUPF = std::stoi(argv[i]);
				}
				catch ( std::invalid_argument& ex ) {
					std::cerr << "Maximum lattice updates per frame malformed." << std::endl;
					return false;
				}
			} else {
				std::cerr << "Maximum lattice updates per frame undefined." << std::endl;
				return false;
			}
		}

		if ( arg == "--size" ) {
			if ( i+2 < argc ) {
				try {
					i += 1;
					nX = std::stoi(argv[i]);
					i += 1;
					nY = std::stoi(argv[i]);
				}
				catch ( std::invalid_argument& ex ) {
					std::cerr << "Lattice size malformed." << std::endl;
					return false;
				}
			} else {
				std::cerr << "Lattice size undefined." << std::endl;
				return false;
			}
		}
	}
	return true;
}

int main(int argc, char* argv[]) {
	if ( parseArguments(argc, argv) ) {
		GlfwGuard glfw;

		if( !glfw.isGood() ) {
			std::cerr << "Failed to initialize GLFW." << std::endl;
			return -1;
		}

		return render();
	} else {
		return -1;
	}
}
