extends Spatial

var noise := OpenSimplexNoise.new()
var thread := Thread.new()
var mutex := Mutex.new()
var semaphore := Semaphore.new()
var exit_thread = false

#OS.get_processor_count()

func _ready():
	noise.octaves = 6
	noise.period = 80

	thread.start(self, "_thread_function")

	var timer := Timer.new()
	timer.connect("timeout", self, "_on_Timer_timeout")
	add_child(timer)
	timer.start(0.1)


func _on_Timer_timeout():
	semaphore.post()


func _should_exit():
	mutex.lock()
	var should_exit = exit_thread
	mutex.unlock()
	return should_exit


func _thread_function(_userdata):
	while true:
		semaphore.wait()
		if _should_exit():
			break

		var player_translation = $Player.translation
		var p_x := int(player_translation.x) / Chunk.SIZE
		var p_z := int(player_translation.z) / Chunk.SIZE

		var known_chunks := {}
		for node in get_children():
			var chunk := node as Chunk
			if chunk != null:
				known_chunks[[chunk.x, chunk.z]] = 1

		for x in range(p_x - Chunk.TRACK_AMOUNT, p_x + Chunk.TRACK_AMOUNT):
			for z in range(p_z - Chunk.TRACK_AMOUNT, p_z + Chunk.TRACK_AMOUNT):
				if not known_chunks.has([x, z]):
					var chunk = Chunk.new(noise, x, z, $Player)
					call_deferred("add_child", chunk)
					if _should_exit():
						break


func _exit_tree():
	mutex.lock()
	exit_thread = true
	mutex.unlock()
	semaphore.post()
	thread.wait_to_finish()
