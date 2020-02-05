#ifndef TERRAIN_CHUNK_H
#define TERRAIN_CHUNK_H

#include <Godot.hpp>
#include <Spatial.hpp>

namespace godot {

class TerrainChunk : public Spatial {
    GODOT_CLASS(TerrainChunk, Spatial)

private:
    int x;
    int z;

public:
    static void _register_methods();

    TerrainChunk();
    ~TerrainChunk();

    void _init();

    void _process(float delta);
};

}

#endif