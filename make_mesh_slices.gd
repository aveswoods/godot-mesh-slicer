# Author: Ava Z. Beaver
# (MIT License)
# ---
# Link to repository:
#
# This script provides a function for slicing meshes along a plane.
#
# This is intended for meshes with lower face-counts, since it is a "perfect" slice. Meaning,
# each face that is sliced through is mapped perfectly to the "upper" or "lower" mesh by creating
# three new faces. There is no synthesis to reduce the number of faces by eliminating possible
# redundancy.
# Further, this is intended for real-time mesh slicing, so low time complexity was prioritized.
#
# UV maps are *NOT* created, currently.
#
# Lastly, slices are constructed with the exact vertices as before. They are not recentered
# based on their new true center, which may cause bugs when physics are applied. This will be
# investigated later along with a possible solution.
extends Node

class_name Slicer

# Slicing function
# ---
# The mesh must be an ArrayMesh, since that is how data is read with the MeshDataTool. Any Mesh can
# be converted to ArrayMesh with SurfaceTool
# Link: https://docs.godotengine.org/en/stable/classes/class_surfacetool.html
static func get_sliced_meshes(mesh: ArrayMesh, plane: Plane = Plane(Vector3(1, 0, 0), 0)):
	
	# MeshDataTool used for reading the Mesh
	var mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(mesh, 0)
	
	# SurfaceTools for making the new meshes
	var surface_tool_upper = SurfaceTool.new()
	surface_tool_upper.begin(Mesh.PRIMITIVE_TRIANGLES)
	var surface_tool_lower = SurfaceTool.new()
	surface_tool_lower.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var num_faces = mesh_data_tool.get_face_count()
	
	# Keeps track of distances of every vertex to the plane, so it only needs to be computed once
	var dist_from_plane = {}
	
	# Keeps track of which edges are on the border of a slice, stored as duples
	var border_edges = []
	# Center of the border edges, calculated as the average of the edge vertices
	var border_center = Vector3.ZERO
	
	# Values for vertices in a face
	var vertex_index0
	var vertex0
	var hemisphere0 # 1 if upper, -1 if lower
	var vertex_index1
	var vertex1
	var hemisphere1
	var vertex_index2
	var vertex2
	var hemisphere2
	
	# Go through each face
	for i in num_faces:
		# Calculate distances of each vertex to the plane, and which hemisphere it is a part of
		vertex_index0 = mesh_data_tool.get_face_vertex(i, 0)
		vertex0 = mesh_data_tool.get_vertex(vertex_index0)
		if not dist_from_plane.has(vertex_index0):
			dist_from_plane[vertex_index0] = plane.distance_to(vertex0)
		hemisphere0 = sign(dist_from_plane[vertex_index0])
		
		vertex_index1 = mesh_data_tool.get_face_vertex(i, 1)
		vertex1 = mesh_data_tool.get_vertex(vertex_index1)
		if not dist_from_plane.has(vertex_index1):
			dist_from_plane[vertex_index1] = plane.distance_to(vertex1)
		hemisphere1 = sign(dist_from_plane[vertex_index1])
		
		vertex_index2 = mesh_data_tool.get_face_vertex(i, 2)
		vertex2 = mesh_data_tool.get_vertex(vertex_index2)
		if not dist_from_plane.has(vertex_index2):
			dist_from_plane[vertex_index2] = plane.distance_to(vertex2)
		hemisphere2 = sign(dist_from_plane[vertex_index2])
		
		# If any two vertices are identical, skip this iteration
		if vertex0.is_equal_approx(vertex1) or vertex0.is_equal_approx(vertex2) or vertex1.is_equal_approx(vertex2):
			continue
		
		# Find which mesh the face should be a part of. This involves finding whether it is on the
		# border between the two, and how to make new faces in this case
		# ---
		# If all in the same hemisphere, add the face to the new mesh.
		# If one is not in the same hemisphere and on the border, add the face to the new mesh
		# as if it were not on the border.
		# If one is not in the same hemisphere and not on the border, make new faces in the new
		# meshes.
		# ---
		# This is done by finding the intersect between the edges that cross the slice and the
		# slice plane. Then, new faces are constructed. The way the vertices are added depends
		# on OpenGL's winding order. That is, every *ordered* three vertices form *one* face,
		# whose front follows the winding order.
		# Link: https://learnopengl.com/Advanced-OpenGL/Face-culling
		# ---
		# The mess of if-else's below determines which vertices in the original winding order
		# are in the upper and lower meshes, and how to make the new meshes with the correct
		# winding order. Every case is, in essense, identical; the difference being the order
		# of the vertices being added.
		
		# All in the same hemisphere
		if hemisphere0 == hemisphere1 and hemisphere1 == hemisphere2:
			# Lower
			if hemisphere0 == -1:
				surface_tool_lower.add_vertex(vertex0)
				surface_tool_lower.add_vertex(vertex1)
				surface_tool_lower.add_vertex(vertex2)
			# Upper
			elif hemisphere0 == 1:
				surface_tool_upper.add_vertex(vertex0)
				surface_tool_upper.add_vertex(vertex1)
				surface_tool_upper.add_vertex(vertex2)
			# Do nothing if they are all on the border
		
		# 0 and 1 in the same hemisphere
		elif hemisphere0 == hemisphere1:
			# Lower
			if hemisphere0 == -1:
				if hemisphere2 == 0:
					surface_tool_lower.add_vertex(vertex0)
					surface_tool_lower.add_vertex(vertex1)
					surface_tool_lower.add_vertex(vertex2)
				else:
					# Find intersect point between 0 and 2 with the plane, and 1 and 2 with
					# the plane
					var intersect0 = plane.intersects_segment(vertex0, vertex2)
					var intersect1 = plane.intersects_segment(vertex1, vertex2)
					
					# Add triangles
					surface_tool_lower.add_vertex(intersect1)
					surface_tool_lower.add_vertex(intersect0)
					surface_tool_lower.add_vertex(vertex0)
					
					surface_tool_lower.add_vertex(vertex0)
					surface_tool_lower.add_vertex(vertex1)
					surface_tool_lower.add_vertex(intersect1)
					
					surface_tool_upper.add_vertex(vertex2)
					surface_tool_upper.add_vertex(intersect0)
					surface_tool_upper.add_vertex(intersect1)
					
					# Add border edge
					border_edges.append([
						intersect1,
						intersect0
					])
					border_center += intersect0
					border_center += intersect1
			
			# Upper
			elif hemisphere0 == 1:
				if hemisphere2 == 0:
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(vertex2)
				else:
					# Find intersect point between 0 and 2 with the plane, and 1 and 2 with
					# the plane
					var intersect0 = plane.intersects_segment(vertex0, vertex2)
					var intersect1 = plane.intersects_segment(vertex1, vertex2)
					
					# Add triangles
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(intersect1)
					
					surface_tool_upper.add_vertex(intersect1)
					surface_tool_upper.add_vertex(intersect0)
					surface_tool_upper.add_vertex(vertex0)
					
					surface_tool_lower.add_vertex(intersect0)
					surface_tool_lower.add_vertex(intersect1)
					surface_tool_lower.add_vertex(vertex2)
					
					# Add border edge
					border_edges.append([
						intersect0,
						intersect1
					])
					border_center += intersect0
					border_center += intersect1
			
			# Border
			else:
				if hemisphere2 == -1:
					# Face is in the lower hemisphere, with an edge on the border
					surface_tool_lower.add_vertex(vertex0)
					surface_tool_lower.add_vertex(vertex1)
					surface_tool_lower.add_vertex(vertex2)
				else:
					# Face is in the upper hemisphere, with an edge on the border
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(vertex2)
					
				border_edges.append([
					vertex0,
					vertex1
				])
				border_center += vertex0
				border_center += vertex1
		
		# 0 and 2 in the same hemisphere
		elif hemisphere0 == hemisphere2:
			# Lower
			if hemisphere0 == -1:
				if hemisphere1 == 0:
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(vertex2)
				else:
					var intersect0 = plane.intersects_segment(vertex0, vertex1)
					var intersect2 = plane.intersects_segment(vertex1, vertex2)
					
				# Add triangles
					surface_tool_lower.add_vertex(intersect0)
					surface_tool_lower.add_vertex(intersect2)
					surface_tool_lower.add_vertex(vertex2)
					
					surface_tool_lower.add_vertex(vertex2)
					surface_tool_lower.add_vertex(vertex0)
					surface_tool_lower.add_vertex(intersect0)
					
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(intersect2)
					surface_tool_upper.add_vertex(intersect0)
				
					# Add border edge
					border_edges.append([
						intersect0,
						intersect2
					])
					border_center += intersect0
					border_center += intersect2
			
			# Upper
			elif hemisphere0 == 1:
				if hemisphere1 == 0:
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(vertex2)
				else:
					# 0 and 2 in upper hemisphere
					var intersect0 = plane.intersects_segment(vertex0, vertex1)
					var intersect2 = plane.intersects_segment(vertex1, vertex2)
					
					# Add triangles
					surface_tool_upper.add_vertex(vertex2)
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(intersect0)
					
					surface_tool_upper.add_vertex(intersect0)
					surface_tool_upper.add_vertex(intersect2)
					surface_tool_upper.add_vertex(vertex2)
					
					surface_tool_lower.add_vertex(intersect2)
					surface_tool_lower.add_vertex(intersect0)
					surface_tool_lower.add_vertex(vertex1)
					
					# Add border edge
					border_edges.append([
						intersect2,
						intersect0
					])
					border_center += intersect0
					border_center += intersect2
			
			# Border
			else:
				if hemisphere1 == -1:
					# Face is in the lower hemisphere, with an edge on the border
					surface_tool_lower.add_vertex(vertex0)
					surface_tool_lower.add_vertex(vertex1)
					surface_tool_lower.add_vertex(vertex2)
				else:
					# Face is in the upper hemisphere, with an edge on the border
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(vertex2)
				
				border_edges.append([
					vertex0,
					vertex2
				])
				border_center += vertex0
				border_center += vertex2
		
		# 1 and 2 in the same hemisphere
		elif hemisphere1 == hemisphere2:
			# Lower
			if hemisphere1 == -1:
				if hemisphere0 == 0:
					surface_tool_lower.add_vertex(vertex0)
					surface_tool_lower.add_vertex(vertex1)
					surface_tool_lower.add_vertex(vertex2)
				else:
					var intersect1 = plane.intersects_segment(vertex0, vertex1)
					var intersect2 = plane.intersects_segment(vertex0, vertex2)
					
					# Add triangles
					surface_tool_lower.add_vertex(intersect2)
					surface_tool_lower.add_vertex(intersect1)
					surface_tool_lower.add_vertex(vertex1)
					
					surface_tool_lower.add_vertex(vertex1)
					surface_tool_lower.add_vertex(vertex2)
					surface_tool_lower.add_vertex(intersect2)
					
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(intersect1)
					surface_tool_upper.add_vertex(intersect2)
					
					# Add border edge
					border_edges.append([
						intersect2,
						intersect1
					])
					border_center += intersect1
					border_center += intersect2
			
			# Upper
			elif hemisphere1 == 1:
				if hemisphere0 == 0:
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(vertex2)
				else:
					var intersect1 = plane.intersects_segment(vertex0, vertex1)
					var intersect2 = plane.intersects_segment(vertex0, vertex2)
					
					# Add triangles
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(vertex2)
					surface_tool_upper.add_vertex(intersect2)
					
					surface_tool_upper.add_vertex(intersect2)
					surface_tool_upper.add_vertex(intersect1)
					surface_tool_upper.add_vertex(vertex1)
					
					surface_tool_lower.add_vertex(intersect1)
					surface_tool_lower.add_vertex(intersect2)
					surface_tool_lower.add_vertex(vertex0)
					
					# Add border edge
					border_edges.append([
						intersect1,
						intersect2
					])
					border_center += intersect1
					border_center += intersect2
			
			# Border
			else:
				if hemisphere0 == -1:
					# Face is in the lower hemisphere, with an edge on the border
					surface_tool_lower.add_vertex(vertex0)
					surface_tool_lower.add_vertex(vertex1)
					surface_tool_lower.add_vertex(vertex2)
				else:
					# Face is in the upper hemisphere, with an edge on the border
					surface_tool_upper.add_vertex(vertex0)
					surface_tool_upper.add_vertex(vertex1)
					surface_tool_upper.add_vertex(vertex2)
				
				border_edges.append([
					vertex1,
					vertex2
				])
				border_center += vertex1
				border_center += vertex2
		
		# All in different hemispheres
		else:
			if hemisphere0 == 0:
				var intersect = plane.intersects_segment(vertex1, vertex2)
				
				# Add triangles
				surface_tool_upper.add_vertex(vertex0)
				surface_tool_upper.add_vertex(vertex1)
				surface_tool_upper.add_vertex(intersect)
				
				surface_tool_lower.add_vertex(vertex2)
				surface_tool_lower.add_vertex(vertex0)
				surface_tool_lower.add_vertex(intersect)
				
				# Add border edge
				border_edges.append([
					vertex0,
					intersect
				])
				border_center += vertex0
				border_center += intersect
				
			elif hemisphere1 == 0:
				var intersect = plane.intersects_segment(vertex0, vertex2)
				
				# Add triangles
				surface_tool_upper.add_vertex(vertex1)
				surface_tool_upper.add_vertex(vertex2)
				surface_tool_upper.add_vertex(intersect)
				
				surface_tool_lower.add_vertex(vertex0)
				surface_tool_lower.add_vertex(vertex1)
				surface_tool_lower.add_vertex(intersect)
				
				border_edges.append([
					vertex1,
					intersect
				])
			
			else: # hemisphere2 == 0
				var intersect = plane.intersects_segment(vertex0, vertex1)
				
				# Add triangles
				surface_tool_upper.add_vertex(vertex2)
				surface_tool_upper.add_vertex(vertex0)
				surface_tool_upper.add_vertex(intersect)
				
				surface_tool_lower.add_vertex(vertex1)
				surface_tool_lower.add_vertex(vertex2)
				surface_tool_lower.add_vertex(intersect)
				
				border_edges.append([
					vertex2,
					intersect
				])
	
	# Create upper mesh border surfaces
	# ---
	# Again, this follows OpenGL's winding order.
	if border_edges.size() >= 3:
		# Find center vertex
		border_center /= 2.0 * border_edges.size()
		# Create faces by "fanning" around the center
		for edge in border_edges:
			surface_tool_upper.add_vertex(border_center)
			surface_tool_upper.add_vertex(edge[0])
			surface_tool_upper.add_vertex(edge[1])
			
			surface_tool_lower.add_vertex(edge[1])
			surface_tool_lower.add_vertex(edge[0])
			surface_tool_lower.add_vertex(border_center)
	
	# Create index arrays to shrink vertex arrays by using indices for face construction
	surface_tool_upper.index()
	surface_tool_lower.index()
	# Make normals
	surface_tool_upper.generate_normals()
	surface_tool_lower.generate_normals()
	
	# Return both meshes in a duple array
	return [surface_tool_upper.commit(), surface_tool_lower.commit()]
