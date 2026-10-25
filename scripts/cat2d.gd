class_name Cat2D
extends Node2D
## Illustrated black cat drawn procedurally in 2D: slim athletic silhouette,
## amber eye, union ink outline. Origin = ground point under the cat, +x = forward.
##
## Motion: planted-foot rotary gallop (stance feet are locked to the roof, so
## they never slide), anticipation/takeoff/tuck/reach/landing jump poses, belly
## slide, sitting idle (breathing, blinking, looking around), spring-chain tail.
## Poses are blended, then legs are solved with 2-bone IK.

signal footfall(world_pos: Vector2)

const BODY := Color(0.05, 0.048, 0.055)
const FAR := Color(0.2, 0.19, 0.21)
const RIM := Color(0.36, 0.35, 0.4)
const EYE := Color(1.0, 0.74, 0.12)
const OUT := 2.8
const TRAVEL := 54.0       # foot travel during stance (px)
const DUTY := 0.36         # fraction of the stride a foot is planted
const TAIL_N := 9
const TAIL_LEN := 7.5
# Leg indices: 0 hind-near, 1 hind-far, 2 front-near, 3 front-far.
const OFFS := [0.0, 0.09, 0.52, 0.61]

# Inputs (set by the game every frame)
var speed := 0.0
var vy := 0.0
var grounded := true
var sliding := false
var sitting := true
var crouch := 0.0
var flinch := 0.0

var phase := 0.0
var land := 0.0
var _t := 0.0
var _w := {"sit": 1.0, "air": 0.0, "slide": 0.0, "crouch": 0.0, "run": 0.0}
var _was_grounded := true
var _prev_vy := 0.0
var _tail_base := PI - 0.2
var _tail_base_v := 0.0
var _tail: Array = []  # [rel_angle, vel]
var _blink := 0.0
var _blink_in := 2.0
var _look := 0.0
var _look_to := 0.0
var _look_in := 1.5
var _was_stance := [false, false, false, false]
var _pose := {}


func _ready() -> void:
	for i in TAIL_N:
		_tail.append([0.0, 0.0])


# ---------------- Poses ----------------
# feet: per leg [x, y, paw_angle, hock_dx, hock_dy]   (hock only used by hind legs)

func _run_pose() -> Dictionary:
	var flex := sin(TAU * (phase + 0.12))
	var bob := sin(TAU * 2.0 * phase)
	var feet := []
	for i in 4:
		var hind := i < 2
		var anchor := -30.0 if hind else 34.0
		var p := fposmod(phase + OFFS[i], 1.0)
		var f := [0.0, 0.0, 0.0, -6.0, -13.0]
		if p < DUTY:
			f[0] = anchor + TRAVEL * (0.5 - p / DUTY)
		else:
			var s := (p - DUTY) / (1.0 - DUTY)
			var e := s * s * (3.0 - 2.0 * s)
			f[0] = anchor - TRAVEL * 0.5 + TRAVEL * e + sin(s * PI) * (6.0 if hind else 10.0)
			f[1] = -sin(s * PI) * (20.0 if hind else 16.0)
			f[2] = sin(s * PI) * (1.3 if hind else 1.1)
			if hind:
				f[3] = -13.0 * sin(s * PI) - 6.0
				f[4] = -13.0 + 6.0 * sin(s * PI)
		feet.append(f)
	return {
		"hip": Vector2(-36.0 + 4.0 * flex, -46.0 - 2.5 * bob), "sh": Vector2(30.0 - 3.0 * flex, -50.0 - 2.0 * bob),
		"arch": 7.0 * flex, "head": Vector2(19, -17), "hang": 0.06 * sin(TAU * 2.0 * phase), "feet": feet,
		"tail": PI + 0.28 + 0.08 * sin(TAU * phase), "curl": [0.0, -0.06, -0.08, -0.04, 0.05, 0.12, 0.18, 0.2, 0.16],
		"ear": 0.2, "lid": 1.0,
	}


