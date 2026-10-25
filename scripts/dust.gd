class_name Dust
extends Node2D
## Small, restrained dust puffs (footfalls, landings, slides).

var _puffs: Array = []  # [pos, vel, age, life, radius]


func puff(at: Vector2, count: int, strength := 1.0) -> void:
	for i in count:
		var v := Vector2(randf_range(-90, 30), randf_range(-50, -10)) * strength
		_puffs.append([at + Vector2(randf_range(-8, 8), -2), v, 0.0, randf_range(0.3, 0.5), randf_range(4, 8) * strength])


func _process(delta: float) -> void:
	for p in _puffs:
		p[2] += delta
		p[0] += p[1] * delta
		p[1] *= 0.9
	_puffs = _puffs.filter(func(p): return p[2] < p[3])
	queue_redraw()


func _draw() -> void:
	for p in _puffs:
		var k: float = p[2] / p[3]
		draw_circle(p[0], p[4] * (0.6 + k), Color(0.86, 0.77, 0.63, 0.55 * (1.0 - k)))
