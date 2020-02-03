tool
extends Spatial
class_name Terrain

onready var player = $"../Player"

export(int, 0, 20) var radius = 8
export(float) var chunk_size = 64 setget _set_chunk_size
export(int, 2, 129) var resolution = 33 setget _set_resolution
export(float) var amplitude = 80 setget _set_amplitude
export(float, EASE) var curve = 1 setget _set_curve
export(OpenSimplexNoise) var noise setget _set_noise

var observer_thread := Thread.new()
var semaphore := BinarySemaphore.new()
var should_exit = false
var should_exit_mutex := Mutex.new()
var should_refresh = false
var should_refresh_mutex := Mutex.new()
var plane_mesh_arrays: Array


func _ready():
	_generate_plane_mesh()

	observer_thread.start(self, "_observer_thread")

	var timer := Timer.new()
	timer.connect("timeout", self, "_on_Timer_timeout")
	add_child(timer)
	timer.start(0.1)


func _generate_plane_mesh():
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_depth = resolution - 2
	plane_mesh.subdivide_width = resolution - 2
	plane_mesh_arrays = plane_mesh.get_mesh_arrays()


func _on_Timer_timeout():
	semaphore.post()


func _observer_thread(_userdata):
	var chunks := {}
	var chunks_to_create := []

	while true:
		semaphore.wait()
		if _should_exit():
			break

		if _should_refresh():
			for xz in chunks:
				chunks[xz].queue_free()
			chunks.clear()
			_set_refresh(false)

		var p_x := int(round(player.translation.x / chunk_size))
		var p_z := int(round(player.translation.z / chunk_size))

		var chunks_to_delete := chunks.duplicate()

		for xz in _get_neighbor_coords(p_x, p_z, radius):
			if chunks.has(xz):
				chunks_to_delete.erase(xz)
			else:
				if len(chunks_to_create) == OS.get_processor_count():
					_create_chunks(chunks, chunks_to_create)
				chunks_to_create.append(xz)
				if _should_exit():
					break
		_create_chunks(chunks, chunks_to_create)

		for xz in chunks_to_delete:
			chunks[xz].queue_free()
			chunks.erase(xz)


func _get_neighbor_coords(x: int, z: int, radius: int):
	assert(radius >= 0)
	var coords := [[x, z]]
	for r in range(1, radius + 1):
		for i in range(-r, r + 1):
			coords.append([x + i, z - r])
			coords.append([x + i, z + r])
		for i in range(-(r - 1), (r - 1) + 1):
			coords.append([x - r, z + i])
			coords.append([x + r, z + i])
	return coords


func _create_chunks(chunks, chunks_to_create):
	var threads := []
	for xz in chunks_to_create:
		var thread := Thread.new()
		thread.start(self, "_create_chunk", xz)
		threads.append(thread)
	chunks_to_create.clear()
	for thread in threads:
		var chunk = thread.wait_to_finish()
		chunks[[chunk.x, chunk.z]] = chunk


func _create_chunk(xz) -> Chunk:
	var chunk := Chunk.new(noise if noise else OpenSimplexNoise.new(), xz[0], xz[1], self)
	call_deferred("add_child", chunk)
	return chunk


func _exit_tree():
	_set_exit(true)
	semaphore.post()
	if observer_thread.is_active():  # Avoid "Thread must exist to wait for its completion." error in editor output
		observer_thread.wait_to_finish()


func _should_exit():
	should_exit_mutex.lock()
	var value = should_exit
	should_exit_mutex.unlock()
	return value


func _set_exit(value):
	should_exit_mutex.lock()
	should_exit = value
	should_exit_mutex.unlock()


func _should_refresh():
	should_refresh_mutex.lock()
	var value = should_refresh
	should_refresh_mutex.unlock()
	return value


func _set_refresh(value):
	should_refresh_mutex.lock()
	should_refresh = value
	should_refresh_mutex.unlock()


func _set_chunk_size(value):
	chunk_size = value
	_generate_plane_mesh()
	_set_refresh(true)


func _set_resolution(value):
	if value <= 3:
		resolution = clamp(value, 2, 129)
	else:
		resolution = nearest_po2(value - 1) + 1
	_generate_plane_mesh()
	_set_refresh(true)


func _set_curve(value):
	curve = value
	_set_refresh(true)


func _set_amplitude(value):
	amplitude = value
	_set_refresh(true)


func _set_noise(value):
	noise = value
	_set_refresh(true)
	if noise:
		if not noise.is_connected("changed", self, "_on_noise_changed"):
			noise.connect("changed", self, "_on_noise_changed")


func _on_noise_changed():
	_set_refresh(true)


func get_plane_mesh_arrays():
	return plane_mesh_arrays.duplicate(true)
