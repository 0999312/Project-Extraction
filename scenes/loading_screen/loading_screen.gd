extends LoadingScreen
## Extended loading screen that registers gameplay-phase audio on ready.
##
## The opening scene registers the audio registry and startup audio groups.
## When the loading screen appears (transitioning to a game scene), we register
## the gameplay audio groups so they are available before the game scene loads.


func _ready() -> void:
	super._ready()
	AudioCatalog.register_gameplay_audio()
