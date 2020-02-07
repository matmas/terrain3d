tool
extends Spatial
class_name Terrain

onready var player = $"../Player"

const MAX_RESOLUTION = 257
enum Resolution {
	_2 = 2,
	_3 = 3,
	_5 = 5,
	_9 = 9,
	_17 = 17,
	_33 = 33,
	_65 = 65,
	_129 = 129,
	_257 = 257,
	_513 = 513,
}
export(float) var size = 10000.0 setget _set_size
export(Resolution) var resolution = Resolution._33 setget _set_resolution
export(float) var amplitude = 25.0 setget _set_amplitude
export(float, EASE) var curve = 1 setget _set_curve
export(int) var noise_seed = 0 setget _set_noise_seed
export(float, 0.00390625, 10.0) var frequency = 1.0 / 64 setget _set_frequency
export(int, 1, 6) var octaves = 3 setget _set_octaves
export(float, 0.1, 4.0) var lacunarity = 2.0 setget _set_lacunarity
export(float, 0.0, 1.0) var gain = 0.164 setget _set_gain

var observer_thread := Thread.new()
var semaphore := BinarySemaphore.new()
var should_exit = false
var should_exit_mutex := Mutex.new()
var should_refresh = false
var should_refresh_mutex := Mutex.new()
var root: TerrainNode


func _get_new_root():
	return TerrainNode.new(null, Vector3.ZERO, self.size, self.resolution)


func _ready():
	root = _get_new_root()
	add_child(root)

	observer_thread.start(self, "_observer_thread")

	var timer := Timer.new()
	timer.connect("timeout", self, "_on_Timer_timeout")
	add_child(timer)
	timer.start(0.1)


func _on_Timer_timeout():
	semaphore.post()


func _observer_thread(_userdata):
	while true:
		semaphore.wait()
		if _should_exit():
			break

		if _should_refresh():
			_set_refresh(false)
			root.queue_free()
			root = _get_new_root()
			call_deferred("add_child", root)

		root.update(self, player.translation)


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


func _set_size(value):
	size = value
	_set_refresh(true)


func _set_resolution(value):
	if value <= 3:
		resolution = clamp(value, 2, MAX_RESOLUTION)
	else:
		resolution = nearest_po2(value - 1) + 1
	_set_refresh(true)


func _set_curve(value):
	curve = value
	_set_refresh(true)


func _set_amplitude(value):
	amplitude = value
	_set_refresh(true)


func _set_noise_seed(value):
	noise_seed = value
	_set_refresh(true)


func _set_frequency(value):
	frequency = value
	_set_refresh(true)


func _set_octaves(value):
	octaves = value
	_set_refresh(true)


func _set_lacunarity(value):
	lacunarity = value
	_set_refresh(true)


func _set_gain(value):
	gain = value
	_set_refresh(true)
