extends SceneTree
## Dev tool: renders a contact sheet of Cat2D poses to tools/out/cat_sheet.png.
## Run: xvfb-run godot --rendering-driver opengl3 -s tools/cat_sheet.gd

const CELL := Vector2i(300, 190)
var cat: Cat2D
var steps := []
var idx := 0
var sheet: Image
var settle := 0
var vp: SubViewport


func _init() -> void:
	vp = SubViewport.new()
	vp.size = CELL
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.86, 0.72, 0.52)
	bg.size = Vector2(CELL)
	vp.add_child(bg)
	var ground := ColorRect.new()
	ground.color = Color(0.6, 0.5, 0.42)
	ground.position = Vector2(0, 160)
	ground.size = Vector2(CELL.x, 30)
	vp.add_child(ground)
	cat = Cat2D.new()
	cat.position = Vector2(150, 160)
	cat.scale = Vector2.ONE * 1.6
	vp.add_child(cat)
	# [label, sitting, speed, grounded, vy, sliding, crouch, settle_seconds]
	steps.append(["sit", true, 0.0, true, 0.0, false, 0.0, 1.0])
	for i in 8:
		steps.append(["run%d" % i, false, 520.0, true, 0.0, false, 0.0, 0.0 if i > 0 else 1.2])
	steps.append(["antic", false, 520.0, true, 0.0, false, 1.0, 0.12])
	for v in [-1000.0, -600.0, -150.0, 0.0, 300.0, 700.0, 1000.0]:
		steps.append(["air", false, 520.0, false, v, false, 0.0, 0.08])
	steps.append(["land", false, 520.0, true, 0.0, false, 0.0, 0.05])
	steps.append(["land2", false, 520.0, true, 0.0, false, 0.0, 0.18])
	steps.append(["slide", false, 520.0, true, 0.0, true, 0.0, 0.4])
	sheet = Image.create(CELL.x * 8, CELL.y * ceili(steps.size() / 8.0), false, Image.FORMAT_RGBA8)


func _process(_d: float) -> bool:
	if idx >= steps.size():
		sheet.save_png("res://tools/out/cat_sheet.png")
		return true
	var s: Array = steps[idx]
	cat.sitting = s[1]
	cat.speed = s[2]
	cat.grounded = s[3]
	cat.vy = s[4]
	cat.sliding = s[5]
	cat.crouch = s[6]
	if settle == 0:
		var n := int(s[7] / 0.016)
		for k in n:
			cat._process(0.016)
		if s[0].begins_with("run"):
			cat.phase = (int(s[0].substr(3)) / 8.0)
			cat._process(0.0001)
	settle += 1
	if settle >= 3:
		var img := vp.get_texture().get_image()
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((idx % 8) * CELL.x, (idx / 8) * CELL.y))
		settle = 0
		idx += 1
	return false
