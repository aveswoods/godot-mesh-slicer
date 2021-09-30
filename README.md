# Mesh Slicer in the Godot Game Engine

An implementation and explanation for slicing an [`ArrayMesh`](https://docs.godotengine.org/en/stable/classes/class_arraymesh.html) with a [`Plane`](https://docs.godotengine.org/en/stable/classes/class_plane.html).

![Sample 1 cut](https://github.com/azbeaver/godot-mesh-slicer/blob/main/images/sample2_cut.png)

## About

There is a class called `Slicer` with one static function `get_sliced_meshes` that takes an `ArrayMesh` and a `Plane` as inputs and returns an array with two `ArrayMesh`'s.
The first one is the "upper" mesh, and the second is the "lower" mesh.

There is also an example project. The example slices the `MeshInstance` in the scene tree by the `SlicePlane`. These can be moved in the editor.

## Installing

To use the utility, I recommend downloading `make_mesh_slices.gd` directly and adding it to your project. This file contains the `Slicer` class.

To use the example, pull this repository and import it as a Godot project.

## Using

As long as `make_mesh_slices.gd` is in your project directory, you can use the slicing function by calling `Slicer.get_sliced_meshes` from any script.
As stated above, this function takes an `ArrayMesh` and `Plane` as its two parameters, and it returns an array with two new `ArrayMesh`'s.

This function was written to be as time-efficient as possible, intending for real-time slicing of meshes. As such, there may be redundant faces created as the result of a slice.
I recommend using meshes that have lower polygon counts.

The slices created by this function have normals generated before being returned. However, they currently do *not* have UV coordinates. I hope to implement this in the future.

When creating the `Plane`, assume the mesh is centered at **(0, 0, 0)** and is **not rotated**. This is because mesh vertices have their own local coordinates.
See the `_ready` function in `SlicerExample.gd` for a way to get the `Plane` based on global coordinates and rotations of a mesh and a slicing plane.

### Explanation

There is a step-by-step explanation of how this implementation works in the in-line comments of `make_mesh_slices.gd`. This includes helpful links and higher-level interpretations.
I recommend having the following pages open while reading:
- [Using the ArrayMesh](https://docs.godotengine.org/en/stable/tutorials/content/procedural_geometry/arraymesh.html)
- [Using the SurfaceTool](https://docs.godotengine.org/en/stable/tutorials/content/procedural_geometry/surfacetool.html)
- [Advanced vector math](https://docs.godotengine.org/en/stable/tutorials/math/vectors_advanced.html)
- [Plane](https://docs.godotengine.org/en/stable/classes/class_plane.html)

## Sample Photos

### 1.

![Sample 1 uncut](https://github.com/azbeaver/godot-mesh-slicer/blob/main/images/sample1_uncut.png)
![Sample 1 cut](https://github.com/azbeaver/godot-mesh-slicer/blob/main/images/sample1_cut.png)

### 2

![Sample 2 uncut](https://github.com/azbeaver/godot-mesh-slicer/blob/main/images/sample2_uncut.png)
![Sample 2 cut](https://github.com/azbeaver/godot-mesh-slicer/blob/main/images/sample2_cut.png)
