class_name HitParticleEffect
extends Node2D

@onready var particles: GPUParticles2D = $GPUParticles2D

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
		var mat := particles.process_material
		if mat is ParticleProcessMaterial:
			(mat as ParticleProcessMaterial).direction = Vector3(direction.normalized().x, direction.normalized().y, 0.0)
	particles.restart()
	particles.emitting = true

