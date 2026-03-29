class_name PlayerHUD
extends CanvasLayer

# ── Color constants for the health bar ────────────────────────────────────────
const COLOR_HP_HEALTHY  := Color(0.133, 0.694, 0.298, 1)   # green  ≥ 50 %
const COLOR_HP_INJURED  := Color(0.827, 0.184, 0.184, 1)   # red    < 50 %
const COLOR_STAMINA     := Color(0.753, 0.753, 0.753, 1)   # light-grey
const COLOR_ENERGY      := Color(1.0,   0.843, 0.0,   1)   # yellow
const COLOR_THIRST      := Color(0.196, 0.784, 0.941, 1)   # water-blue / cyan

# ── Hotbar visual constants ──────────────────────────────────────────────────
const HOTBAR_SLOT_SIZE := Vector2(56, 56)
const HOTBAR_SLOT_SELECTED_SIZE := Vector2(64, 64)
const HOTBAR_SELECTED_COLOR := Color(0.7, 0.85, 1.0, 1.0)   # light blue
const HOTBAR_NORMAL_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const HOTBAR_TEXTURE_PATH := "res://assets/game/textures/ui/hud_item.png"
const HOTBAR_SLOT_COUNT := 9

# ── StyleBox fill colours (reused from theme, overridden per bar) ──────────────
var _sb_hp_healthy : StyleBoxFlat
var _sb_hp_injured : StyleBoxFlat
var _sb_stamina    : StyleBoxFlat
var _sb_energy     : StyleBoxFlat
var _sb_thirst     : StyleBoxFlat

# ── Node references ────────────────────────────────────────────────────────────
@onready var hp_bar      : ProgressBar = $HUDRoot/StatsPanel/StatsVBox/Row2/HPBar
@onready var stamina_bar : ProgressBar = $HUDRoot/StatsPanel/StatsVBox/Row2/StaminaBar
@onready var energy_bar  : ProgressBar = $HUDRoot/StatsPanel/StatsVBox/Row1/EnergyBar
@onready var thirst_bar  : ProgressBar = $HUDRoot/StatsPanel/StatsVBox/Row1/ThirstBar

@onready var hp_label      : Label = $HUDRoot/StatsPanel/StatsVBox/Row2/HPBar/HPLabel
@onready var stamina_label : Label = $HUDRoot/StatsPanel/StatsVBox/Row2/StaminaBar/StaminaLabel
@onready var energy_label  : Label = $HUDRoot/StatsPanel/StatsVBox/Row1/EnergyBar/EnergyLabel
@onready var thirst_label  : Label = $HUDRoot/StatsPanel/StatsVBox/Row1/ThirstBar/ThirstLabel

@onready var hotbar_container : HBoxContainer = $HUDRoot/HotbarRow/Hotbar

# ── Tracked state ─────────────────────────────────────────────────────────────
var _player : BiologicalActor = null
var _grid : GridInventory = null
var _hotbar_slots_ui : Array[TextureRect] = []
var _hotbar_texture : Texture2D = null
var _hotbar_pressed : Array[bool] = []

## Emitted when the active hotbar slot changes via key input.
## item_id is the item ID in the newly selected slot, or "" if the slot is empty.
signal hotbar_selection_changed(item_id: String)

func _ready() -> void:
	_build_style_boxes()
	_apply_bar_styles()
	_find_player()
	_load_hotbar_texture()
	_build_hotbar_slots()
	_update_hotbar_selection()

func _process(_delta: float) -> void:
	if _player == null:
		_find_player()
		return
	_refresh_bars()
	_poll_hotbar_input()

func bind_inventory(grid: GridInventory) -> void:
	_grid = grid
	if _grid != null and not _grid.inventory_changed.is_connected(_on_inventory_changed):
		_grid.inventory_changed.connect(_on_inventory_changed)
	_update_hotbar_selection()

func _on_inventory_changed() -> void:
	_update_hotbar_selection()

# ── Hotbar ─────────────────────────────────────────────────────────────────────
func _load_hotbar_texture() -> void:
	if ResourceLoader.exists(HOTBAR_TEXTURE_PATH):
		_hotbar_texture = ResourceLoader.load(HOTBAR_TEXTURE_PATH, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
	else:
		push_warning("[PlayerHUD] Hotbar texture not found: %s" % HOTBAR_TEXTURE_PATH)

func _build_hotbar_slots() -> void:
	for child in hotbar_container.get_children():
		child.queue_free()
	_hotbar_slots_ui.clear()
	_hotbar_pressed.clear()
	for i in range(HOTBAR_SLOT_COUNT):
		var slot := TextureRect.new()
		slot.texture = _hotbar_texture
		slot.custom_minimum_size = HOTBAR_SLOT_SIZE
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hotbar_container.add_child(slot)
		_hotbar_slots_ui.append(slot)
		_hotbar_pressed.append(false)

func _update_hotbar_selection() -> void:
	var active_index := 0
	if _grid != null:
		active_index = _grid.active_hotbar_index
	for i in range(_hotbar_slots_ui.size()):
		var slot := _hotbar_slots_ui[i]
		if i == active_index:
			slot.custom_minimum_size = HOTBAR_SLOT_SELECTED_SIZE
			slot.modulate = HOTBAR_SELECTED_COLOR
		else:
			slot.custom_minimum_size = HOTBAR_SLOT_SIZE
			slot.modulate = HOTBAR_NORMAL_COLOR

func _poll_hotbar_input() -> void:
	for i in range(HOTBAR_SLOT_COUNT):
		var action_name := StringName("pe_hotbar_%d" % (i + 1))
		var is_triggered := GuideInputRuntime.is_action_triggered(action_name)
		if is_triggered and not _hotbar_pressed[i]:
			if _grid != null:
				_grid.set_active_hotbar(i)
				_update_hotbar_selection()
				hotbar_selection_changed.emit(_grid.get_active_item_id())
		_hotbar_pressed[i] = is_triggered

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
		var fill := _sb_hp_healthy if (h.max_hp > 0.0 and (h.current_hp / h.max_hp) >= 0.5) else _sb_hp_injured
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
