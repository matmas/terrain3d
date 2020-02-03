tool
extends Spatial
class_name Chunk

var noise: OpenSimplexNoise
var x
var z
var mesh_instance: MeshInstance
var terrain


func _init(noise, x, z, terrain):
	self.noise = noise
	self.x = x
	self.z = z
	self.translation = Vector3(x * terrain.chunk_size, 0, z * terrain.chunk_size)
	self.terrain = terrain
	var arrays = _get_plane_mesh_arrays(terrain.chunk_size, terrain.resolution)

	# Adjust vertices
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	for i in range(len(vertices)):
		var point = Vector2(vertices[i].x, vertices[i].z)
		var height := _height(point)
		arrays[Mesh.ARRAY_VERTEX][i].y = height
		var delta = Vector2(terrain.chunk_size * 0.5 / terrain.resolution, 0)
		arrays[Mesh.ARRAY_NORMAL][i] = Vector3(height - _height(point + delta), delta.x, height - _height(point - delta.tangent()))

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, preload("res://terrain.material"))
	mesh_instance = MeshInstance.new()
	mesh_instance.mesh = mesh
	mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
#	mesh_instance.create_trimesh_collision()


func _ready():
	add_child(mesh_instance)


func _height(point) -> float:
	var value = noise.get_noise_2d(x * terrain.chunk_size + point.x, z * terrain.chunk_size + point.y)  # from -1.0 to 1.0
	value = (value + 1.0) * 0.5  # from 0.0 to 1.0
	value = ease(value, terrain.curve)
	value = value * 2.0 - 1.0  # from -1.0 to 1.0
	value *= terrain.amplitude
	return value


func _get_plane_mesh_arrays(chunk_size, resolution):
	"""
	Faster equivalent to:

	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_depth = resolution - 2
	plane_mesh.subdivide_width = resolution - 2
	return plane_mesh.get_mesh_arrays()
	"""
	var vertices := PoolVector3Array()
	vertices.resize(resolution * resolution)
	for zi in range(resolution):
		for xi in range(resolution):
			var x = lerp(-chunk_size * 0.5, chunk_size * 0.5, float(xi) / (resolution - 1))
			var z = lerp(-chunk_size * 0.5, chunk_size * 0.5, float(zi) / (resolution - 1))
			vertices.set(xi + zi * resolution, Vector3(x, 0.0, z))
	var normals := PoolVector3Array()
	normals.resize(resolution * resolution)
	for i in range(resolution * resolution):
		normals.set(i, Vector3(0.0, 1.0, 0.0))
	var tangents := PoolRealArray()
	tangents.resize(4 * resolution * resolution)
	for i in range(resolution * resolution):
		tangents.set(i * 4, 1.0)
		tangents.set(i * 4 + 1, 0.0)
		tangents.set(i * 4 + 2, 0.0)
		tangents.set(i * 4 + 3, 1.0)
	var uvs := PoolVector2Array()
	uvs.resize(resolution * resolution)
	for zi in range(resolution):
		for xi in range(resolution):
			uvs.set(xi + zi * resolution, Vector2(float(xi) / (resolution - 1), float(zi) / (resolution - 1)))
	var indices := PoolIntArray()
	indices.resize(6 * (resolution - 1) * (resolution - 1))
	for zi in range(resolution - 1):
		for xi in range(resolution - 1):
			indices.set((xi + zi * (resolution - 1)) * 6, xi + zi * resolution)
			indices.set((xi + zi * (resolution - 1)) * 6 + 1, xi + 1 + zi * resolution)
			indices.set((xi + zi * (resolution - 1)) * 6 + 2, xi + 1 + (zi + 1) * resolution)
			indices.set((xi + zi * (resolution - 1)) * 6 + 3, xi + zi * resolution)
			indices.set((xi + zi * (resolution - 1)) * 6 + 4, xi + 1 + (zi + 1) * resolution)
			indices.set((xi + zi * (resolution - 1)) * 6 + 5, xi + (zi + 1) * resolution)
	var arrays := []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_INDEX] = indices
	return arrays
