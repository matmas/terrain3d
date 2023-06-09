#ifndef UTILS_HPP
#define UTILS_HPP

#include <Godot.hpp>

float ease(float p_x, float p_c);
float lerp(float a, float b, float t);
godot::Array get_plane_mesh_arrays(float chunk_size, int resolution, int lod_n, int lod_s, int lod_w, int lod_e);

#endif
