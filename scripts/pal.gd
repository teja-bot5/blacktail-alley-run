class_name Pal
extends RefCounted
## Shared palette and toon materials (flat shading + ink outline).

const INK := Color(0.13, 0.09, 0.07)
const CAT := Color(0.035, 0.035, 0.045)
const AMBER := Color(1.0, 0.62, 0.12)
const TEAL := Color(0.22, 0.62, 0.64)
const CYAN := Color(0.35, 0.82, 0.86)
const WALLS := [
	Color(0.80, 0.56, 0.42),  # terracotta
	Color(0.90, 0.72, 0.58),  # peach
	Color(0.86, 0.78, 0.62),  # beige
	Color(0.74, 0.60, 0.46),  # dusty tan
	Color(0.93, 0.80, 0.68),  # pale peach
]
const ROOF := Color(0.62, 0.44, 0.34)
const BRICK := Color(0.62, 0.30, 0.22)
const WOOD := Color(0.30, 0.20, 0.14)

static var _cache := {}
static var _dust: NoiseTexture2D


static func dust() -> NoiseTexture2D:
	if _dust == null:
		_dust = NoiseTexture2D.new()
		_dust.width = 128
		_dust.height = 128
		_dust.seamless = true
		var n := FastNoiseLite.new()
		n.frequency = 0.08
		_dust.noise = n
		var g := Gradient.new()
		g.set_color(0, Color(0.72, 0.68, 0.64))
		g.set_color(1, Color(1, 1, 1))
		_dust.color_ramp = g
	return _dust


## Toon material with optional inverted-hull outline. `grow` is in local units.
static func toon(color: Color, outline := true, grow := 0.025, dusty := true) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s" % [color.to_html(), outline, grow, dusty]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.roughness = 1.0
	if dusty:
		m.albedo_texture = dust()
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * 0.6
	if outline:
		m.next_pass = ink(grow)
	_cache[key] = m
	return m


static func ink(grow: float) -> StandardMaterial3D:
	var o := StandardMaterial3D.new()
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.albedo_color = INK
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.grow = true
	o.grow_amount = grow
	return o


static func glow(color: Color, energy := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, outline := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = toon(color, outline)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, sides := 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = sides
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = toon(color, true, 0.015)
	mi.position = pos
	parent.add_child(mi)
	return mi
