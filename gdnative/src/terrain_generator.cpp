#include "terrain_generator.hpp"
#include "FastNoise.h"
#include "ArrayMesh.hpp"
#include "utils.hpp"

using namespace godot;

void TerrainGenerator::_register_methods() {
    register_method("set_params", &TerrainGenerator::set_params);
    register_method("generate_arrays", &TerrainGenerator::generate_arrays);
}

TerrainGenerator::TerrainGenerator() {
    noise.SetNoiseType(FastNoise::SimplexFractal);
    noise.SetFractalType(FastNoise::FractalType::FBM);
}

TerrainGenerator::~TerrainGenerator() {
}

void TerrainGenerator::_init() {
}

void TerrainGenerator::set_params(int seed, float frequency, int octaves, float lacunarity, float gain, float curve, float amplitude) {
    noise.SetSeed(seed);
    noise.SetFrequency(frequency);
    noise.SetFractalOctaves(octaves);
    noise.SetFractalLacunarity(lacunarity);
    noise.SetFractalGain(gain);
    this->curve = curve;
    this->amplitude = amplitude;
}

float TerrainGenerator::_height(Vector2 point) {
    float value = this->noise.GetNoise(point.x, point.y);  // from -1.0 to 1.0
	value = (value + 1.0) * 0.5;  // from 0.0 to 1.0
	value = ease(value, this->curve);
	value = value * 2.0 - 1.0;  // from -1.0 to 1.0
	value *= this->amplitude;
	return value;
}

Array TerrainGenerator::generate_arrays(int resolution, float chunk_size, Vector2 position, bool reduce_top, bool reduce_bottom, bool reduce_left, bool reduce_right) {
    Array plane_mesh_arrays = get_plane_mesh_arrays(chunk_size, resolution, reduce_top, reduce_bottom, reduce_left, reduce_right);
    return plane_mesh_arrays;
    PoolVector3Array vertices = plane_mesh_arrays[Mesh::ARRAY_VERTEX];
    PoolVector3Array normals;
    normals.resize(resolution * resolution);
    {
        PoolVector3Array::Read vertices_r = vertices.read();
        PoolVector3Array::Write vertices_w = vertices.write();
        PoolVector3Array::Write normals_w = normals.write();

        for (int i = 0; i < resolution * resolution; i++) {
            Vector3 vertex = vertices_r[i];
            Vector2 vertex_position = position + Vector2(vertex.x, vertex.z);
            float height = this->_height(vertex_position);
            vertices_w[i].y = height;
            Vector2 delta = Vector2(chunk_size * 0.5 / resolution, 0);
            normals_w[i] = Vector3(height - _height(vertex_position + delta), delta.x, height - _height(vertex_position - delta.tangent()));
        }
    }
    Array arrays;
    arrays.resize(Mesh::ARRAY_MAX);
    arrays[Mesh::ARRAY_VERTEX] = vertices;
    arrays[Mesh::ARRAY_NORMAL] = normals;
    arrays[Mesh::ARRAY_TANGENT] = plane_mesh_arrays[Mesh::ARRAY_TANGENT];
    arrays[Mesh::ARRAY_TEX_UV] = plane_mesh_arrays[Mesh::ARRAY_TEX_UV];
    arrays[Mesh::ARRAY_INDEX] = plane_mesh_arrays[Mesh::ARRAY_INDEX];
    return arrays;
}
