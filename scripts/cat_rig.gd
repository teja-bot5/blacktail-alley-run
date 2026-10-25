class_name CatRig
extends Node3D
## Procedural animation for the Quaternius CC0 cat skeleton.
##
## The model only ships Idle/Walking clips, so every running-game motion is
## generated here from a gait phase plus state inputs set by the runner.
## Skeleton space: +X forward, +Z up, +Y = cat's left.
## Pitch about +Y swings a down-pointing leg backwards and tips the nose down.

const MODEL := preload("res://assets/cat/Cat.fbx")
const FWD := Vector3(1, 0, 0)
const UP := Vector3(0, 0, 1)
const SIDE := Vector3(0, 1, 0)
const HIP_HEIGHT := 0.22  # metres, rest height of the back

# --- Inputs, written by the runner every frame ---
var speed := 0.0      # forward m/s
var lat_vel := 0.0    # sideways m/s, + = right
var vert_vel := 0.0   # m/s
var grounded := true
var slide := 0.0      # 0..1 target
var crouch := 0.0     # 0..1 target (jump anticipation)
var flinch := 0.0     # 1 on obstacle bump

# --- Internal state ---
var phase := 0.0
var land := 0.0
var _was_grounded := true
var _prev_lat := 0.0
var _prev_vert := 0.0
var _w := {"run": 0.0, "air": 0.0, "slide": 0.0, "crouch": 0.0, "lean": 0.0}
var _tail := []   # per bone: [pitch, yaw, pitch_vel, yaw_vel]
var _blink := 0.0
var _blink_timer := 2.0

var body: Node3D
var model: Node3D
var sk: Skeleton3D
var _idx := {}
var _rest_inv := {}
var _acc := {}
var _eyes: Array[Node3D] = []
var _pupils: Array[Node3D] = []

const BONES := {
	"pelvis": "Bone", "chest": "Bone.001", "neck": "Bone.002", "head": "Bone.003",
	"tail0": "Bone.004", "tail1": "Bone.005", "tail2": "Bone.006", "tail3": "Bone.007",
	"fl_up": "Bone.017", "fl_lo": "Bone.018", "fl_paw": "Bone.019",
	"fr_up": "Bone.014", "fr_lo": "Bone.015", "fr_paw": "Bone.016",
	"hl_up": "Bone.008", "hl_lo": "Bone.009", "hl_paw": "Bone.010",
	"hr_up": "Bone.011", "hr_lo": "Bone.012", "hr_paw": "Bone.013",
}


func _ready() -> void:
	body = Node3D.new()
	body.position.y = HIP_HEIGHT
	add_child(body)
	model = MODEL.instantiate()
	model.scale = Vector3.ONE * 0.1
	model.rotation.y = PI / 2  # model faces +X; runner faces -Z
	model.position.y = -HIP_HEIGHT
	body.add_child(model)
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if ap:
		ap.queue_free()
	sk = model.find_child("Skeleton3D", true, false)
	for key in BONES:
		var i := sk.find_bone(BONES[key])
		assert(i >= 0, "missing bone " + BONES[key])
		_idx[key] = i
		_rest_inv[key] = sk.get_bone_global_rest(i).basis.orthonormalized().inverse()
	for i in 4:
		_tail.append([0.0, 0.0, 0.0, 0.0])
	_style_mesh()
	_add_eyes()


func _style_mesh() -> void:
	var mi: MeshInstance3D = model.find_child("Cat", true, false)
	var fur := Pal.toon(Pal.CAT, true, 0.0009, false)
	fur.rim_enabled = true
	fur.rim = 0.35
	fur.rim_tint = 0.0
	mi.set_surface_override_material(0, fur)
	mi.set_surface_override_material(1, Pal.toon(Color(0.06, 0.055, 0.06), true, 0.0009, false))
	mi.set_surface_override_material(2, Pal.toon(Color(0.32, 0.16, 0.17), false, 0.0, false))


