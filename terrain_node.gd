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
const Direction_ALL = [Direction.N, Direction.S, Direction.W, Direction.E]


func _init(parent, position: Vector3, size: float, resolution: int):
	self.parent = parent
	self.position = position
	self.size = size
	self.resolution = resolution
	var parent_position = parent.position if parent != null else Vector3.ZERO
	self.translation = position - parent_position


func update_tree_structure(max_screen_space_vertex_error):
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
			child.update_tree_structure(max_screen_space_vertex_error)


func get_nodes_to_update(additional_nodes):
	var nodes = []
	if should_be_split:
		if mesh_instance:
			nodes = [self]  # split it
			for n in _get_all_smaller_neighbors():
				additional_nodes[n] = true

		for child in children:
			nodes += child.get_nodes_to_update(additional_nodes)
	else:
		if mesh_instance:
			pass  # keep it merged
		else:
			if children:
				nodes = [self]  # merge children
				for n in _get_all_smaller_neighbors():
					additional_nodes[n] = true
			else:
				nodes = [self]  # generate missing mesh_instance
	return nodes


func get_all_nodes_to_update():
	var additional_nodes = {}
	var nodes_to_update = get_nodes_to_update(additional_nodes)
	for node in additional_nodes:
		if not nodes_to_update.has(node):
			nodes_to_update.append(node)
	return nodes_to_update


func update_nodes(terrain):
	for node in get_all_nodes_to_update():
		node.update(terrain)

#if len(chunks_to_create) == OS.get_processor_count():
#	_create_chunks(chunks, chunks_to_create)
#var threads := []
#for child in children:
#    var thread := Thread.new()
#    thread.start(child, "update_mesh", terrain)
#    threads.append(thread)
#for thread in threads:
#    thread.wait_to_finish()


func update(terrain):
	if should_be_split:
		if mesh_instance:  # split it
			mesh_instance.queue_free()
			mesh_instance = null
	else:
		if children:  # merge children
			for child in self.children:
				child.queue_free()
			self.children.clear()

		if mesh_instance:  # merged already, just regenerate
			mesh_instance.queue_free()
			mesh_instance = null
			generate_mesh_instance(terrain)
		else:
			# generate missing mesh_instance
			generate_mesh_instance(terrain)


func generate_mesh_instance(terrain):
	var terrain_generator = TerrainGenerator.new()
	terrain_generator.set_params(terrain.noise_seed, terrain.frequency, terrain.octaves, terrain.lacunarity, terrain.gain, terrain.curve, terrain.amplitude)
	var arrays = terrain_generator.generate_arrays(self.resolution, self.size, Vector2(self.position.x, self.position.z),
		_should_reduce(Direction.N),
		_should_reduce(Direction.S),
		_should_reduce(Direction.W),
		_should_reduce(Direction.E))
	call_deferred("_create_mesh", arrays)


func _create_mesh(arrays):
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, preload("res://terrain.material"))
	self.mesh_instance = MeshInstance.new()
	self.mesh_instance.mesh = mesh
	self.mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)


func _should_reduce(direction):
	var neighbor = _get_neighbor_of_greater_or_equal_size(direction)
	if not neighbor:
		return false
	return self.size < neighbor.size


func _get_neighbor_of_greater_or_equal_size(direction):
	if not parent:
		return null
	if direction == Direction.N:
		if parent._children()[Child.SE] == self:
			return parent._children()[Child.NE]
		if parent._children()[Child.SW] == self:
			return parent._children()[Child.NW]
	if direction == Direction.S:
		if parent._children()[Child.NE] == self:
			return parent._children()[Child.SE]
		if parent._children()[Child.NW] == self:
			return parent._children()[Child.SW]
	if direction == Direction.W:
		if parent._children()[Child.NE] == self:
			return parent._children()[Child.NW]
		if parent._children()[Child.SE] == self:
			return parent._children()[Child.SW]
	if direction == Direction.E:
		if parent._children()[Child.NW] == self:
			return parent._children()[Child.NE]
		if parent._children()[Child.SW] == self:
			return parent._children()[Child.SE]
	var node = self.parent._get_neighbor_of_greater_or_equal_size(direction)
	if not node or not node._children():
		return node
	if direction == Direction.N:
		return node._children()[Child.SW] if parent._children()[Child.NW] == self else node._children()[Child.SE]
	if direction == Direction.S:
		return node._children()[Child.NW] if parent._children()[Child.SW] == self else node._children()[Child.NE]
	if direction == Direction.W:
		return node._children()[Child.NE] if parent._children()[Child.NW] == self else node._children()[Child.SE]
	if direction == Direction.E:
		return node._children()[Child.NW] if parent._children()[Child.NE] == self else node._children()[Child.SW]


func _find_neighbors_of_smaller_size(neighbor, direction):
	var candidates = [] if neighbor == null else [neighbor]
	var neighbors = []
	while len(candidates) > 0:
		if candidates[0]._children() == []:
			neighbors.append(candidates[0])
		else:
			if direction == Direction.N:
				candidates.append(candidates[0]._children()[Child.SW])
				candidates.append(candidates[0]._children()[Child.SE])
			if direction == Direction.S:
				candidates.append(candidates[0]._children()[Child.NW])
				candidates.append(candidates[0]._children()[Child.NE])
			if direction == Direction.W:
				candidates.append(candidates[0]._children()[Child.NE])
				candidates.append(candidates[0]._children()[Child.SE])
			if direction == Direction.E:
				candidates.append(candidates[0]._children()[Child.NW])
				candidates.append(candidates[0]._children()[Child.SW])
		candidates.remove(0)
	return neighbors


func _get_neighbors(direction):
  var neighbor = _get_neighbor_of_greater_or_equal_size(direction)
  return _find_neighbors_of_smaller_size(neighbor, direction)


func _get_all_smaller_neighbors():
	var smaller_neighbors = []
	for direction in Direction_ALL:
		var neighbors = _get_neighbors(direction)
		if len(neighbors) > 1:
			smaller_neighbors += neighbors
	return smaller_neighbors


func _children():  # Omits children to be deleted soon
	return children if should_be_split else []


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
