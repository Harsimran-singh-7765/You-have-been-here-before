extends Control

# --- CONFIGURATION (Drag & Drop) ---
# Ye variable Inspector mein dikhega. 
# Wahan apni "World.tscn" ya "Game.tscn" drag karke drop kar dena.
@export_file("*.tscn") var game_scene_path: String

# --- NODES (Based on your image structure) ---
@onready var intro_video: VideoStreamPlayer = $IntroVideo
@onready var menu_ui: MarginContainer = $MarginContainer

# Button Paths (image ke hisaab se exact path)
@onready var btn_start: Button = $MarginContainer/TextureRect/CenterContainer/VBoxContainer/Start_game
@onready var btn_exit: Button = $MarginContainer/TextureRect/CenterContainer/VBoxContainer/Exit

func _ready() -> void:
	# 1. Start State: Video ON, Menu OFF
	menu_ui.visible = false
	intro_video.visible = true
	
	# Video play karo
	intro_video.play()
	
	# 2. Signals Connect karo (Taaki click kaam kare)
	intro_video.finished.connect(_on_video_finished)
	
	# Agar button paths sahi hain toh connect karo
	if btn_start:
		btn_start.pressed.connect(_on_start_pressed)
	if btn_exit:
		btn_exit.pressed.connect(_on_exit_pressed)

func _process(_delta: float) -> void:
	# OPTIONAL: Agar Space/Enter dabaye toh video skip ho jaye
	if intro_video.visible and Input.is_action_just_pressed("ui_accept"):
		_on_video_finished()

# --- LOGIC FUNCTIONS ---

func _on_video_finished() -> void:
	# Video band karo aur chupa do
	intro_video.stop()
	intro_video.visible = false
	
	# Main Menu (Background + Buttons) dikhao
	menu_ui.visible = true

# In main_menu.gd

func _on_start_pressed() -> void:
	if game_scene_path:
		# Button lock karo
		btn_start.disabled = true
		
		# Saara kaam TransitionScreen ko sonp do
		TransitionScreen.transition_to(game_scene_path)
		
		# Ab ye script delete bhi ho jaye toh fark nahi padta, 
		# kyunki TransitionScreen sambhal raha hai.
func _on_exit_pressed() -> void:
	# Game band karne ke liye
	get_tree().quit()