## Almond amber eyes with slit pupils, attached to the head bone.
## Positions are in skeleton units (model is 100x armature, x0.1 holder).
func _add_eyes() -> void:
	var att := BoneAttachment3D.new()
	att.bone_name = BONES["head"]
	sk.add_child(att)
	var head_rest := sk.get_bone_global_rest(_idx["head"])
	var iris := Pal.glow(Pal.AMBER, 0.9)
	var pupil_mat := StandardMaterial3D.new()
	pupil_mat.albedo_color = Color(0.02, 0.015, 0.01)
	pupil_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var shine := StandardMaterial3D.new()
	shine.albedo_color = Color(1, 0.97, 0.9)
	shine.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in [-1.0, 1.0]:
		var pos := Vector3(2.93, 0.21 * side, 2.80) / 100.0
		# Eye frame uses skeleton axes, turned slightly outwards.
		var basis := Basis(UP, 0.42 * side)
		var eye := Node3D.new()
		eye.transform = head_rest.affine_inverse() * Transform3D(basis, pos)
		att.add_child(eye)
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.0012
		sm.height = 0.0024
		sm.radial_segments = 16
		sm.rings = 8
		ball.mesh = sm
		ball.scale = Vector3(0.55, 1.0, 0.8)
		ball.material_override = iris
		eye.add_child(ball)
		var pupil := MeshInstance3D.new()
		var pm := SphereMesh.new()
		pm.radius = 0.0011
		pm.height = 0.0022
		pupil.mesh = pm
		pupil.position = Vector3(0.00035, 0, 0)
		pupil.scale = Vector3(0.45, 0.22, 0.85)
		pupil.material_override = pupil_mat
		eye.add_child(pupil)
		var glint := MeshInstance3D.new()
		var gm := SphereMesh.new()
		gm.radius = 0.00022
		gm.height = 0.00044
		glint.mesh = gm
		glint.position = Vector3(0.0006, 0.0003 * side, 0.00035)
		glint.material_override = shine
		eye.add_child(glint)
		_eyes.append(eye)
		_pupils.append(pupil)


func _rot(key: String, axis: Vector3, angle: float) -> void:
	if absf(angle) < 0.0001:
		return
	var local_axis: Vector3 = (_rest_inv[key] * axis).normalized()
	_acc[key] = _acc[key] * Quaternion(local_axis, angle)


func _approach(key: String, target: float, rate: float, delta: float) -> float:
	_w[key] = lerpf(_w[key], target, 1.0 - exp(-rate * delta))
	return _w[key]


