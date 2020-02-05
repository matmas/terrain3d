#include "terrain_generator.hpp"
#include "FastNoise.h"
#include "ArrayMesh.hpp"
#include "utils.hpp"

using namespace godot;

void TerrainGenerator::_register_methods() {
    register_method("generate_arrays", &TerrainGenerator::generate_arrays);
}

TerrainGenerator::TerrainGenerator() {
    noise.SetNoiseType(FastNoise::SimplexFractal);
    noise.SetSeed(0);
    noise.SetFrequency(1.0 / 64);
    noise.SetFractalType(FastNoise::FractalType::FBM);
    noise.SetFractalOctaves(3);
    noise.SetFractalLacunarity(4.0);
    noise.SetFractalGain(0.164);
}

TerrainGenerator::~TerrainGenerator() {
}

void TerrainGenerator::_init() {
}

float TerrainGenerator::_height(Vector2 point, float chunk_size, int x, int z, float curve, float amplitude) {
    float value = this->noise.GetNoise(x * chunk_size + point.x, z * chunk_size + point.y);  // from -1.0 to 1.0
	value = (value + 1.0) * 0.5;  // from 0.0 to 1.0
	value = ease(value, curve);
	value = value * 2.0 - 1.0;  // from -1.0 to 1.0
	value *= amplitude;
	return value;
}

Array TerrainGenerator::generate_arrays(int resolution, float chunk_size, int x, int z, float curve, float amplitude) {
    Array arrays = get_plane_mesh_arrays(chunk_size, resolution);
    PoolVector3Array vertices = arrays[Mesh::ARRAY_VERTEX];
    PoolVector3Array normals = arrays[Mesh::ARRAY_NORMAL];
    {
        PoolVector3Array::Read vertices_r = vertices.read();
        PoolVector3Array::Write vertices_w = vertices.write();
        PoolVector3Array::Write normals_w = normals.write();

        for (int i = 0; i < resolution * resolution; i++) {
            Vector3 vertex = vertices_r[i];
            Vector2 point = Vector2(vertex.x, vertex.z);
            float height = this->_height(point, chunk_size, x, z, curve, amplitude);
            vertices_w[i].y = height;
            Vector2 delta = Vector2(chunk_size * 0.5 / resolution, 0);
            normals_w[i] = Vector3(height - _height(point + delta, chunk_size, x, z, curve, amplitude), delta.x, height - _height(point - delta.tangent(), chunk_size, x, z, curve, amplitude));
        }
    }
    arrays[Mesh::ARRAY_VERTEX] = vertices;
    arrays[Mesh::ARRAY_NORMAL] = normals;
    return arrays;
}
