class_name CatView
extends Node2D
## Shows the procedurally animated 3D cat (CatRig) as a flat side-view sprite.
## The rig renders into a transparent SubViewport through an orthographic
## camera, so the 2D game keeps the rig's spine, paw and tail motion.

const VP := Vector2i(320, 200)
const ORTHO := 0.62         # metres visible vertically
const FOOT := 0.18          # camera height above the feet (m)
const SCALE := 0.74         # sprite scale on screen
const PX_PER_M := VP.y / ORTHO * SCALE

var rig: CatRig
var _sprite: Sprite2D


func _ready() -> void:
	var vp := SubViewport.new()
	vp.size = VP
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	rig = CatRig.new()
	vp.add_child(rig)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ORTHO
	# Side view turned ~23° toward the cat's face so the near amber eye reads.
	var yaw := 0.4
	cam.position = Vector3(2.0 * cos(yaw), FOOT, -2.0 * sin(yaw))
	cam.rotation.y = PI / 2 + yaw
	vp.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 60, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.85, 0.7)
	env.ambient_light_energy = 0.6
	env.background_mode = Environment.BG_CLEAR_COLOR
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	_sprite = Sprite2D.new()
	_sprite.texture = vp.get_texture()
	_sprite.scale = Vector2.ONE * SCALE
	# Node origin = the cat's feet.
	_sprite.position = Vector2(0, -FOOT / ORTHO * VP.y * SCALE)
	add_child(_sprite)


## Feed 2D motion into the rig (pixels/s → the rig's metre-based tuning).
func drive(speed_px: float, vy_px: float, grounded: bool, sliding: bool, crouch: bool) -> void:
	rig.speed = 5.5 + (speed_px - 420.0) / 90.0
	rig.vert_vel = -vy_px / 190.0
	rig.grounded = grounded
	rig.slide = 1.0 if sliding else 0.0
	rig.crouch = 1.0 if crouch else 0.0
	rig.lat_vel = 0.0


func flash(on: bool) -> void:
	modulate.a = 0.35 if on else 1.0