func _process(delta: float) -> void:
	if sk == null or delta <= 0.0:
		return
	delta = minf(delta, 0.05)
	for key in BONES:
		_acc[key] = Quaternion.IDENTITY

	# Landing impulse and inertial accelerations (drive tail + eyes).
	if grounded and not _was_grounded:
		land = clampf(-_prev_vert / 5.0, 0.4, 1.0)
	_was_grounded = grounded
	land = move_toward(land, 0.0, delta * 3.5)
	var lat_acc := (lat_vel - _prev_lat) / delta
	var vert_acc := (vert_vel - _prev_vert) / delta
	if grounded:
		vert_acc = 0.0
	_prev_lat = lat_vel
	_prev_vert = vert_vel

	var lean := clampf(lat_vel / 5.0, -1.0, 1.0)
	_approach("lean", lean, 14.0, delta)
	lean = _w["lean"]
	var w_air := _approach("air", 0.0 if grounded else 1.0, 18.0, delta)
	var w_slide := _approach("slide", slide, 14.0, delta)
	var w_crouch := _approach("crouch", crouch, 30.0, delta)
	var w_run := _approach("run", clampf(speed / 3.0, 0.0, 1.0) * (1.0 - w_air) * (1.0 - w_slide), 10.0, delta)

	# Gait: half-bound/rotary gallop. Stride frequency rises with speed.
	var freq := lerpf(2.4, 3.8, clampf((speed - 3.0) / 9.0, 0.0, 1.0))
	phase = fposmod(phase + delta * freq * (0.3 + 0.7 * w_run), 1.0)
	var flex := sin(TAU * phase) * w_run                 # + = back arched (gathered)
	var bob := (0.5 - 0.5 * cos(TAU * 2.0 * phase)) * w_run
	var rock := sin(TAU * (phase + 0.25)) * 0.07 * w_run  # body pitch, + = nose down

	# Air: t>0 rising, t<0 falling.
	var t := clampf(vert_vel / 5.0, -1.0, 1.0)
	var rise := maxf(t, 0.0) * w_air
	var fall := maxf(-t, 0.0) * w_air
	var apex := (1.0 - absf(t)) * w_air

	# ---------- Body (whole-cat transform) ----------
	var squash := land * (1.0 - w_air)
	var height := 0.018 * bob - 0.045 * w_crouch - 0.085 * w_slide - 0.05 * squash - 0.012 * flinch
	var body_pitch := rock + 0.12 * w_crouch - 0.22 * rise + 0.18 * fall + 0.08 * squash + 0.06 * w_slide
	body.position = Vector3(0, HIP_HEIGHT + height, 0)
	body.rotation = Vector3(-body_pitch, -lean * 0.30, -lean * 0.32)
	model.scale = Vector3(0.1, 0.1 * (1.0 - 0.06 * squash + 0.04 * rise), 0.1 * (1.0 + 0.05 * rise - 0.05 * w_slide))

	# ---------- Spine: pelvis/chest bend (only one spine joint in this rig) ----------
	var spine := 0.20 * flex + 0.22 * w_crouch - 0.38 * rise + 0.30 * apex - 0.18 * fall + 0.25 * squash - 0.2 * w_slide
	_rot("chest", SIDE, spine)
	_rot("pelvis", SIDE, -spine * 0.35)
	# Sharp turns: C-curve, front half leads into the turn.
	_rot("chest", UP, -lean * 0.38)
	_rot("pelvis", UP, lean * 0.12)
	_rot("chest", FWD, lean * 0.12)

	# ---------- Neck/head: stabilise gaze, look into turns ----------
	var gaze := -(body_pitch + spine * 0.65)
	_rot("neck", SIDE, gaze * 0.6 + 0.35 * w_slide - 0.15 * fall - 0.1 * flinch)
	_rot("head", SIDE, gaze * 0.4 + 0.15 * w_crouch - 0.15 * w_slide + 0.1 * rise)
	_rot("neck", UP, -lean * 0.35)
	_rot("head", UP, -lean * 0.25)
	_rot("head", FWD, lean * 0.18)

	# ---------- Legs ----------
	# Pitch angles in world intent (+ = leg swings back), parent rotations removed.
	var hind_parent := body_pitch - spine * 0.35
	var fore_parent := body_pitch + spine * 0.65
	_leg("hl", 0.00, true, hind_parent, w_run, rise, apex, fall, w_slide, w_crouch, squash, lean)
	_leg("hr", 0.07, true, hind_parent, w_run, rise, apex, fall, w_slide, w_crouch, squash, lean)
	_leg("fl", 0.52, false, fore_parent, w_run, rise, apex, fall, w_slide, w_crouch, squash, lean)
	_leg("fr", 0.59, false, fore_parent, w_run, rise, apex, fall, w_slide, w_crouch, squash, lean)

	# ---------- Tail: spring chain counter-balancing the body ----------
	_tail_update(delta, lat_acc, vert_acc, w_run, w_slide, w_air, lean)

	for key in BONES:
		var i: int = _idx[key]
		sk.set_bone_pose_rotation(i, sk.get_bone_rest(i).basis.get_rotation_quaternion() * _acc[key])

	_eyes_update(delta, w_air, w_slide, w_crouch)
	flinch = move_toward(flinch, 0.0, delta * 3.0)


