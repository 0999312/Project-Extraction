class_name HitParticleEffect
extends Node2D

@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	if particles == null:
		queue_free()
		return
	particles.one_shot = true
	particles.emitting = true
	var timer := get_tree().create_timer(particles.lifetime + 0.3)
	timer.timeout.connect(queue_free)

func emit_hit(direction: Vector2 = Vector2.ZERO) -> void:
	if particles == null:
		return
	if direction.length_squared() > 0.0001:
		particles.direction = direction.normalized()
	particles.restart()
	particles.emitting = true

