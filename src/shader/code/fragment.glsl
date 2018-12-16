static const std::string FRAGMENT_SHADER_CODE = R"(
#version 430

in  vec3 color;
out vec4 FragColor;

void main() {
	FragColor = vec4(color.xyz, 0.0);
}
)";
