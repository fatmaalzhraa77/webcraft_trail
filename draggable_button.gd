extends TextureButton  
#-------------------------------------variables
var image_path := ""
var image_upload_button: Button
var is_dragging := false
var drag_copy : TextureButton = null  # This will hold the duplicate button
var is_in_workspace := false  # Track if the block is in the workspace
var drag_offset := Vector2()  # Offset between the mouse and the block's position
var target_position := Vector2()  # Target position for smooth movement
var lerp_speed := 20.0  # Speed of smooth movement (higher = faster)
var indx:int =0
var codes=Dictionary()
#-------------------------- ready variables
@onready var panel=$Panel
@onready var drop_hint: Panel = $DropHint
@onready var del_btn:TextureButton=$DeleteButton
@onready var edit_btn:Button=$EditButton # Add as child node in scene
@onready var file_dialog: FileDialog = $ImageFileDialog
@onready var thumbnail: Sprite2D = $Thumbnail
#------------------------------------ signals
signal code_added(button_name: String, html_code: String)
signal button_deleted(button_id)
signal position_changed(button_name, new_position)
signal files_dropped(files: PackedStringArray)  
func delete_button():
	# Clean up before deletion
	emit_signal("button_deleted", name)
	if codes.has(name):
		codes.erase(name)
	
	# Remove from CanvasLayer
	if get_parent():
		get_parent().remove_child(self)
	queue_free()


func _ready() -> void:
	thumbnail.hide()
	edit_btn.edit_option_selected.connect(_handle_edit_option)
	panel.text_submitted.connect(_on_panel_text_submitted)
	edit_btn.type_change.connect(on_type_changed) 
	# Connect the button's pressed signal to start dragging
	
	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up"))
	add_to_group("draggable_buttons")
	   # Initialize default styles
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.png ; PNG Images", "*.jpg ; JPEG Images"]
	file_dialog.file_selected.connect(_on_image_selected)


func show_edit_panel():
	panel.show()
	
func _on_button_down() -> void:
	# Start dragging
	is_dragging = true
	# Calculate the offset between the mouse and the block's position
	drag_offset = get_global_mouse_position() - global_position

	# If the block is in the scrollbar, create a copy in the workspace
	if not is_in_workspace:
		create_drag_copy()
		store_str(self.name,drag_copy.name,codes)
	else:
		# If the block is already in the workspace, drag it directly
		drag_copy = self

func _on_button_up() -> void:
	# Stop dragging 
	is_dragging = false
	_on_dropped()
	if drag_copy:
		# If the block was copied, mark it as part of the workspace
		if drag_copy != self:
			drag_copy.is_in_workspace = true

		# Disconnect the duplicate's signals (if it was a copy)
		if drag_copy != self:
			drag_copy.disconnect("button_down", Callable(self, "_on_button_down"))
			drag_copy.disconnect("button_up", Callable(self, "_on_button_up"))

		drag_copy = null  # Clear the reference to the duplicate

func _process(delta: float) -> void:
	if is_dragging and drag_copy:
		# Calculate the target position for smooth movement
		target_position = get_global_mouse_position() - drag_offset

		# Use linear interpolation (lerp) to smoothly move the block
		drag_copy.global_position = drag_copy.global_position.lerp(target_position, lerp_speed * delta)
		emit_signal("position_changed", drag_copy.name)

func create_drag_copy() -> void:
	# Duplicate the original button
	drag_copy = duplicate()
	drag_copy.name=self.name+"_copy_"+str(indx) 
	#print(drag_copy.name)
	indx=indx+1
	drag_copy.position = global_position  # Set the duplicate's position to match the original
	
	# Find the CanvasLayer (or workspace) and add the duplicate to it
	var canvas_layer = get_tree().root.get_node("main/CanvasLayer")
	if canvas_layer:
		canvas_layer.add_child(drag_copy)

	# Connect the duplicate's signals (so it can be dragged again)
	drag_copy.connect("button_down", Callable(self, "_on_button_down"))
	drag_copy.connect("button_up", Callable(self, "_on_button_up"))


