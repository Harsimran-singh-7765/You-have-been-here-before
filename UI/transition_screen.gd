extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.visible = false
	color_rect.modulate.a = 0.0

# Basic Fade Logic (Tumhara existing code)
func fade(target_alpha: float, duration: float = 1.0) -> Tween:
	if target_alpha > 0.0:
		color_rect.visible = true
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", target_alpha, duration)
	
	if target_alpha == 0.0:
		tween.tween_callback(func(): color_rect.visible = false)
	
	return tween

# --- NEW FUNCTION (Ye sab kuch handle karega) ---
func transition_to(target_path: String) -> void:
	# 1. Fade Out (Andhera)
	await fade(1.0, 1.0).finished
	
	# 2. Scene Change (Autoload zinda rahega, toh ye line chalegi)
	get_tree().change_scene_to_file(target_path)
	
	# 3. Wait for Load (Smoothness)
	await get_tree().create_timer(0.1).timeout
	
	# 4. Fade In (Ujala)
	await fade(0.0, 1.0).finished
