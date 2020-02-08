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
Array get_plane_mesh_arrays(float chunk_size, int resolution, bool reduce_top, bool reduce_bottom, bool reduce_left, bool reduce_right) {
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
    if (reduce_top) {
        indices_size -= 3 * (resolution - 1) / 2;
    }
    if (reduce_bottom) {
        indices_size -= 3 * (resolution - 1) / 2;
    }
    if (reduce_left) {
        indices_size -= 3 * (resolution - 1) / 2;
    }
    if (reduce_right) {
        indices_size -= 3 * (resolution - 1) / 2;
    }
    indices.resize(indices_size);
    {
        PoolIntArray::Write w = indices.write();
        int i = 0;
        for (int zi = 0; zi < resolution - 1; zi+=2) {
            for (int xi = 0; xi < resolution - 1; xi+=2) {
                // 0-1-2-3-4
                // |\ /|\ /|
                // 5 6-7-8 9
                // |/|\|/|\|
                // a-b-c-d-e
                // |\|/|\|/|
                // f g-h-i j
                // |/ \|/ \|
                // k-l-m-n-o

                if (reduce_top && (zi == 0)) {
                    w[i++] = xi + 0 + (zi + 0) * resolution;  // 0
                    w[i++] = xi + 2 + (zi + 0) * resolution;  // 2 (top triangle)
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6
                } else {
                    w[i++] = xi + 0 + (zi + 0) * resolution;  // 0
                    w[i++] = xi + 1 + (zi + 0) * resolution;  // 1 (1st top triangle)
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6

                    w[i++] = xi + 1 + (zi + 0) * resolution;  // 1
                    w[i++] = xi + 2 + (zi + 0) * resolution;  // 2 (2nd top triangle)
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6
                }
                if (reduce_left && (xi == 0)) {
                    w[i++] = xi + 0 + (zi + 0) * resolution;  // 0
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6 (left triangle)
                    w[i++] = xi + 0 + (zi + 2) * resolution;  // a
                } else {
                    w[i++] = xi + 0 + (zi + 0) * resolution;  // 0
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6 (1st left triangle)
                    w[i++] = xi + 0 + (zi + 1) * resolution;  // 5

                    w[i++] = xi + 0 + (zi + 1) * resolution;  // 5
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6 (2nd left triangle)
                    w[i++] = xi + 0 + (zi + 2) * resolution;  // a
                }
                if (reduce_right && (xi == resolution - 3)) {
                    w[i++] = xi + 2 + (zi + 0) * resolution;  // 2
                    w[i++] = xi + 2 + (zi + 2) * resolution;  // c (right triangle)
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6
                } else {
                    w[i++] = xi + 2 + (zi + 0) * resolution;  // 2
                    w[i++] = xi + 2 + (zi + 1) * resolution;  // 7 (1st right triangle)
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6

                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6
                    w[i++] = xi + 2 + (zi + 1) * resolution;  // 7 (2st right triangle)
                    w[i++] = xi + 2 + (zi + 2) * resolution;  // c

                }
                if (reduce_bottom && (zi == resolution - 3)) {
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6
                    w[i++] = xi + 2 + (zi + 2) * resolution;  // c (bottom triangle)
                    w[i++] = xi + 0 + (zi + 2) * resolution;  // a
                } else {
                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6
                    w[i++] = xi + 1 + (zi + 2) * resolution;  // b (1st bottom triangle)
                    w[i++] = xi + 0 + (zi + 2) * resolution;  // a

                    w[i++] = xi + 1 + (zi + 1) * resolution;  // 6
                    w[i++] = xi + 2 + (zi + 2) * resolution;  // c (2st bottom triangle)
                    w[i++] = xi + 1 + (zi + 2) * resolution;  // b
                }
            }
        }
        assert(indices_size == i);
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
