tool
extends Spatial
class_name Terrain

enum Resolution {
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
enum Ratio {
	_1_to_1 = 1,
	_2_to_1 = 2,
	_4_to_1 = 4,
	_8_to_1 = 8,
	_16_to_1 = 16,
	_32_to_1 = 32,
}
export(float) var max_screen_space_vertex_error = 100000.0 setget _set_max_screen_space_vertex_error
export(float) var size = 10000.0 setget _set_size
export(Resolution) var resolution = Resolution._129 setget _set_resolution
export(Ratio) var mesh_to_physics_mesh_ratio = 16 setget _set_mesh_to_physics_mesh_ratio

var observer_thread := Thread.new()
var semaphore := BinarySemaphore.new()
var should_exit = false
var should_exit_mutex := Mutex.new()
var should_refresh = false
var should_refresh_mutex := Mutex.new()
var root: TerrainNode

const USE_THREADS = true


func _get_new_root():
	var terrain_generator = TerrainGenerator.new()
	for node in get_children():
		var layer := node as NoiseLayer
		if layer:
			terrain_generator.add_params(layer.noise_type, layer.fractal_type, layer.interpolation, layer._seed, layer.frequency, layer.octaves, layer.lacunarity, layer.gain, layer.curve, layer.amplitude)
	return TerrainNode.new(null, self, terrain_generator, Vector3.ZERO, self.size, self.resolution)


func _ready():
	root = _get_new_root()
	add_child(root)

	observer_thread.start(self, "_observer_thread")

	var timer := Timer.new()
	timer.connect("timeout", self, "_on_Timer_timeout")
	add_child(timer)
	timer.start(0.1)


func _on_Timer_timeout():
	if USE_THREADS:
		semaphore.post()
	else:
		root.update()


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

		root.update()


func refresh():
	_set_refresh(true)


func _exit_tree():
	_set_exit(true)
	semaphore.post()
	if observer_thread.is_active():  # Avoid "Thread must exist to wait for its completion." error in editor output
		observer_thread.wait_to_finish()


# Getters and setters with mutexes:


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


# Setters of exported variables:


func _set_max_screen_space_vertex_error(value):
	max_screen_space_vertex_error = value
	_set_refresh(true)


func _set_size(value):
	size = value
	_set_refresh(true)


func _set_resolution(value):
	if (value - 1) / mesh_to_physics_mesh_ratio > 2:
		resolution = value
		_set_refresh(true)


func _set_mesh_to_physics_mesh_ratio(value):
	if (resolution - 1) / value > 2:
		mesh_to_physics_mesh_ratio = value
		_set_refresh(true)
