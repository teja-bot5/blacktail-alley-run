class_name World
extends Node3D
## Procedural South-Asian rooftop strip built from reusable chunks.

const CHUNK := 14.0
const AHEAD := 70.0
const BEHIND := 12.0
const LANE_W := CatRunner.LANE_W

var rng := RandomNumberGenerator.new()
var next_z := 6.0
var chunks: Array[Node3D] = []
var obstacles: Array = []  # {kind, lane, z, depth, node}
var fish: Array = []       # {lane, z, node}
var _fish_mesh: Mesh
var _fish_mat: Material


func _ready() -> void:
	rng.seed = 7
	_fish_mesh = _make_fish_mesh()
	_fish_mat = Pal.glow(Pal.CYAN, 0.5)
	_fish_mat.next_pass = Pal.ink(0.012)


func update(cat_z: float) -> void:
	while next_z > cat_z - AHEAD:
		_build_chunk(next_z, chunks.is_empty())
		next_z -= CHUNK
	while not chunks.is_empty() and chunks[0].position.z - CHUNK > cat_z + BEHIND:
		chunks.pop_front().queue_free()
	obstacles = obstacles.filter(func(o): return o.z < cat_z + BEHIND)
	fish = fish.filter(func(f): return is_instance_valid(f.node) and f.z < cat_z + BEHIND)


func _build_chunk(z0: float, first: bool) -> void:
	var c := Node3D.new()
	c.position.z = z0
	add_child(c)
	chunks.append(c)
	var mid := -CHUNK / 2.0
	# Roof slab + seam
	Pal.box(c, Vector3(3.0, 0.4, CHUNK), Vector3(0, -0.2, mid), Pal.ROOF.lerp(Pal.WALLS[rng.randi() % 3], 0.12), false)
	Pal.box(c, Vector3(3.0, 0.02, 0.08), Vector3(0, 0.005, -0.05), Pal.ROOF.darkened(0.3), false)
	for s in [-1.0, 1.0]:
		var wall_col: Color = Pal.WALLS[rng.randi() % Pal.WALLS.size()]
		Pal.box(c, Vector3(0.16, 0.38, CHUNK), Vector3(1.55 * s, 0.19, mid), wall_col)
		# Exposed brick patch on the parapet
		if rng.randf() < 0.6:
			Pal.box(c, Vector3(0.17, 0.14, 0.5), Vector3(1.55 * s, 0.2, rng.randf_range(-CHUNK + 1, -1)), Pal.BRICK, false)
		_side_buildings(c, s)
	_pole_and_cables(c)
	_skyline(c)
	if not first:
		_obstacles(c, z0)


func _side_buildings(c: Node3D, s: float) -> void:
	var z := 0.0
	while z > -CHUNK:
		var depth := rng.randf_range(3.0, 6.0)
		var width := rng.randf_range(3.0, 5.5)
		var top := rng.randf_range(-2.5, 3.5)
		var col: Color = Pal.WALLS[rng.randi() % Pal.WALLS.size()]
		var x := s * (1.75 + width / 2.0 + rng.randf_range(0.0, 0.8))
		var h := top + 12.0
		Pal.box(c, Vector3(width, h, depth - 0.1), Vector3(x, top - h / 2.0, z - depth / 2.0), col)
		var face := x - s * width / 2.0
		# Windows / teal shutters on the facade facing the track
		for i in rng.randi_range(1, 3):
			var wy := top - rng.randf_range(0.9, 2.2)
			var wz := z - rng.randf_range(0.6, depth - 0.6)
			var shutter := rng.randf() < 0.3
			Pal.box(c, Vector3(0.08, 0.75, 0.55), Vector3(face - s * 0.03, wy, wz), Pal.TEAL if shutter else Color(0.25, 0.18, 0.15), shutter)
		if rng.randf() < 0.45:  # AC unit
			Pal.box(c, Vector3(0.35, 0.4, 0.7), Vector3(face - s * 0.18, top - 1.2, z - depth * 0.5), Color(0.86, 0.85, 0.80))
		if rng.randf() < 0.55:  # rooftop water tank
			var tank_col := Pal.TEAL if rng.randf() < 0.5 else Color(0.25, 0.42, 0.62)
			Pal.cylinder(c, 0.35, 0.75, Vector3(x + rng.randf_range(-0.8, 0.8), top + 0.375, z - depth / 2.0), tank_col)
		Pal.box(c, Vector3(width, 0.3, 0.12), Vector3(x, top + 0.15, z - 0.06), col.darkened(0.08))
		z -= depth