func store_str(name: String, key, co: Dictionary) -> void:
	var element_id = key  # Use the provided key as our unique ID
	var content = ""
	var element_class = ""
	
	match name:
		"DraggableButton":
			content = "<h1>Hello world!</h1>"
			element_class = "heading-1"
		"DraggableButton2":
			content = "<h2>Hello world!</h2>"
			element_class = "heading-2"
		"DraggableButton3":
			content = "<h3>Hello world!</h3>"
			element_class = "heading-3"
		"DraggableButton4":
			content = "<h4>Hello world!</h4>"
			element_class = "heading-4"
		"DraggableButton5":
			content = "<a href='link'>Visit W3Schools.com!</a>"
			element_class = "link"
		"DraggableButton6", "DraggableButton7":
			content = "<p>My mother has <span class='blue-text'>blue</span> eyes.</p>"
			element_class = "paragraph"
		"DraggableButton8":
			content = "<strong>This text is important!</strong>"
			element_class = "strong-text"
		"DraggableButton9":
			content = "<textarea rows='3' cols='20'>Enter your text here...</textarea>"
			element_class = "text-input"
		"DraggableButton10":
			content = "<button type='button'>Click Me!</button>"
			element_class = "custom-button"
		"DraggableButton11":
			if image_path!= "":
				content = "<img src='%s' alt='User image' class='image'>" % image_path
			else:  # Fall back to default
				content = "<img src='images/webcraft.jpg' alt='Default image' class='image'>"
			element_class ="image-container"
		"DraggableButton12":
			if image_path != "":
				content = "<input type='image' src='%s' alt='Submit'>" % image_path
			else:
				content = "<input type='image' src='images/webcraft.jpg' alt='Submit'>"
			element_class = "image-input"
	
	# Wrap content in a styled container with ID and class
	co[key] = "<div id='%s' class='draggable-element %s'>%s</div>" % [element_id, element_class, content]
	emit_signal("code_added", key, co[key])
	#missing part just in case 
func _on_panel_text_submitted(parent:String,text: String):
	emit_signal("panel_text_submitted", name, text)
	var main = get_tree().root.get_node("main") 
	if main:
		main.update_button_text(self.name, text)
func _on_css_button_pressed():
	var css_panel = preload("res://css_panel.tscn").instantiate()
	
	# Add as child of main node
	var main = get_tree().root.get_node("main")
	main.add_child(css_panel)
	
	# Initialize with current styles
	css_panel.main_node = main
	css_panel.show_for_element(name)
	
	# Connect signals
	css_panel.css_updated.connect(main._on_css_updated)
	css_panel.panel_closed.connect(func(): css_panel.queue_free())

func _on_dropped():
	edit_btn.show()
	#edit_btn.position = Vector2(size.x - edit_btn.size.x - 10, 10)

func _handle_edit_option(option: String):
	match option:
		"edit_opened":
			del_btn.hide()
			panel.hide()
		
		"delete":
			del_btn.show()
			del_btn.disabled = false
			edit_btn.hide()
		
		"text":
			panel.show()
			edit_btn.hide()
		
		"css":
			edit_btn.hide()
			_on_css_button_pressed()
		"image":
			_open_image_dialog()
			pass
func _open_image_dialog():
	file_dialog.popup_centered()
func _is_image_element() -> bool: 
	return name.begins_with("DraggableButton11") or name.begins_with("DraggableButton12")
func _on_image_selected(selected_path: String):
	# Create destination directory
	var dest_dir = DirAccess.open("res://")
	if dest_dir.make_dir_recursive("web_output/images") != OK:
		push_error("Couldn't create images folder")
		return
	
	# Generate unique filename
	var timestamp = Time.get_unix_time_from_system()
	var new_name = "img_%s_%d.%s" % [name, timestamp, selected_path.get_extension()]
	var dest_path = "res://docs/web_output/images/" + new_name
	
	# Copy the image
	if dest_dir.copy(selected_path, dest_path) == OK:
		image_path = "images/" + new_name
		_update_thumbnail(dest_path)
		update_image_html()
	else:
		_show_error("Failed to save image")
func _update_thumbnail(image_path: String):
	var img = Image.load_from_file(image_path)
	if img:
		var texture = ImageTexture.create_from_image(img)
		thumbnail.texture = texture
		thumbnail.show()
		
		# Calculate scaling to fit button
		var scale_factor = min(
			float(size.x) / img.get_width(),
			float(size.y) / img.get_height()
		) * 0.8  # 80% of available space
		thumbnail.scale = Vector2(scale_factor, scale_factor)

func _show_error(message: String):
	var error_popup = AcceptDialog.new()
	error_popup.title = "Error"
	error_popup.dialog_text = message
	add_child(error_popup)
	error_popup.popup_centered()
	await error_popup.confirmed
	error_popup.queue_free()
func update_image_html():
	if name.begins_with("DraggableButton11"):
		codes[name] = "<img id='%s' src='%s' alt='User image' class='image'>" % [name, image_path]
	elif name.begins_with("DraggableButton12"):
		codes[name] = "<input id='%s' type='image' src='%s' alt='Submit'>" % [name, image_path]
	emit_signal("code_added", name, codes[name])
func get_current_html() -> String:
	if name.begins_with("DraggableButton11") and image_path != "":
		return "<div id='%s' class='draggable-element image-container'><img src='%s' alt='User image'></div>" % [name, image_path]
	print(codes.get(name, ""))
	return codes.get(name, "")
func on_type_changed(new_type:String):
	var btn_name=self.name
	var original_type = btn_name.split("_copy_")[0]
	var main = get_tree().root.get_node("main") 
	if main:
		main.update_button_type(btn_name,new_type)
