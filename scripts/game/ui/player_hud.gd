class_name PlayerHUD
extends CanvasLayer

# ── Color constants for the health bar ────────────────────────────────────────
const COLOR_HP_HEALTHY  := Color(0.133, 0.694, 0.298, 1)   # green  ≥ 50 %
const COLOR_HP_INJURED  := Color(0.827, 0.184, 0.184, 1)   # red    < 50 %
const COLOR_STAMINA     := Color(0.753, 0.753, 0.753, 1)   # light-grey
const COLOR_ENERGY      := Color(1.0,   0.843, 0.0,   1)   # yellow
const COLOR_THIRST      := Color(0.196, 0.784, 0.941, 1)   # water-blue / cyan

# ── Hotbar visual constants (no texture, pure StyleBoxFlat) ──────────────────
const HOTBAR_SLOT_SIZE := Vector2(56, 56)
const HOTBAR_SLOT_SELECTED_SIZE := Vector2(64, 64)
const HOTBAR_BG_COLOR := Color(0.0, 0.0, 0.0, 64.0 / 255.0)        # alpha = 64
const HOTBAR_SELECTED_BG_COLOR := Color(0.0, 0.0, 0.3, 64.0 / 255.0) # deep blue, alpha = 64
const HOTBAR_BORDER_COLOR := Color(0.0, 0.0, 0.0, 1.0)               # pure black
const HOTBAR_BORDER_WIDTH := 6
const HOTBAR_CORNER_RADIUS := 8
const HOTBAR_SLOT_COUNT := 9

# ── StyleBox fill colours (reused from theme, overridden per bar) ──────────────
var _sb_hp_healthy : StyleBoxFlat
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
var _hotbar_slots_ui : Array[PanelContainer] = []
var _hotbar_pressed : Array[bool] = []

## Emitted when the active hotbar slot changes via key input.
## item_id is the item ID in the newly selected slot, or "" if the slot is empty.
signal hotbar_selection_changed(item_id: String)

func _ready() -> void:
	_build_style_boxes()
	_apply_bar_styles()
	_find_player()
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
static func _make_hotbar_stylebox(is_selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = HOTBAR_SELECTED_BG_COLOR if is_selected else HOTBAR_BG_COLOR
	sb.border_width_left = HOTBAR_BORDER_WIDTH
	sb.border_width_top = HOTBAR_BORDER_WIDTH
	sb.border_width_right = HOTBAR_BORDER_WIDTH
	sb.border_width_bottom = HOTBAR_BORDER_WIDTH
	sb.border_color = HOTBAR_BORDER_COLOR
	sb.corner_radius_top_left = HOTBAR_CORNER_RADIUS
	sb.corner_radius_top_right = HOTBAR_CORNER_RADIUS
	sb.corner_radius_bottom_right = HOTBAR_CORNER_RADIUS
	sb.corner_radius_bottom_left = HOTBAR_CORNER_RADIUS
	return sb

func _build_hotbar_slots() -> void:
	for child in hotbar_container.get_children():
		child.queue_free()
	_hotbar_slots_ui.clear()
	_hotbar_pressed.clear()
	for i in range(HOTBAR_SLOT_COUNT):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = HOTBAR_SLOT_SIZE
		slot.add_theme_stylebox_override("panel", _make_hotbar_stylebox(false))
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
			slot.add_theme_stylebox_override("panel", _make_hotbar_stylebox(true))
		else:
			slot.custom_minimum_size = HOTBAR_SLOT_SIZE
			slot.add_theme_stylebox_override("panel", _make_hotbar_stylebox(false))

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
	_sb_hp_healthy = hp_bar.get_theme_stylebox("fill")
	_sb_hp_healthy.bg_color = COLOR_HP_HEALTHY

	_sb_stamina = stamina_bar.get_theme_stylebox("fill")
	_sb_stamina.bg_color = COLOR_STAMINA

	_sb_energy = energy_bar.get_theme_stylebox("fill")
	_sb_energy.bg_color = COLOR_ENERGY

	_sb_thirst = thirst_bar.get_theme_stylebox("fill")
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
