class_name Pal
extends RefCounted
## Cat materials (flat toon shading + ink outline) used by CatRig.

const INK := Color(0.13, 0.09, 0.07)
const CAT := Color(0.035, 0.035, 0.045)
const AMBER := Color(1.0, 0.62, 0.12)


## Toon material with optional inverted-hull outline. `grow` is in local units.
static func toon(color: Color, outline := true, grow := 0.025, _unused := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.roughness = 1.0
	if outline:
		var o := StandardMaterial3D.new()
		o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		o.albedo_color = INK
		o.cull_mode = BaseMaterial3D.CULL_FRONT
		o.grow = true
		o.grow_amount = grow
		m.next_pass = o
	return m


static func glow(color: Color, energy := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m
