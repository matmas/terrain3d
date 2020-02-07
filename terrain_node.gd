extends Spatial
class_name TerrainNode

var position: Vector3
var size: float
var resolution: int

var parent: TerrainNode
var children = []
var mesh_instance: MeshInstance


func _init(parent: TerrainNode, position: Vector3, size: float, resolution: int):
	self.parent = parent
	self.position = position
	self.size = size
	self.resolution = resolution
	var parent_position = Vector3.ZERO
	if parent != null:
		parent_position = parent.position
	self.translation = position - parent_position


func update(terrain, camera_position: Vector3):
	if mesh_instance == null:
		var terrain_generator = TerrainGenerator.new()
		terrain_generator.set_params(terrain.noise_seed, terrain.frequency, terrain.octaves, terrain.lacunarity, terrain.gain, terrain.curve, terrain.amplitude)
		var arrays = terrain_generator.generate_arrays(self.resolution, self.size, Vector2(self.position.x, self.position.z))
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, preload("res://terrain.material"))
		mesh_instance = MeshInstance.new()
		mesh_instance.mesh = mesh
		mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
		call_deferred("add_child", mesh_instance)

	var distance = camera_position.distance_to(self.position) - self.size
	if distance < 10 and resolution < terrain.MAX_RESOLUTION:
		mesh_instance.visible = false
		if children == []:
			for i in [-1, 1]:
				for j in [-1, 1]:
					var child_offset = Vector3(i * size / 4, 0.0, j * size / 4)
					var child = load("res://terrain_node.gd").new(self, self.position + child_offset, size / 2, resolution)
					children.append(child)
					call_deferred("add_child", child)
		for child in children:
			child.update(terrain, camera_position)
