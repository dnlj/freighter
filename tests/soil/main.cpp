#include <iostream>
#include <string_view>
#include <algorithm>
#include <SOIL.h>

void check(bool value, std::string_view msg) {
	if (!value) {
		std::cout << "FAILURE: ";
	} else {
		std::cout << "SUCCESS: ";
	}
	std::cout << msg << "\n";
}

int main(void) {
	unsigned char data[4 * 4 * 3] = {
		255, 000, 000,    000, 255, 000,    000, 255, 255,    255, 000, 255,
		000, 000, 255,    255, 255, 255,    255, 255, 000,    000, 000, 000,
		000, 255, 255,    255, 000, 255,    255, 000, 000,    000, 255, 000,
		255, 255, 000,    000, 000, 000,    000, 000, 255,    255, 255, 255,
	};

	int width;
	int height;
	int channels;
	auto image = SOIL_load_image("colors.bmp", &width, &height, &channels, SOIL_LOAD_RGB);
	
	check(image != nullptr, "Image loaded");
	check(width == 4, "Correct width");
	check(height == 4, "Correct height");
	check(channels == 3, "Correct channels");
	check(std::equal(image, image + width * height * channels, data), "Correct data");

	SOIL_free_image_data(image);
	getchar();
	return 0;
}