func _air_pose(rise: float, fall: float) -> Dictionary:
	var apex := clampf(1.0 - rise - fall, 0.0, 1.0)
	var r := {  # takeoff / extension
		"hip": Vector2(-40, -48), "sh": Vector2(31, -60), "arch": -8.0, "head": Vector2(21, -20), "hang": -0.2,
		"feet": [[-74, -2, 2.3, -10, -6], [-68, 2, 2.3, -10, -6], [62, -46, -0.5, 0, 0], [56, -40, -0.4, 0, 0]],
		"tail": PI - 0.1, "curl": [0.0, 0.02, 0.04, 0.05, 0.05, 0.06, 0.08, 0.1, 0.1], "ear": 0.4, "lid": 1.15,
	}
	var a := {  # tuck
		"hip": Vector2(-32, -52), "sh": Vector2(27, -55), "arch": 11.0, "head": Vector2(19, -18), "hang": 0.0,
		"feet": [[-12, -24, 1.4, -14, -4], [-8, -22, 1.4, -14, -4], [14, -26, 1.6, 0, 0], [10, -24, 1.6, 0, 0]],
		"tail": PI + 0.65, "curl": [0.0, 0.08, 0.12, 0.14, 0.14, 0.12, 0.1, 0.06, 0.0], "ear": 0.3, "lid": 1.15,
	}
	var f := {  # reach for landing
		"hip": Vector2(-37, -50), "sh": Vector2(30, -46), "arch": -3.0, "head": Vector2(21, -14), "hang": 0.18,
		"feet": [[-34, -16, 0.9, -12, -8], [-28, -12, 0.9, -12, -8], [52, 0, -0.2, 0, 0], [46, -2, -0.1, 0, 0]],
		"tail": PI + 0.45, "curl": [0.0, 0.04, 0.08, 0.1, 0.12, 0.12, 0.1, 0.08, 0.04], "ear": 0.3, "lid": 1.1,
	}
	var out := _mix(a, r, rise / maxf(rise + apex, 0.001) if rise > 0.0 else 0.0)
	return _mix(out, f, fall)


func _crouch_pose(base: Dictionary) -> Dictionary:
	var c := base.duplicate(true)
	c.hip += Vector2(2, 13)
	c.sh += Vector2(-2, 11)
	c.arch += 6.0
	c.head += Vector2(-2, 6)
	c.hang += 0.12
	for f in c.feet:
		if f[1] > -1.0:  # planted feet stay planted
			continue
		f[1] = minf(f[1] + 10.0, 0.0)
	return c


func _slide_pose() -> Dictionary:
	return {
		"hip": Vector2(-40, -20), "sh": Vector2(32, -22), "arch": -5.0, "head": Vector2(23, -6), "hang": 0.12,
		"feet": [[-84, 0, 2.6, -12, -2], [-78, 0, 2.6, -12, -2], [70, 0, -0.1, 0, 0], [64, 0, -0.1, 0, 0]],
		"tail": PI + 0.06, "curl": [0.0, 0.0, 0.01, 0.02, 0.02, 0.03, 0.04, 0.05, 0.06], "ear": 1.0, "lid": 0.75,
	}


func _sit_pose() -> Dictionary:
	var breathe := sin(_t * 1.7)
	return {
		"hip": Vector2(-20, -17), "sh": Vector2(6, -60 - 1.2 * breathe), "arch": 5.0 + breathe, "head": Vector2(9, -21),
		"hang": -0.08 + _look,
		"feet": [[2, 0, 0.0, -18, -2], [-2, 0, 0.0, -17, -2], [14, 0, 0.0, 0, 0], [8, 0, 0.0, 0, 0]],
		"tail": PI - 0.25, "curl": [0.35, 0.25, 0.12, 0.0, -0.08, -0.15, -0.25, -0.38 + 0.25 * sin(_t * 2.3), -0.45 + 0.4 * sin(_t * 2.3 - 0.6)],
		"ear": 0.0 + 0.4 * maxf(sin(_t * 0.9) - 0.92, 0.0) * 10.0, "lid": 1.0,
	}


