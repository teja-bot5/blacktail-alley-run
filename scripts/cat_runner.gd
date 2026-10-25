class_name CatRunner
extends Node3D
## Three-lane movement: lane switch, jump (with anticipation crouch), slide.
## Feeds state into CatRig every frame.

signal hit(kind: String)

const LANE_W := 0.9
const GRAVITY := 17.0
const JUMP_V := 5.2
const ANTICIPATION := 0.07
const SLIDE_TIME := 0.65

var speed := 6.5
var lane := 0
var vy := 0.0
var grounded := true
var slide_t := 0.0
var jump_wait := -1.0
var lat_vel := 0.0
var rig: CatRig
var distance := 0.0
var max_height := 0.0


func _ready() -> void:
	rig = CatRig.new()
	add_child(rig)


func move_lane(dir: int) -> void:
	lane = clampi(lane + dir, -1, 1)


func jump() -> void:
	if grounded and jump_wait < 0.0:
		slide_t = 0.0
		jump_wait = ANTICIPATION


func do_slide() -> void:
	if grounded:
		slide_t = SLIDE_TIME
	else:
		vy = minf(vy, -6.0)  # fast-fall into a slide
		slide_t = SLIDE_TIME


func is_sliding() -> bool:
	return slide_t > 0.0


func _physics_process(delta: float) -> void:
	position.z -= speed * delta
	distance += speed * delta

	# Critically damped lane spring: fast, readable sharp turns.
	var target_x := lane * LANE_W
	var k := 260.0
	lat_vel += (k * (target_x - position.x) - 2.0 * sqrt(k) * lat_vel) * delta
	position.x += lat_vel * delta

	if jump_wait >= 0.0:
		jump_wait -= delta
		if jump_wait < 0.0:
			vy = JUMP_V
			grounded = false
	if not grounded:
		vy -= GRAVITY * delta
		position.y += vy * delta
		if position.y <= 0.0:
			position.y = 0.0
			vy = 0.0
			grounded = true
	max_height = maxf(max_height, position.y)
	slide_t = maxf(slide_t - delta, 0.0) if grounded else slide_t

	rig.speed = speed
	rig.lat_vel = lat_vel
	rig.vert_vel = vy
	rig.grounded = grounded
	rig.slide = 1.0 if slide_t > 0.0 else 0.0
	rig.crouch = 1.0 if jump_wait >= 0.0 else 0.0


## Axis-aligned overlap test against an obstacle described by kind/lane/z.
func collides(kind: String, ob_lane: int, z: float, depth: float) -> bool:
	if ob_lane != lane and absf(position.x - ob_lane * LANE_W) > LANE_W * 0.5:
		return false
	if absf(position.z - z) > depth * 0.5 + 0.2:
		return false
	match kind:
		"jump":
			return position.y < 0.42
		"slide":
			return not is_sliding()
		_:
			return true
