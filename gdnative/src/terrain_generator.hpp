#ifndef TERRAIN_GENERATOR_HPP
#define TERRAIN_GENERATOR_HPP

#include <vector>
#include <limits>
#include <Godot.hpp>
#include <Reference.hpp>
#include "FastNoise.h"

namespace godot {

struct NoiseLayer {
    FastNoise noise;
    float curve;
    float amplitude;
};

class TerrainGenerator : public Reference {
    GODOT_CLASS(TerrainGenerator, Reference)

private:
    std::vector<NoiseLayer> layers;
    float _height(Vector2 point);

public:
    static void _register_methods();

    TerrainGenerator();
    ~TerrainGenerator();

    void _init();
    void add_params(int noise_type, int fractal_type, int interpolation, int seed, float frequency, int octaves, float lacunarity, float gain, float curve, float amplitude);
    Array generate_arrays(int resolution, float chunk_size, Vector2 position, int lod_n, int lod_s, int lod_w, int lod_e);
    PoolRealArray arrays_to_mapdata(Array arrays, int mesh_ratio);
    Array get_min_max_height(Array arrays);
};

}

#endif