func _pole_and_cables(c: Node3D) -> void:
	var s := -1.0 if rng.randf() < 0.5 else 1.0
	var base := Vector3(1.85 * s, 0, -2.0)
	Pal.cylinder(c, 0.07, 6.0, base + Vector3(0, 1.5, 0), Pal.WOOD, 8)
	Pal.box(c, Vector3(0.9, 0.06, 0.06), base + Vector3(-0.3 * s, 4.1, 0), Pal.WOOD)
	var top := base + Vector3(0, 4.1, 0)
	# Sagging cables: one along the street, one or two crossing overhead.
	_cable(c, top, top + Vector3(0, rng.randf_range(-0.4, 0.4), -CHUNK), 0.7)
	for i in rng.randi_range(1, 2):
		var far := Vector3(-1.9 * s, rng.randf_range(3.2, 4.4), -2.0 - rng.randf_range(-3.0, 3.0))
		_cable(c, top + Vector3(0, -0.1 * i, 0), far, rng.randf_range(0.4, 0.9))


func _cable(c: Node3D, a: Vector3, b: Vector3, sag: float) -> void:
	var segs := 10
	var prev := a
	for i in range(1, segs + 1):
		var t := float(i) / segs
		var p := a.lerp(b, t) + Vector3(0, -sag * 4.0 * t * (1.0 - t), 0)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.025, 0.025, prev.distance_to(p))
		mi.mesh = bm
		mi.material_override = Pal.toon(Pal.INK, false, 0.0, false)
		c.add_child(mi)
		mi.look_at_from_position((prev + p) / 2.0, p, Vector3.UP if absf((p - prev).normalized().y) < 0.99 else Vector3.RIGHT)
		prev = p


func _skyline(c: Node3D) -> void:
	for s in [-1.0, 1.0]:
		for i in 2:
			var w := rng.randf_range(4.0, 8.0)
			var h := rng.randf_range(2.0, 9.0)
			var col: Color = Pal.WALLS[rng.randi() % Pal.WALLS.size()].lightened(0.15)
			Pal.box(c, Vector3(w, h + 10.0, w), Vector3(s * rng.randf_range(14.0, 26.0), h / 2.0 - 5.0, -i * 7.0 - 3.0), col, false)


func _obstacles(c: Node3D, z0: float) -> void:
	var kinds := ["jump", "slide", "wall"]
	for row in 2:
		var zl := -3.5 - row * 6.5
		var kind: String = kinds[rng.randi() % kinds.size()]
		var lane := rng.randi_range(-1, 1)
		var n := Node3D.new()
		n.position = Vector3(lane * LANE_W, 0, zl)
		c.add_child(n)
		var depth := 0.5
		match kind:
			"jump":
				Pal.box(n, Vector3(0.75, 0.36, 0.45), Vector3(0, 0.18, 0), Pal.BRICK)
				Pal.box(n, Vector3(0.7, 0.04, 0.4), Vector3(0, 0.38, 0), Pal.WALLS[1])
			"slide":
				for s in [-1.0, 1.0]:
					Pal.box(n, Vector3(0.05, 0.9, 0.05), Vector3(0.42 * s, 0.45, 0), Pal.WOOD)
				var board := Pal.box(n, Vector3(0.8, 0.5, 0.04), Vector3(0, 0.55, 0), Pal.TEAL)
				board.rotation.x = 0.05
				depth = 0.3
			"wall":
				Pal.box(n, Vector3(0.8, 0.95, 0.6), Vector3(0, 0.475, 0), Pal.WALLS[3])
				Pal.box(n, Vector3(0.82, 0.18, 0.3), Vector3(0, 0.6, 0.16), Pal.BRICK, false)
				depth = 0.6
		obstacles.append({"kind": kind, "lane": lane, "z": z0 + zl, "depth": depth, "node": n})
		# Fish trail in a free lane before the obstacle
		var fl := wrapi(lane + (1 if rng.randf() < 0.5 else -1), -1, 2)
		for i in 4:
			var fz := zl + 2.6 - i * 0.7
			var f := MeshInstance3D.new()
			f.mesh = _fish_mesh
			f.material_override = _fish_mat
			f.position = Vector3(fl * LANE_W, 0.32, fz)
			c.add_child(f)
			fish.append({"lane": fl, "z": z0 + fz, "node": f})


func _make_fish_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Diamond body + tail fin, flat-shaded token
	var pts := [Vector3(0.14, 0, 0), Vector3(0, 0.06, 0), Vector3(-0.08, 0, 0), Vector3(0, -0.06, 0)]
	var tail := [Vector3(-0.08, 0, 0), Vector3(-0.16, 0.06, 0), Vector3(-0.16, -0.06, 0)]
	for zf in [0.025, -0.025]:
		var n := Vector3(0, 0, signf(zf))
		for tri in [[0, 1, 2], [0, 2, 3]]:
			for i in (tri if zf > 0 else [tri[0], tri[2], tri[1]]):
				st.set_normal(n)
				st.add_vertex(pts[i] + Vector3(0, 0, zf))
		for i in ([0, 1, 2] if zf > 0 else [0, 2, 1]):
			st.set_normal(n)
			st.add_vertex(tail[i] + Vector3(0, 0, zf * 0.5))
	return st.commit()
