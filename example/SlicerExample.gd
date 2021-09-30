# This example scene cuts MeshInstance along the plane SlicePlane when "ui_select" is pressed.
# Use WASD to move on XZ plane, and Space/Shift to move on the Y axis
# Press left click to slice the mesh, hold right click to move the camera's rotation
extends Spatial

onready var mesh_instance = $MeshInstance
onready var slice_plane = $SlicePlane
onready var camera = $Camera
var plane
var sliced = false

# Camera movement variables
var move_speed = 5
var mouse_speed = 0.3
var mouse_delta

func _ready():
	# Set up slice plane
	var zero_vector = slice_plane.transform.xform(Vector3.ZERO)
	var forward_vector = slice_plane.transform.xform(Vector3.FORWARD)
	var right_vector = slice_plane.transform.xform(Vector3.RIGHT)
	
	zero_vector = mesh_instance.transform.xform_inv(zero_vector)
	forward_vector = mesh_instance.transform.xform_inv(forward_vector)
	right_vector = mesh_instance.transform.xform_inv(right_vector)
	
	plane = Plane(zero_vector, forward_vector, right_vector)


func _input(event):
	# Detect mouse movement
	if event is InputEventMouseMotion:
		mouse_delta = event.relative

func _process(delta):
	var velocity = Vector3.ZERO
	
	# Camera movement
	if Input.is_action_pressed("left"):
		velocity += Vector3.LEFT
	if Input.is_action_pressed("right"):
		velocity += Vector3.RIGHT
	if Input.is_action_pressed("forward"):
		velocity += Vector3.FORWARD
	if Input.is_action_pressed("back"):
		velocity += Vector3.BACK
	if Input.is_action_pressed("up"):
		velocity += Vector3.UP
	if Input.is_action_pressed("down"):
		velocity += Vector3.DOWN
	
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
#		camera.rotate_object_local(Vector3.RIGHT, delta * mouse_delta.y)
#		camera.rotate_object_local(Vector3.UP, delta * mouse_delta.x)
		camera.rotate(Vector3.UP, -1 * mouse_speed * delta * mouse_delta.x)
		camera.rotate_object_local(Vector3.RIGHT, -1 * mouse_speed * delta * mouse_delta.y)
		mouse_delta = Vector2.ZERO
	
	camera.translate_object_local(velocity.normalized() * delta * move_speed)
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT) and not sliced:
		sliced = true
		
		# Make the mesh into an ArrayMesh
		var surface_tool = SurfaceTool.new()
		surface_tool.create_from(mesh_instance.mesh, 0)
		var mesh = surface_tool.commit()
		
		var start = OS.get_ticks_usec()
		
		# Calculate mesh slices
		var meshes = Slicer.get_sliced_meshes (mesh, plane)
		
		print("Time to slice: " + str(float(OS.get_ticks_usec() - start) / 1000 ) + " ms")
	
		# Add upper mesh to scene
		var upper = MeshInstance.new()
		upper.mesh = meshes[0]
		upper.translation = mesh_instance.translation + 0.5 * Vector3.UP
		upper.rotation = mesh_instance.rotation
		add_child(upper)
	
		# Add lower mesh to scene
		var lower = MeshInstance.new()
		lower.mesh = meshes[1]
		lower.translation = mesh_instance.translation + 0.5 * Vector3.DOWN
		lower.rotation = mesh_instance.rotation
		add_child(lower)
		
		remove_child(mesh_instance)
		
		slice_plane.visible = false
