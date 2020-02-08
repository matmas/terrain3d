extends Spatial
class_name TerrainNode

var position: Vector3
var size: float
var resolution: int

var parent
var should_be_split = false
var children = []
var mesh_instance: MeshInstance


enum Child { NW, NE, SW, SE }
enum Direction { N, S, W, E }


func _init(parent, position: Vector3, size: float, resolution: int):
	self.parent = parent
	self.position = position
	self.size = size
	self.resolution = resolution
	var parent_position = parent.position if parent != null else Vector3.ZERO
	self.translation = position - parent_position


func update_structure(max_screen_space_vertex_error):
	should_be_split = (_screen_space_vertex_error() > max_screen_space_vertex_error)
	if should_be_split:
		if children == []:
			for zi in range(2):
				for xi in range(2):
					var child_offset = Vector3((xi * 2 - 1) * size / 4, 0.0, (zi * 2 - 1) * size / 4)
					var child_size = size / 2
					var child = load("res://terrain_node.gd").new(self, self.position + child_offset, child_size, self.resolution)
					children.append(child)
					call_deferred("add_child", child)
		for child in children:
			child.update_structure(max_screen_space_vertex_error)


func update_mesh(terrain):
	if should_be_split:
		var threads := []
		for child in children:
			var thread := Thread.new()
			thread.start(child, "update_mesh", terrain)
			threads.append(thread)
		for thread in threads:
			thread.wait_to_finish()

		if mesh_instance != null:
			mesh_instance.queue_free()
			mesh_instance = null
	else:
		if mesh_instance == null:
			var terrain_generator = TerrainGenerator.new()
			terrain_generator.set_params(terrain.noise_seed, terrain.frequency, terrain.octaves, terrain.lacunarity, terrain.gain, terrain.curve, terrain.amplitude)
			var arrays = terrain_generator.generate_arrays(self.resolution, self.size, Vector2(self.position.x, self.position.z),
				_should_reduce(Direction.N),
				_should_reduce(Direction.S),
				_should_reduce(Direction.W),
				_should_reduce(Direction.E))
			var mesh = ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh.surface_set_material(0, preload("res://terrain.material"))
			mesh_instance = MeshInstance.new()
			mesh_instance.mesh = mesh
			mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
			call_deferred("add_child", mesh_instance)
			for child in children:
				child.queue_free()
			children.clear()


func _should_reduce(direction):
	var neighbor = _get_neighbor(direction)
	if not neighbor:
		return false
	return self.size < neighbor.size


func _get_neighbor(direction):
	if not parent:
		return null
	if direction == Direction.N:
		if parent.children[Child.SE] == self:
			return parent.children[Child.NE]
		if parent.children[Child.SW] == self:
			return parent.children[Child.NW]
	if direction == Direction.S:
		if parent.children[Child.NE] == self:
			return parent.children[Child.SE]
		if parent.children[Child.NW] == self:
			return parent.children[Child.SW]
	if direction == Direction.W:
		if parent.children[Child.NE] == self:
			return parent.children[Child.NW]
		if parent.children[Child.SE] == self:
			return parent.children[Child.SW]
	if direction == Direction.E:
		if parent.children[Child.NW] == self:
			return parent.children[Child.NE]
		if parent.children[Child.SW] == self:
			return parent.children[Child.SE]
	var node = self.parent._get_neighbor(direction)
	if not node or not node.children:
		return node
	if direction == Direction.N:
		return node.children[Child.SW] if parent.children[Child.NW] == self else node.children[Child.SE]
	if direction == Direction.S:
		return node.children[Child.NW] if parent.children[Child.SW] == self else node.children[Child.NE]
	if direction == Direction.W:
		return node.children[Child.NE] if parent.children[Child.NW] == self else node.children[Child.SE]
	if direction == Direction.E:
		return node.children[Child.NW] if parent.children[Child.NE] == self else node.children[Child.SW]


func _screen_space_vertex_error():
	var viewport = get_viewport()
	if viewport == null:  # Happens at startup
		return 0
	var camera = viewport.get_camera()
	var camera_position = camera.get_global_transform().origin
	var geometric_error = self.size / (self.resolution - 1)
	var viewport_width = viewport.get_visible_rect().size.x
	var perspective_scaling_factor = viewport_width / (2.0 * tan(deg2rad(camera.fov) / 2.0))
	var distance = clamp(camera_position.distance_to(self.position) - self.size, 0.001, 10000)
	return geometric_error * perspective_scaling_factor / distance
