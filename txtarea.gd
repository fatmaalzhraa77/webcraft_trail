extends TextureButton

# Drag and Drop Variables
var is_dragging := false
var drag_copy : TextureButton = null
var is_in_workspace := false
var drag_offset := Vector2()
var target_position := Vector2()
var lerp_speed := 20.0


# Resize Variables
var is_resizing := false
var resize_handle_size := 15
var min_size := Vector2(100, 50)
var max_size := Vector2(400, 300)
var initial_mouse_pos := Vector2()
var initial_size := Vector2()

# Text Edit Variable
var text_edit : TextEdit

func _ready() -> void:
	# Original connections
	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up"))
	
	# Add text edit if in workspace
	if is_in_workspace:
		setup_text_area()
		add_resize_handle()

func setup_text_area():
	text_edit = TextEdit.new()
	text_edit.size = size - Vector2(200, 200)
	text_edit.position =  Vector2(250, -10)
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(text_edit)

func add_resize_handle():
	var resize_handle = TextureButton.new()
	# PROPER WAY to set button textures in code:
	var style_box = StyleBoxTexture.new()
	style_box.texture = preload("res://resize_handle.png")
	resize_handle.add_theme_stylebox_override("normal", style_box)
	resize_handle.add_theme_stylebox_override("pressed", style_box)
	resize_handle.add_theme_stylebox_override("hover", style_box)
	
	resize_handle.custom_minimum_size = Vector2(resize_handle_size, resize_handle_size)
	resize_handle.position = Vector2(size.x - resize_handle_size, size.y - resize_handle_size)
	resize_handle.name = "ResizeHandle"
	resize_handle.connect("button_down", Callable(self, "_on_resize_start"))
	add_child(resize_handle)

func _on_resize_start():
	is_resizing = true
	initial_mouse_pos = get_global_mouse_position()
	initial_size = size

func _on_button_down() -> void:
	if is_resizing: return
	
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	
	if not is_in_workspace:
		create_drag_copy()
	else:
		drag_copy = self

func _on_button_up() -> void:
	is_dragging = false
	is_resizing = false
	
	if drag_copy:
		if drag_copy != self:
			drag_copy.is_in_workspace = true
			drag_copy.setup_text_area()
			drag_copy.add_resize_handle()
			
			# Disconnect original signals
			drag_copy.disconnect("button_down", Callable(self, "_on_button_down"))
			drag_copy.disconnect("button_up", Callable(self, "_on_button_up"))
		
		drag_copy = null

func _process(delta: float) -> void:
	if is_resizing:
		handle_resize()
	elif is_dragging and drag_copy:
		handle_drag(delta)

func handle_drag(delta: float):
	target_position = get_global_mouse_position() - drag_offset
	drag_copy.global_position = drag_copy.global_position.lerp(target_position, lerp_speed * delta)

func handle_resize():
	var mouse_delta = get_global_mouse_position() - initial_mouse_pos
	var new_size = initial_size + Vector2(mouse_delta.x, mouse_delta.y)
	new_size = new_size.clamp(min_size, max_size)
	
	size = new_size
	if has_node("ResizeHandle"):
		$ResizeHandle.position = Vector2(size.x - resize_handle_size, size.y - resize_handle_size)
	if text_edit:
		text_edit.size = size - Vector2(20, 20)

func create_drag_copy() -> void:
	drag_copy = duplicate()
	drag_copy.position = global_position
	var canvas_layer = get_tree().root.get_node("main/CanvasLayer")
	if canvas_layer:
		canvas_layer.add_child(drag_copy)
		drag_copy.connect("button_down", Callable(self, "_on_button_down"))
		drag_copy.connect("button_up", Callable(self, "_on_button_up"))

func _input(event: InputEvent):
	if is_resizing and event is InputEventMouseButton and not event.pressed:
		is_resizing = false
