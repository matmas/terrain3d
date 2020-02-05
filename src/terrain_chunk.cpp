#include "terrain_chunk.h"
#include "FastNoiseSIMD.h"

using namespace godot;

void TerrainChunk::_register_methods() {
    register_method("_process", &TerrainChunk::_process);
}

TerrainChunk::TerrainChunk() {
}

TerrainChunk::~TerrainChunk() {
}

void TerrainChunk::_init() {
    x = 0;
    z = 0;

    FastNoiseSIMD* noise = FastNoiseSIMD::NewFastNoiseSIMD();
    float* noiseSet = noise->GetSimplexFractalSet(0, 0, 0, 16, 16, 16);
}

void TerrainChunk::_process(float delta) {
}
