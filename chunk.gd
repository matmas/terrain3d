extends Spatial
class_name Chunk

var x
var z
var mesh_instance: MeshInstance
var terrain
var terrain_generator

func _init(x, z, resolution, terrain):
	self.x = x
	self.z = z
	self.translation = Vector3(x * terrain.chunk_size, 0, z * terrain.chunk_size)
	self.terrain = terrain
	self.terrain_generator = TerrainGenerator.new()

	var arrays = terrain_generator.generate_arrays(resolution, terrain.chunk_size, x, z, terrain.curve, terrain.amplitude)
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
	var value = terrain.noise.get_noise_2d(x * terrain.chunk_size + point.x, z * terrain.chunk_size + point.y)  # from -1.0 to 1.0
	value = (value + 1.0) * 0.5  # from 0.0 to 1.0
	value = ease(value, terrain.curve)
	value = value * 2.0 - 1.0  # from -1.0 to 1.0
	value *= terrain.amplitude
	return value
