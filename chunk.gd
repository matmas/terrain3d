extends Spatial
class_name Chunk

const SIZE = 64
const TRACK_AMOUNT = 8

var noise: OpenSimplexNoise
var x
var z
var tracker: Spatial
var mesh_instance: MeshInstance


func _init(noise, x, z, tracker: Spatial):
	self.noise = noise
	self.x = x
	self.z = z
	self.tracker = tracker
	self.translation = Vector3(x * SIZE, 0, z * SIZE)

	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(SIZE, SIZE)
	plane_mesh.subdivide_depth = SIZE / 2
	plane_mesh.subdivide_width = SIZE / 2

	var surface_tool := SurfaceTool.new()
	var data_tool := MeshDataTool.new()

	surface_tool.create_from(plane_mesh, 0)
	var array_plane := surface_tool.commit()
	data_tool.create_from_surface(array_plane, 0)

	for i in range(data_tool.get_vertex_count()):
		var vertex = data_tool.get_vertex(i)

		vertex.y = noise.get_noise_3d(x * SIZE + vertex.x, vertex.y, z * SIZE + vertex.z) * 80

		data_tool.set_vertex(i, vertex)

	for s in range(array_plane.get_surface_count()):
		array_plane.surface_remove(s)

	data_tool.commit_to_surface(array_plane)
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_plane, 0)
	surface_tool.generate_normals()

	mesh_instance = MeshInstance.new()
	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF


func _ready():
	add_child(mesh_instance)


func _process(_delta):
	var tx = int(tracker.translation.x) / SIZE
	var tz = int(tracker.translation.z) / SIZE
	if abs(tx - x) > TRACK_AMOUNT or abs(tz - z) > TRACK_AMOUNT:
		queue_free()
