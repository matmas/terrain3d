extends Spatial

const TRACK_AMOUNT = 8

var noise := OpenSimplexNoise.new()
var observer_thread := Thread.new()
var semaphore := Semaphore.new()
var exit_thread = false
var exit_thread_mutex := Mutex.new()

#OS.get_processor_count()

func _init():
	noise.octaves = 6
	noise.period = 80


func _ready():
#	var plane_mesh := PlaneMesh.new()
#	plane_mesh.size = Vector2(Chunk.SIZE, Chunk.SIZE)
#	plane_mesh.subdivide_depth = Chunk.SIZE / 2
#	plane_mesh.subdivide_width = Chunk.SIZE / 2
#	plane_mesh.material = load("res://terrain.material")
#	var surface_tool := SurfaceTool.new()
#	surface_tool.create_from(plane_mesh, 0)
#	mesh = surface_tool.commit()

	observer_thread.start(self, "_observer_thread")

	var timer := Timer.new()
	timer.connect("timeout", self, "_on_Timer_timeout")
	add_child(timer)
	timer.start(0.1)


func _on_Timer_timeout():
	semaphore.post()


func _should_exit():
	exit_thread_mutex.lock()
	var should_exit = exit_thread
	exit_thread_mutex.unlock()
	return should_exit


func _observer_thread(_userdata):
	var chunks := {}

	while true:
		semaphore.wait()
		if _should_exit():
			break

		var player_translation = $Player.translation
		var p_x := int(player_translation.x) / Chunk.SIZE
		var p_z := int(player_translation.z) / Chunk.SIZE

		var chunks_to_delete := chunks.duplicate()

		for x in range(p_x - TRACK_AMOUNT, p_x + TRACK_AMOUNT):
			for z in range(p_z - TRACK_AMOUNT, p_z + TRACK_AMOUNT):
				if chunks.has([x, z]):
					chunks_to_delete.erase([x, z])
				else:
					var chunk := Chunk.new(noise, x, z)
					chunks[[x, z]] = chunk
					call_deferred("add_child", chunk)
					if _should_exit():
						break

		for xz in chunks_to_delete:
			chunks[xz].queue_free()
			chunks.erase(xz)


func _exit_tree():
	exit_thread_mutex.lock()
	exit_thread = true
	exit_thread_mutex.unlock()
	semaphore.post()
	observer_thread.wait_to_finish()
