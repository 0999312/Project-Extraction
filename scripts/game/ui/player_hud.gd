class_name PlayerHUD
extends CanvasLayer

# ── Color constants for the health bar ────────────────────────────────────────
const COLOR_HP_HEALTHY  := Color(0.133, 0.694, 0.298, 1)   # green  ≥ 50 %
const COLOR_HP_INJURED  := Color(0.827, 0.184, 0.184, 1)   # red    < 50 %
const COLOR_STAMINA     := Color(0.753, 0.753, 0.753, 1)   # light-grey
const COLOR_ENERGY      := Color(1.0,   0.843, 0.0,   1)   # yellow
const COLOR_THIRST      := Color(0.196, 0.784, 0.941, 1)   # water-blue / cyan

# ── StyleBox fill colours (reused from theme, overridden per bar) ──────────────
var _sb_hp_healthy : StyleBoxFlat
var _sb_hp_injured : StyleBoxFlat
var _sb_stamina    : StyleBoxFlat
var _sb_energy     : StyleBoxFlat
var _sb_thirst     : StyleBoxFlat

# ── Node references ────────────────────────────────────────────────────────────
@onready var hp_bar      : ProgressBar = $HUDRoot/StatsPanel/Row2/HPBar
@onready var stamina_bar : ProgressBar = $HUDRoot/StatsPanel/Row2/StaminaBar
@onready var energy_bar  : ProgressBar = $HUDRoot/StatsPanel/Row1/EnergyBar
@onready var thirst_bar  : ProgressBar = $HUDRoot/StatsPanel/Row1/ThirstBar

@onready var hp_label      : Label = $HUDRoot/StatsPanel/Row2/HPBar/HPLabel
@onready var stamina_label : Label = $HUDRoot/StatsPanel/Row2/StaminaBar/StaminaLabel
@onready var energy_label  : Label = $HUDRoot/StatsPanel/Row1/EnergyBar/EnergyLabel
@onready var thirst_label  : Label = $HUDRoot/StatsPanel/Row1/ThirstBar/ThirstLabel

@onready var hotbar_container : HBoxContainer = $HUDRoot/HotbarRow/Hotbar

# ── Tracked player reference ──────────────────────────────────────────────────
var _player : BiologicalActor = null

func _ready() -> void:
	_build_style_boxes()
	_apply_bar_styles()
	_find_player()

func _process(_delta: float) -> void:
	if _player == null:
		_find_player()
		return
	_refresh_bars()

# ── Internal helpers ───────────────────────────────────────────────────────────
func _find_player() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p is BiologicalActor:
		_player = p as BiologicalActor

func _build_style_boxes() -> void:
	_sb_hp_healthy = StyleBoxFlat.new()
	_sb_hp_healthy.bg_color = COLOR_HP_HEALTHY

	_sb_hp_injured = StyleBoxFlat.new()
	_sb_hp_injured.bg_color = COLOR_HP_INJURED

	_sb_stamina = StyleBoxFlat.new()
	_sb_stamina.bg_color = COLOR_STAMINA

	_sb_energy = StyleBoxFlat.new()
	_sb_energy.bg_color = COLOR_ENERGY

	_sb_thirst = StyleBoxFlat.new()
	_sb_thirst.bg_color = COLOR_THIRST

func _apply_bar_styles() -> void:
	energy_bar.add_theme_stylebox_override("fill", _sb_energy)
	thirst_bar.add_theme_stylebox_override("fill", _sb_thirst)
	hp_bar.add_theme_stylebox_override("fill", _sb_hp_healthy)
	stamina_bar.add_theme_stylebox_override("fill", _sb_stamina)

func _refresh_bars() -> void:
	# HP
	var h := _player.health
	if h != null:
		hp_bar.max_value = h.max_hp
		hp_bar.value = h.current_hp
		var fill := _sb_hp_healthy if (h.current_hp / h.max_hp) >= 0.5 else _sb_hp_injured
		hp_bar.add_theme_stylebox_override("fill", fill)
		hp_label.text = "%d/%d" % [int(h.current_hp), int(h.max_hp)]

	# Stamina
	var s := _player.stamina_state
	if s != null:
		stamina_bar.max_value = s.max_stamina
		stamina_bar.value = s.current_stamina
		stamina_label.text = "%d/%d" % [int(s.current_stamina), int(s.max_stamina)]

	# Energy
	var e := _player.energy_state
	if e != null:
		energy_bar.max_value = e.max_energy
		energy_bar.value = e.current_energy
		energy_label.text = "%d/%d" % [int(e.current_energy), int(e.max_energy)]

	# Thirst
	var t := _player.thirst_state
	if t != null:
		thirst_bar.max_value = t.max_thirst
		thirst_bar.value = t.current_thirst
		thirst_label.text = "%d/%d" % [int(t.current_thirst), int(t.max_thirst)]
