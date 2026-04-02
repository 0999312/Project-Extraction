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

## Item rarity level (0 = none, 1 = common, 2 = uncommon, 3 = rare, 4 = epic, 5 = legendary).
@export_range(0, 5) var rarity: int = 0

## Custom occupancy pattern. If empty, uses a filled rectangle of size_w × size_h.
## Each entry is a Vector2i offset from the top-left origin that the item occupies.
## Example: for an L-shaped item (2 wide, 3 tall, missing top-right):
##   [(0,0), (0,1), (0,2), (1,2)]
@export var pattern: Array[Vector2i] = []
