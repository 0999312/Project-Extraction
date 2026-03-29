class_name ItemDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var category: String = ""
@export var size_w: int = 1
@export var size_h: int = 1
@export var weight: float = 0.0
@export var max_stack: int = 1
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg", "*.svg") var icon_path: String = ""
## Tags are managed via MSF TagRegistry. This field is used only for
## initial registration; at runtime query TagRegistry instead.
@export var tags: Array[String] = []
