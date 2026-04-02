class_name HeldItemRenderConfig
extends Resource

@export var id: String = ""
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg", "*.svg") var sprite_path: String = ""
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var sprite_scale: Vector2 = Vector2.ONE
@export var sprite_rotation_deg: float = 0.0
