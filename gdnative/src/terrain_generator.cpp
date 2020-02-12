#include "terrain_generator.hpp"
#include "FastNoise.h"
#include "ArrayMesh.hpp"
#include "utils.hpp"
#include <math.h>

using namespace godot;

void TerrainGenerator::_register_methods() {
    register_method("set_params", &TerrainGenerator::set_params);
    register_method("generate_arrays", &TerrainGenerator::generate_arrays);
    register_method("arrays_to_mapdata", &TerrainGenerator::arrays_to_mapdata);
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

Array TerrainGenerator::generate_arrays(int resolution, float chunk_size, Vector2 position, int lod_n, int lod_s, int lod_w, int lod_e) {
    Array plane_mesh_arrays = get_plane_mesh_arrays(chunk_size, resolution, lod_n, lod_s, lod_w, lod_e);
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

PoolRealArray TerrainGenerator::arrays_to_mapdata(Array arrays, int mesh_ratio) {
    PoolVector3Array vertices = arrays[Mesh::ARRAY_VERTEX];

    PoolRealArray array;
    int resolution = sqrt(vertices.size());
    int new_resolution = (resolution - 1) / mesh_ratio + 1;
    array.resize(new_resolution * new_resolution);
    {
        auto r = vertices.read();
        auto w = array.write();
        int i = 0;
        for (int zi = 0; zi < resolution; zi += mesh_ratio) {
            for (int xi = 0; xi < resolution; xi += mesh_ratio) {
                w[i++] = r[xi + zi * resolution].y;
            }
        }
    }
    return array;
}
