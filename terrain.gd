tool
extends Spatial
class_name Terrain

onready var player = $"../Player"

const RADIUS = 8

var noise := OpenSimplexNoise.new()
var observer_thread := Thread.new()
var semaphore := Semaphore.new()
var exit_thread = false
var exit_thread_mutex := Mutex.new()
var plane_mesh_arrays: Array


func _init():
	noise.octaves = 6
	noise.period = 80


func _ready():
	observer_thread.start(self, "_observer_thread")

	var timer := Timer.new()
	timer.connect("timeout", self, "_on_Timer_timeout")
	add_child(timer)
	timer.start(0.1)

	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(Chunk.SIZE, Chunk.SIZE)
	plane_mesh.subdivide_depth = Chunk.SIZE / 2
	plane_mesh.subdivide_width = Chunk.SIZE / 2
	plane_mesh_arrays = plane_mesh.get_mesh_arrays()


func _on_Timer_timeout():
	semaphore.post()


func _should_exit():
	exit_thread_mutex.lock()
	var should_exit = exit_thread
	exit_thread_mutex.unlock()
	return should_exit


func _observer_thread(_userdata):
	var chunks := {}
	var chunks_to_create := []

	while true:
		semaphore.wait()
		if _should_exit():
			break

		var p_x := int(player.translation.x) / Chunk.SIZE
		var p_z := int(player.translation.z) / Chunk.SIZE

		var chunks_to_delete := chunks.duplicate()

		for xz in _get_neighbor_coords(p_x, p_z, RADIUS):
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
	assert(radius > 0)
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
	var chunk := Chunk.new(noise, xz[0], xz[1], self)
	call_deferred("add_child", chunk)
	return chunk


func _exit_tree():
	exit_thread_mutex.lock()
	exit_thread = true
	exit_thread_mutex.unlock()
	semaphore.post()
	observer_thread.wait_to_finish()


func get_plane_mesh_arrays():
	return plane_mesh_arrays.duplicate(true)