func _mix(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	if w <= 0.0:
		return a
	if w >= 1.0:
		return b
	var o := {}
	for k in a:
		var va = a[k]
		var vb = b[k]
		if k == "feet":
			var feet := []
			for i in 4:
				var f := []
				for j in 5:
					f.append(lerpf(va[i][j], vb[i][j], w))
				feet.append(f)
			o[k] = feet
		elif k == "curl":
			var c := []
			for j in TAIL_N:
				c.append(lerpf(va[j], vb[j], w))
			o[k] = c
		elif k == "tail" or k == "hang":
			o[k] = lerp_angle(va, vb, w)
		else:
			o[k] = lerp(va, vb, w)
	return o


# ---------------- Update ----------------

func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	_t += delta
	if grounded and not _was_grounded:
		land = clampf(_prev_vy / 1100.0, 0.35, 1.0)
	_was_grounded = grounded
	land = move_toward(land, 0.0, delta * 4.0)
	var acc_up := -(vy - _prev_vy) / maxf(delta, 0.001) if not grounded else 0.0
	_prev_vy = vy

	var ws := _approach("sit", 1.0 if sitting else 0.0, 7.0, delta)
	var wa := _approach("air", 0.0 if grounded else 1.0, 16.0, delta)
	var wsl := _approach("slide", 1.0 if sliding else 0.0, 16.0, delta)
	var wc := _approach("crouch", maxf(crouch, land), 26.0, delta)
	var freq := clampf(speed / (TRAVEL / DUTY), 2.6, 5.2)
	phase = fposmod(phase + delta * freq * (1.0 if speed > 1.0 else 0.0), 1.0)

	var pose := _run_pose()
	pose = _mix(pose, _air_pose(clampf(-vy / 900.0, 0.0, 1.0), clampf(vy / 900.0, 0.0, 1.0)), wa)
	pose = _mix(pose, _slide_pose(), wsl)
	pose = _mix(pose, _crouch_pose(pose), wc * (1.0 - wa))
	pose = _mix(pose, _sit_pose(), ws)
	_pose = pose

	_idle_update(delta)
	_tail_update(delta, acc_up)
	_emit_footfalls(ws, wa, wsl)
	flinch = move_toward(flinch, 0.0, delta * 3.0)
	queue_redraw()


func _approach(key: String, target: float, rate: float, delta: float) -> float:
	_w[key] = lerpf(_w[key], target, 1.0 - exp(-rate * delta))
	return _w[key]


func _idle_update(delta: float) -> void:
	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink = 1.0
		_blink_in = randf_range(1.8, 4.2)
	_blink = move_toward(_blink, 0.0, delta * 7.0)
	_look_in -= delta
	if _look_in <= 0.0:
		_look_to = [-0.25, -0.1, 0.0, 0.12][randi() % 4]
		_look_in = randf_range(1.2, 3.0)
	_look = lerpf(_look, _look_to, 1.0 - exp(-4.0 * delta))


func _tail_update(delta: float, acc_up: float) -> void:
	var k0 := 90.0
	_tail_base_v += (k0 * angle_difference(_tail_base, _pose.tail) - 2.0 * sqrt(k0) * 0.6 * _tail_base_v) * delta
	_tail_base += _tail_base_v * delta
	var drive := clampf(-acc_up * 0.00004, -0.25, 0.25)
	for i in TAIL_N:
		var s: Array = _tail[i]
		var k := 140.0 - 9.0 * i
		var target: float = _pose.curl[i] + drive * (0.3 + 0.12 * i)
		s[1] += (k * (target - s[0]) - 2.0 * sqrt(k) * 0.42 * s[1]) * delta
		s[0] += s[1] * delta


func _emit_footfalls(ws: float, wa: float, wsl: float) -> void:
	for i in 4:
		var p := fposmod(phase + OFFS[i], 1.0)
		var stance := p < DUTY
		if stance and not _was_stance[i] and i % 2 == 0 and grounded and ws < 0.5 and wa < 0.5 and wsl < 0.5 and speed > 1.0:
			footfall.emit(to_global(Vector2(_pose.feet[i][0], 0)))
		_was_stance[i] = stance


# ---------------- Drawing ----------------

func _ik(a: Vector2, target: Vector2, l1: float, l2: float, bend: float) -> PackedVector2Array:
	var d := clampf(a.distance_to(target), absf(l1 - l2) + 0.5, l1 + l2 - 0.5)
	var base := (target - a).angle()
	var ang := base + bend * acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	var j := a + Vector2.from_angle(ang) * l1
	var e := j + (target - j).normalized() * l2
	return PackedVector2Array([a, j, e])


func _strip(p: PackedVector2Array, widths: Array) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in p.size():
		var d := (p[mini(i + 1, p.size() - 1)] - p[maxi(i - 1, 0)]).normalized()
		var n: Vector2 = Vector2(-d.y, d.x) * widths[i] * 0.5
		left.append(p[i] + n)
		right.append(p[i] - n)
	right.reverse()
	return left + right


func _leg(i: int) -> Dictionary:
	var f: Array = _pose.feet[i]
	var hind := i < 2
	var toe := Vector2(f[0], minf(f[1], 0.0) - 3.0)
	var paw_dir := Vector2.from_angle(f[2])
	if hind:
		var root: Vector2 = _pose.hip + Vector2(3, 8)
		var hock := toe + Vector2(f[3], f[4])
		var chain := _ik(root, hock, 21.0, 21.0, -1.0)
		if chain[1].y > -2.0:  # never let a knee poke through the roof
			chain = _ik(root, hock, 21.0, 21.0, 1.0)
		var pts := PackedVector2Array([chain[0], chain[1], chain[2], toe, toe + paw_dir * 8.0])
		return {"pts": pts, "w": [19.0, 9.5, 5.4, 4.8, 4.4]}
	var root2: Vector2 = _pose.sh + Vector2(0, 12)
	var c2 := _ik(root2, toe, 21.0, 20.0, 1.0)
	return {"pts": PackedVector2Array([c2[0], c2[1], c2[2], c2[2] + paw_dir * 9.0]), "w": [12.0, 7.0, 5.4, 4.8]}


func _torso() -> PackedVector2Array:
	var hip: Vector2 = _pose.hip
	var sh: Vector2 = _pose.sh
	var dir := (sh - hip).normalized()
	var up := Vector2(dir.y, -dir.x)
	var a := hip - dir * 12.0
	var b := sh + dir * 9.0
	var ctrl: Vector2 = (a + b) * 0.5 + up * _pose.arch
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var tk := [9.0, 8.0, 6.5, 6.5, 8.5, 10.5]
	var bk := [12.0, 11.5, 8.5, 11.0, 18.0, 15.0]
	for i in 13:
		var u := i / 12.0
		var p := a.lerp(ctrl, u).lerp(ctrl.lerp(b, u), u)
		var k := u * 5.0
		var ki := mini(int(k), 4)
		var fr := k - ki
		top.append(p + up * lerpf(tk[ki], tk[ki + 1], fr))
		bot.append(p - up * lerpf(bk[ki], bk[ki + 1], fr))
	bot.reverse()
	return top + bot


func _head_xf() -> Transform2D:
	return Transform2D(_pose.hang + 0.15 * flinch, _pose.sh + _pose.head)


func _head_shapes() -> Array:
	var xf := _head_xf()
	var ear := clampf(_pose.ear, 0.0, 1.0)
	var skull := xf * Ink.ellipse(Vector2.ZERO, 13.5, 11.0, 18)
	var muzzle := xf * Ink.ellipse(Vector2(11, 3.5), 8.0, 6.2, 12)
	var near_ear := xf * PackedVector2Array([Vector2(-5, -7), Vector2(-1, -24).lerp(Vector2(-16, -14), ear), Vector2(6, -9)])
	var far_ear := xf * PackedVector2Array([Vector2(-10, -5), Vector2(-9, -21).lerp(Vector2(-22, -11), ear), Vector2(-1, -9)])
	return [far_ear, skull, muzzle, near_ear]


func _draw() -> void:
	if _pose.is_empty():
		return
	# Far legs: slightly lighter so they read as behind the body.
	for i in [1, 3]:
		var lg := _leg(i)
		_fill_union([_strip(lg.pts, lg.w)], _joint_circles(lg), FAR)
	var polys: Array = [_torso()]
	var circles: Array = [[_pose.hip + Vector2(-2, 3), 15.0], [_pose.sh + Vector2(-3, 6), 12.5]]
	# Neck
	var hx := _head_xf()
	polys.append(_strip(PackedVector2Array([_pose.sh + Vector2(-2, -3), hx.origin + Vector2(-4, 4)]), [17.0, 13.0]))
	polys.append_array(_head_shapes())
	# Tail
	var tail := PackedVector2Array([_pose.hip + Vector2(-10, -6)])
	var ang := _tail_base
	var tw := []
	for i in TAIL_N:
		ang += _tail[i][0]
		tail.append(tail[i] + Vector2.from_angle(ang) * TAIL_LEN)
	for i in tail.size():
		tw.append(lerpf(6.0, 3.0, float(i) / tail.size()))
	polys.append(_strip(tail, tw))
	circles.append([tail[tail.size() - 1], 1.8])
	for i in [0, 2]:
		var lg := _leg(i)
		polys.append(_strip(lg.pts, lg.w))
		circles.append_array(_joint_circles(lg))
	_fill_union(polys, circles, BODY)
	_details()


func _joint_circles(lg: Dictionary) -> Array:
	var out := []
	for i in lg.pts.size():
		out.append([lg.pts[i], lg.w[i] * 0.5])
	return out


func _fill_union(polys: Array, circles: Array, col: Color) -> void:
	for p in polys:
		for o in Geometry2D.offset_polygon(p, OUT, Geometry2D.JOIN_ROUND):
			draw_colored_polygon(o, Ink.LINE)
	for c in circles:
		draw_circle(c[0], c[1] + OUT, Ink.LINE)
	for p in polys:
		if Geometry2D.triangulate_polygon(p).is_empty():  # self-intersecting at extreme poses
			draw_colored_polygon(Geometry2D.convex_hull(p), col)
		else:
			draw_colored_polygon(p, col)
	for c in circles:
		draw_circle(c[0], c[1], col)


func _details() -> void:
	# Rim light along the back and the top of the head.
	var torso := _torso()
	var back := PackedVector2Array()
	for i in range(2, 11):
		back.append(torso[i] + Vector2(0, 2))
	draw_polyline(back, RIM, 1.6, true)
	var xf := _head_xf()
	# Inner ear
	var ear := clampf(_pose.ear, 0.0, 1.0)
	draw_colored_polygon(xf * PackedVector2Array([Vector2(-3, -9), Vector2(-1.5, -19).lerp(Vector2(-12, -13), ear), Vector2(3, -10)]), Color(0.3, 0.18, 0.2))
	draw_polyline(xf * Ink.ellipse(Vector2(0, 0), 12.0, 10.0, 10, -2.6, -1.2), RIM, 1.4, true)
	# Amber eye with slit pupil, lid closes on blink and narrows in a slide.
	var lid: float = clampf(_pose.lid, 0.2, 1.2) * (1.0 - sin(_blink * PI) * 0.92)
	var c := Vector2(6.5, -2.5)
	var eye := xf * Ink.ellipse(c, 5.4, 4.0 * lid, 14)
	draw_colored_polygon(eye, EYE)
	draw_polyline(eye + PackedVector2Array([eye[0]]), Ink.LINE, 1.4, true)
	if lid > 0.3:
		var pupil_w := 1.3 + 0.9 * clampf(_w.air + flinch, 0.0, 1.0)
		draw_colored_polygon(xf * Ink.ellipse(c + Vector2(1.6 + _look * 3.0, 0), pupil_w, 3.6 * lid, 10), Ink.LINE)
		draw_circle(xf * (c + Vector2(-1.5, -1.6 * lid)), 1.1, Color(1, 1, 0.92))
	# Nose + whiskers
	draw_circle(xf * Vector2(18.5, 1.5), 1.6, Color(0.35, 0.22, 0.24))
	for k in 2:
		draw_line(xf * Vector2(14, 5 + k * 2), xf * Vector2(27, 3 + k * 5), Color(0.6, 0.58, 0.6, 0.6), 0.9, true)
