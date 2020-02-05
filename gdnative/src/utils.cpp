#include <math.h>
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

Array get_plane_mesh_arrays(float chunk_size, int resolution) {
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
    indices.resize(6 * (resolution - 1) * (resolution - 1));
    {
        PoolIntArray::Write w = indices.write();
        for (int zi = 0; zi < resolution - 1; zi++) {
            for (int xi = 0; xi < resolution - 1; xi++) {
                w[(xi + zi * (resolution - 1)) * 6] = xi + zi * resolution;
                w[(xi + zi * (resolution - 1)) * 6 + 1] = xi + 1 + zi * resolution;
                w[(xi + zi * (resolution - 1)) * 6 + 2] = xi + 1 + (zi + 1) * resolution;
                w[(xi + zi * (resolution - 1)) * 6 + 3] = xi + zi * resolution;
                w[(xi + zi * (resolution - 1)) * 6 + 4] = xi + 1 + (zi + 1) * resolution;
                w[(xi + zi * (resolution - 1)) * 6 + 5] = xi + (zi + 1) * resolution;
            }
        }
    }
    Array arrays;
    arrays.resize(Mesh::ARRAY_MAX);
    arrays[Mesh::ARRAY_VERTEX] = vertices;
    arrays[Mesh::ARRAY_NORMAL] = normals;
    arrays[Mesh::ARRAY_TANGENT] = tangents;
    arrays[Mesh::ARRAY_TEX_UV] = uvs;
    arrays[Mesh::ARRAY_INDEX] = indices;
    return arrays;
}
