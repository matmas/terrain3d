#ifndef UTILS_HPP
#define UTILS_HPP

#include <Godot.hpp>

float ease(float p_x, float p_c);
float lerp(float a, float b, float t);
godot::Array get_plane_mesh_arrays(float chunk_size, int resolution, bool reduce_top, bool reduce_bottom, bool reduce_left, bool reduce_right);

#endif
