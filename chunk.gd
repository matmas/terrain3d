tool
extends Spatial
class_name Chunk

const SIZE = 64

var noise: OpenSimplexNoise
var x
var z
var mesh_instance: MeshInstance
var terrain


func _init(noise, x, z, terrain):
	self.noise = noise
	self.x = x
	self.z = z
	self.translation = Vector3(x * SIZE, 0, z * SIZE)
	self.terrain = terrain

	var arrays = terrain.get_plane_mesh_arrays()

	# Adjust vertices
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	for i in range(len(vertices)):
		var point = Vector2(vertices[i].x, vertices[i].z)
		var height := _height(point)
		arrays[Mesh.ARRAY_VERTEX][i].y = height
		var delta = Vector2(vertices[i].length() / 80, 0)
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
	var value = noise.get_noise_3d(x * SIZE + point.x, 0, z * SIZE + point.y)  # from -1.0 to 1.0
	value = (value + 1.0) * 0.5  # from 0.0 to 1.0
	value = ease(value, terrain.curve)
	value = value * 2.0 - 1.0  # from -1.0 to 1.0
	value *= 80
	return value
