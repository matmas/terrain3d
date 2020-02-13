tool
extends Node
class_name NoiseLayer

enum NoiseType { Value, ValueFractal, Perlin, PerlinFractal, Simplex, SimplexFractal, Cellular, WhiteNoise, Cubic, CubicFractal }
enum FractalType { FBM, Billow, RigidMulti }  # Applicable for ValueFractal, PerlinFractal and SimplexFractal NoiseType
enum Interpolation { Linear, Hermite, Quintic }  # Applicable for Value, Perlin, Cubic and CubicFractal NoiseType

export(bool) var enabled = true setget _set_enabled
export(NoiseType) var noise_type = NoiseType.SimplexFractal setget _set_noise_type
export(FractalType) var fractal_type = FractalType.FBM setget _set_fractal_type
export(Interpolation) var interpolation = Interpolation.Quintic setget _set_interpolation
export(int) var _seed = 0 setget _set_seed
export(float, 0.0, 0.01) var frequency = 0.0001 setget _set_frequency
export(int, 1, 6) var octaves = 3 setget _set_octaves
export(float, 0.1, 4.0) var lacunarity = 4.0 setget _set_lacunarity
export(float, 0.0, 1.0) var gain = 0.164 setget _set_gain
export(float, EASE) var curve = 1.0 setget _set_curve
export(float) var amplitude = 25.0 setget _set_amplitude


func _enter_tree():
	get_parent().refresh()


func _exit_tree():
	get_parent().refresh()


func _refresh_parent():
	if get_parent():
		get_parent().refresh()


func _set_enabled(value):
	enabled = value
	_refresh_parent()


func _set_noise_type(value):
	noise_type = value
	_refresh_parent()


func _set_fractal_type(value):
	fractal_type = value
	_refresh_parent()


func _set_interpolation(value):
	interpolation = value
	_refresh_parent()


func _set_seed(value):
	_seed = value
	_refresh_parent()


func _set_frequency(value):
	frequency = value
	_refresh_parent()


func _set_octaves(value):
	octaves = value
	_refresh_parent()


func _set_lacunarity(value):
	lacunarity = value
	_refresh_parent()


func _set_gain(value):
	gain = value
	_refresh_parent()


func _set_curve(value):
	curve = value
	_refresh_parent()


func _set_amplitude(value):
	amplitude = value
	_refresh_parent()
