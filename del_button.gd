extends TextureButton

# Configuration
const BACK_LAYER_Z_INDEX := -100
const DELETE_BUTTON_POSITION := Vector2(550, 350)
var auto_hide_timer: Timer

func _ready():
	# Initial setup
	hide()
	disabled = true
	z_index = 100
	
	# Create auto-hide timer
	auto_hide_timer = Timer.new()
	add_child(auto_hide_timer)
	auto_hide_timer.timeout.connect(_on_auto_hide_timeout)
	
	# Connect signals
	connect("pressed", _on_pressed)
	
	# Wait one frame to ensure parent is ready
	await get_tree().process_frame
	
	var parent = get_parent()
	if parent is TextureButton:
		parent.connect("button_up", _on_parent_dropped)
	else:
		push_error("DeleteButton must be child of a TextureButton")

func _on_parent_dropped():
	# Only show if explicitly requested (via edit panel)
	pass

func show_button():
	show()
	disabled = false
	position = DELETE_BUTTON_POSITION
	# Start auto-hide timer
	auto_hide_timer.start(1.0)

func _on_auto_hide_timeout():
	if not disabled:
		hide()
		disabled = true

func _on_pressed():
	var parent = get_parent()
	if parent is TextureButton:
		if parent.has_method("delete_button"):
			parent.delete_button()
	else:
		parent.emit_signal("button_deleted", parent.name)
		parent.queue_free()
	
	# Force immediate HTML update
	var main = get_node("/root/main")
	if main and main.has_method("generate_html"):
		main.generate_html()

	# Ensure button is properly hidden after deletion
	hide()
	disabled = true
	if auto_hide_timer:
		auto_hide_timer.stop()
