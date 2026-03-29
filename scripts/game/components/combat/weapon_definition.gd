class_name WeaponDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var item_id: String = ""
@export var projectile_definition_id: String = "game:projectile/bullet"
@export var ammo_capacity: int = 0
@export var fire_interval: float = 0.14
@export var reload_duration_sec: float = 1.5
@export var hipfire_spread_deg: float = 6.0
@export var ads_spread_deg: float = 1.5
@export var recoil_per_shot: float = 0.6
@export var recoil_recovery_per_sec: float = 2.0
@export var pellets_per_shot: int = 1
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg", "*.svg") var icon_path: String = ""

