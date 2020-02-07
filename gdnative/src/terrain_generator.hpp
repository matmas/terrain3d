#ifndef TERRAIN_GENERATOR_HPP
#define TERRAIN_GENERATOR_HPP

#include <Godot.hpp>
#include <Reference.hpp>
#include "FastNoise.h"

namespace godot {

class TerrainGenerator : public Reference {
    GODOT_CLASS(TerrainGenerator, Reference)

private:
    FastNoise noise;
    float curve;
    float amplitude;
    float _height(Vector2 point);

public:
    static void _register_methods();

    TerrainGenerator();
    ~TerrainGenerator();

    void _init();
    void set_params(int seed, float frequency, int octaves, float lacunarity, float gain, float curve, float amplitude);
    Array generate_arrays(int resolution, float chunk_size, Vector2 position);
};

}

#endif
