extends Spatial
class_name Chunk

const SIZE = 64

var noise: OpenSimplexNoise
var x
var z
var mesh_instance: MeshInstance


func _init(noise, x, z):
	self.noise = noise
	self.x = x
	self.z = z
	self.translation = Vector3(x * SIZE, 0, z * SIZE)

	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(SIZE, SIZE)
	plane_mesh.subdivide_depth = SIZE / 2
	plane_mesh.subdivide_width = SIZE / 2
	plane_mesh.material = preload("res://terrain.material")
	var surface_tool := SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var mesh = surface_tool.commit()

	# Adjust vertices
#	for i in range(len(plane_arr[Mesh.ARRAY_VERTEX])):
#		var vertex = plane_arr[Mesh.ARRAY_VERTEX][i]
#		plane_arr[Mesh.ARRAY_VERTEX][i].y = noise.get_noise_3d(x * SIZE + vertex.x, vertex.y, z * SIZE + vertex.z) * 80

	# Load ArrayMesh into MeshDataTool
	var data_tool := MeshDataTool.new()
	data_tool.create_from_surface(mesh, 0)

	# Adjust vertices
	for i in range(data_tool.get_vertex_count()):
		var vertex := data_tool.get_vertex(i)
		vertex.y = noise.get_noise_3d(x * SIZE + vertex.x, vertex.y, z * SIZE + vertex.z) * 80
		data_tool.set_vertex(i, vertex)

#	# Remove all ArrayMesh surfaces
	for s in range(mesh.get_surface_count()):
		mesh.surface_remove(s)

#	# Save to ArrayMesh
	data_tool.commit_to_surface(mesh)

#	# Calculate normals
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(mesh, 0)
	surface_tool.generate_normals()

	mesh_instance = MeshInstance.new()
	mesh_instance.mesh = surface_tool.commit()
	mesh_instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	mesh_instance.create_trimesh_collision()
#	OS.delay_msec(100)


func _ready():
	add_child(mesh_instance)
