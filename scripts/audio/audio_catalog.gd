class_name AudioCatalog
extends RefCounted

const STARTUP_AUDIO_GROUPS := [
	{
		"category": "ui",
		"load_phase": "startup",
		"folder": "res://assets/game/sounds/ui",
		"files": [
			"cancel.mp3",
			"click.mp3",
			"equip.mp3",
			"select.mp3",
			"shopping_buy.mp3",
		],
	},
	{
		"category": "music",
		"load_phase": "startup",
		"folder": "res://assets/game/sounds/music",
		"files": [
			"main_menu.mp3",
		],
	},
]

const GAMEPLAY_AUDIO_GROUPS := [
	{
		"category": "game",
		"load_phase": "game_load",
		"folder": "res://assets/game/sounds/sounds",
		"files": [
			"entity_hurt.mp3",
			"handgun_shoot.mp3",
			"human_die.mp3",
			"mob_die.mp3",
			"mag_empty.mp3",
			"reload.mp3",
		],
	},
	{
		"category": "environment",
		"load_phase": "game_load",
		"folder": "res://assets/game/sounds/music",
		"files": [
			"game_scene.mp3",
		],
	},
]
