#include <math.h>
#include <assert.h>
#include <ArrayMesh.hpp>
#include "utils.hpp"

using namespace godot;

// Taken from Godot sources
float ease(float p_x, float p_c) {
	if (p_x < 0)
		p_x = 0;
	else if (p_x > 1.0)
		p_x = 1.0;
	if (p_c > 0) {
		if (p_c < 1.0) {
			return 1.0 - pow(1.0 - p_x, 1.0 / p_c);
		} else {
			return pow(p_x, p_c);
		}
	} else if (p_c < 0) {
		//inout ease

		if (p_x < 0.5) {
			return pow(p_x * 2.0, -p_c) * 0.5;
		} else {
			return (1.0 - pow(1.0 - (p_x - 0.5) * 2.0, -p_c)) * 0.5 + 0.5;
		}
	} else
		return 0; // no ease (raw)
}

float lerp(float a, float b, float t) {
    return a + (b - a) * t;
}

// resolution needs to be power of two + 1 and >= 3
Array get_plane_mesh_arrays(float chunk_size, int resolution, int lod_n, int lod_s, int lod_w, int lod_e) {
    PoolVector3Array vertices;
    vertices.resize(resolution * resolution);
    {
        PoolVector3Array::Write w = vertices.write();
        for (int zi = 0; zi < resolution; zi++) {
            for (int xi = 0; xi < resolution; xi++) {
                float x = lerp(-chunk_size * 0.5, chunk_size * 0.5, float(xi) / (resolution - 1));
                float z = lerp(-chunk_size * 0.5, chunk_size * 0.5, float(zi) / (resolution - 1));
                w[xi + zi * resolution] = Vector3(x, 0.0, z);
            }
        }
    }
    PoolVector3Array normals;
    normals.resize(resolution * resolution);
    {
        PoolVector3Array::Write w = normals.write();
        for (int i = 0; i < resolution * resolution; i++) {
            w[i] = Vector3(0.0, 1.0, 0.0);
        }
    }
    PoolRealArray tangents;
    tangents.resize(4 * resolution * resolution);
    {
        PoolRealArray::Write w = tangents.write();
        for (int i = 0; i < resolution * resolution; i++) {
            w[i * 4] = 1.0;
            w[i * 4 + 1] = 0.0;
            w[i * 4 + 2] = 0.0;
            w[i * 4 + 3] = 1.0;
        }
    }
    PoolVector2Array uvs;
    uvs.resize(resolution * resolution);
    {
        PoolVector2Array::Write w = uvs.write();
        for (int zi = 0; zi < resolution; zi++) {
            for (int xi = 0; xi < resolution; xi++) {
                w[xi + zi * resolution] = Vector2(float(xi) / (resolution - 1), float(zi) / (resolution - 1));
            }
        }
    }

    PoolIntArray indices;
    int indices_size = 3 * 8 * (resolution - 1) / 2 * (resolution - 1) / 2;
    indices.resize(indices_size);
    int i = 0;
    {
        PoolIntArray::Write w = indices.write();
        enum { NORTH, SOUTH, WEST, EAST };
        int direction = NORTH;
        auto coord = [&](int x, int z) {
            if (direction == NORTH) {
                return x + z * resolution;
            }
            if (direction == SOUTH) {
                return resolution - 1 - x + (resolution - 1 - z) * resolution;
            }
            if (direction == WEST) {
                return z + (resolution - 1 - x) * resolution;
            }
            if (direction == EAST) {
                return resolution - 1 - z + x * resolution;
            }
            return 0;
        };
        for (auto lod : {lod_n, lod_s, lod_w, lod_e}) {
            int num_wedges = lod == 0 ? 0 : (resolution - 1) / lod / 2;
            for (int wedge_index = 0; wedge_index < num_wedges; wedge_index++) {
                int wedge_width = lod * 2;
                w[i++] = coord(wedge_width * wedge_index, 0);
                w[i++] = coord(wedge_width * wedge_index + wedge_width, 0);
                w[i++] = coord(wedge_width * wedge_index + wedge_width / 2, 1);
            }
            direction++;
        }
        direction = NORTH;
        for (auto lod : {lod_n, lod_s, lod_w, lod_e}) {
            if (lod > 0) {
                for (int triangle_index = 1; triangle_index < resolution - 2; triangle_index++) {
                    w[i++] = coord((triangle_index / lod) * lod + ((triangle_index / lod) % 2 == 0 ? 0 : lod), 0);
                    w[i++] = coord(triangle_index + 1, 1);
                    w[i++] = coord(triangle_index, 1);
                }
            }
            direction++;
        }
        direction = NORTH;
        for (int zi = 1; zi < resolution - 2; zi++) {
            for (int xi = 1; xi < resolution - 2; xi++) {
                w[i++] = coord(xi + 0, zi + 0);
                w[i++] = coord(xi + 1, zi + 0);
                w[i++] = coord(xi + (xi+zi+1) % 2, zi + 1);

                w[i++] = coord(xi + (xi+zi) % 2, zi + 0);
                w[i++] = coord(xi + 1, zi + 1);
                w[i++] = coord(xi + 0, zi + 1);
            }
        }
        for (auto lod : {lod_n, lod_s, lod_w, lod_e}) {
            if (lod == 0) {
                w[i++] = coord(0, 0);
                w[i++] = coord(1, 0);
                w[i++] = coord(1, 1);

                for (int xi = 1; xi < resolution - 2; xi++) {
                    w[i++] = coord(xi + 0, 0);
                    w[i++] = coord(xi + 1, 0);
                    w[i++] = coord(xi + (xi+1) % 2, 1);

                    w[i++] = coord(xi + xi % 2, 0);
                    w[i++] = coord(xi + 1, 1);
                    w[i++] = coord(xi + 0, 1);
                }

                w[i++] = coord(resolution - 2, 1);
                w[i++] = coord(resolution - 2, 0);
                w[i++] = coord(resolution - 1, 0);
            }
            direction++;
        }
    }
    indices.resize(i);

    Array arrays;
    arrays.resize(Mesh::ARRAY_MAX);
    arrays[Mesh::ARRAY_VERTEX] = vertices;
    arrays[Mesh::ARRAY_NORMAL] = normals;
    arrays[Mesh::ARRAY_TANGENT] = tangents;
    arrays[Mesh::ARRAY_TEX_UV] = uvs;
    arrays[Mesh::ARRAY_INDEX] = indices;
    return arrays;
}