func _leg(p: String, offset: float, hind: bool, parent_pitch: float, w_run: float, rise: float,
		apex: float, fall: float, w_slide: float, w_crouch: float, squash: float, lean: float) -> void:
	var lp := TAU * fposmod(phase + offset, 1.0)
	var amp := 0.62 if hind else 0.72
	var swing := -amp * sin(lp)               # + = back
	var forward_motion := maxf(cos(lp), 0.0)  # leg travelling forward (in the air)
	var stance := maxf(-cos(lp), 0.0)
	var upper := swing * w_run
	var lower := 0.0
	var paw := 0.0
	# Fold during the forward swing; front wrists flick, hind hocks tuck.
	lower += (0.9 if hind else 1.1) * forward_motion * w_run
	upper -= (0.25 if hind else 0.0) * forward_motion * w_run
	# Push-off: hind leg straightens, toes press at end of stance.
	paw += (0.9 * forward_motion - 0.35 * stance * maxf(-sin(lp), 0.0)) * w_run

	if hind:
		upper += 0.9 * rise - 0.55 * apex - 0.45 * fall + 1.25 * w_slide - 0.35 * w_crouch - 0.2 * squash
		lower += 0.2 * rise + 1.2 * apex + 0.7 * fall - 0.3 * w_slide + 0.75 * w_crouch + 0.5 * squash
		paw += -0.4 * rise + 0.9 * apex + 0.5 * fall - 0.6 * w_slide + 0.3 * w_crouch
	else:
		upper += -1.15 * rise + 0.35 * apex - 0.75 * fall - 1.25 * w_slide - 0.25 * w_crouch + 0.35 * squash
		lower += 0.3 * rise + 1.5 * apex - 0.1 * fall - 0.4 * w_slide + 0.7 * w_crouch + 0.6 * squash
		paw += 0.6 * rise + 1.0 * apex + 0.3 * fall - 0.5 * w_slide + 0.25 * w_crouch

	upper -= parent_pitch
	# Keep the paw parallel to the ground while planted.
	var plant := (1.0 - forward_motion) * w_run + w_crouch * 0.6 + squash * 0.8
	paw -= (upper + parent_pitch + lower) * clampf(plant, 0.0, 1.0)

	_rot(p + "_up", SIDE, upper)
	_rot(p + "_lo", SIDE, lower)
	_rot(p + "_paw", SIDE, paw)
	# Turns: legs splay toward the outside, outer side pushes.
	var side := 1.0 if p.ends_with("l") else -1.0
	_rot(p + "_up", FWD, -lean * 0.22 + 0.06 * side * w_slide)


func _tail_update(delta: float, lat_acc: float, vert_acc: float, w_run: float, w_slide: float,
		w_air: float, lean: float) -> void:
	# Base pose: up & curious when idle, streaming back with an S-curve at speed.
	var base_pitch := [-0.15 - 0.95 * w_run - 1.1 * w_slide, -0.35 * w_run - 0.2 * w_slide, 0.15 * w_run, 0.3 * w_run]
	var drive_p := clampf(vert_acc * 0.012, -0.6, 0.6) - 0.35 * w_air
	var drive_y := clampf(lat_acc * 0.03, -0.9, 0.9) + lean * 0.5
	var t := Time.get_ticks_msec() * 0.001
	for i in 4:
		var s: Array = _tail[i]
		var gain := 0.4 + 0.3 * i
		var target_p: float = base_pitch[i] + drive_p * gain + 0.06 * sin(t * 2.1 - i * 0.7)
		var target_y: float = drive_y * gain + 0.12 * sin(TAU * phase - i * 0.9) * w_run + 0.08 * sin(t * 1.3 - i)
		if i > 0:  # follow-through: inherit lag of the previous segment
			var prev: Array = _tail[i - 1]
			target_p += (prev[0] - base_pitch[i - 1]) * 0.35
			target_y += prev[1] * 0.45
		var k := 150.0 - 25.0 * i
		var c := 2.0 * sqrt(k) * 0.45
		s[2] += (k * (target_p - s[0]) - c * s[2]) * delta
		s[3] += (k * (target_y - s[1]) - c * s[3]) * delta
		s[0] += s[2] * delta
		s[1] += s[3] * delta
		var key := "tail%d" % i
		_rot(key, SIDE, s[0])
		_rot(key, FWD, s[1])


func _eyes_update(delta: float, w_air: float, w_slide: float, w_crouch: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink = 1.0
		_blink_timer = randf_range(2.0, 4.5)
	_blink = move_toward(_blink, 0.0, delta * 7.0)
	var lid := 1.0 - sin(_blink * PI) * 0.9
	lid *= 1.0 - 0.35 * w_slide - 0.2 * w_crouch + 0.12 * w_air
	var dilate := 0.22 + 0.35 * w_air + 0.15 * flinch
	for i in _eyes.size():
		_eyes[i].scale = Vector3(1, 1, maxf(lid, 0.08))
		_pupils[i].scale = Vector3(0.45, dilate, 0.85)
