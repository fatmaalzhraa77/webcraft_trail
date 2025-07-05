class_name main
extends Node2D
#---------------------- constants
const CSSPanelScene = preload("res://css_panel.tscn")
const WEB_OUTPUT_DIR = "res://docs/web_output/"
const IMAGE_DIR = "images/"
#--------------------------------on ready variables
@onready var hidden_screen: Sprite2D = $HiddenScreen
@onready var back_btn: TextureButton = $SendToBackButton
@onready var dragged_btn: CanvasLayer = $CanvasLayer
@onready var tween: Tween = create_tween()
#------------------------------- variables
var html_template = """
<!DOCTYPE html>
<html>
<head>
	<title>Generated Page</title>
	<style>
		{styles}
		.heading-1 { font-size: 2em; } /* Default fallbacks */
		.heading-2 { font-size: 1.5em; }
		.draggable-element { display: block; margin: 10px; }
	</style>
</head>
<body>
	{content}
</body>
</html>
"""
var html_snippets := {}
var element_styles := {}
func _ready() -> void:
	if Global.current_project != "":
		load_ui_config()
		var css_panel_instance = CSSPanelScene.instantiate()
		add_child(css_panel_instance)
		css_panel_instance.hide()
	$BringToFrontButton.connect("pressed", Callable(self, "_on_bring_to_front_button_pressed"))
	for button in get_tree().get_nodes_in_group("draggable_buttons"):
		button.connect("code_added", Callable(self, "_on_code_added"))
		button.connect("position_changed", Callable(self, "_on_position_changed"))
		if not button.is_connected("button_deleted", Callable(self, "_on_button_deleted")):
			button.connect("button_deleted", Callable(self, "_on_button_deleted"))
	
func _on_position_changed(button_name: String, new_position: Vector2) -> void:
	generate_html()

func _on_button_deleted(button_id: String):
	# Double cleanup
	if html_snippets.has(button_id):
		html_snippets.erase(button_id)
	
	# Verify the button is actually gone
	for child in $CanvasLayer.get_children():
		if child.name == button_id:
			child.queue_free()
	generate_html()

func _on_bring_to_front_button_pressed() -> void:
	save_ui_config()
	generate_html()
	if OS.has_feature("HTML5"):
		OS.shell_open("https://fatmaalzhraa77.github.io/webcraft_trail/web_output/webcraft_output.html")
	else:
		OS.shell_open(ProjectSettings.globalize_path(WEB_OUTPUT_DIR +"/webcraft_output.html"))

func save_html_file(html_text: String, file_name: String = "webcraft_output.html"):
	var dir = DirAccess.open("res://")
	dir.make_dir_recursive(WEB_OUTPUT_DIR + IMAGE_DIR)
	var file = FileAccess.open(WEB_OUTPUT_DIR + file_name, FileAccess.WRITE)
	if file:
		file.store_string(html_text)
		file.close()
		print("HTML file saved as", file_name)
	else:
		print("Failed to save HTML file.")
func _on_code_added(button_name: String, html_code: String) -> void:
	html_snippets[button_name] = html_code
	
func combine_html_snippets() -> String:
	var combined := ""
	
	# Get all buttons with their positions
	var buttons = []
	for button_name in html_snippets:
		if $CanvasLayer.has_node(button_name):
			var button = $CanvasLayer.get_node(button_name)
			buttons.append({
				"name": button_name,
				"position": button.global_position,
				"html": html_snippets[button_name]
			})
	
	# Sort buttons by Y position (top to bottom), then X (left to right)
	buttons.sort_custom(func(a, b):
		if a.position.y != b.position.y:
			return a.position.y < b.position.y
		return a.position.x < b.position.x
	)
	
	# Combine the HTML in sorted order
	for button in buttons:
		combined += button.html + "\n"
	
	return combined

func update_button_text(button_name: String, text: String):
	var original_type = button_name.split("_copy_")[0]
	print("type ",original_type," Updating: ", button_name, "with text:", text)
	Global.update_code(original_type,button_name,text,html_snippets[button_name])
	print("the new code",Global.dic[button_name])
	# Your HTML generation logic here
	html_snippets[button_name] = Global.dic[button_name]  # Example
	generate_html()
func _on_css_updated(element_id: String, properties: Dictionary):
	# Store styles
	element_styles[element_id] = properties
	# Apply immediately to HTML
	generate_html()
	
	# Optional: Visual feedback
	if $CanvasLayer.has_node(element_id):
		var btn = $CanvasLayer.get_node(element_id)
		btn.modulate = Color(0.9, 1, 0.9)  # Flash green tint
		await get_tree().create_timer(0.3).timeout
		btn.modulate = Color.WHITE
func generate_html():
	var css_rules = ""
	for element_id in element_styles:
		css_rules += "#%s {\n" % element_id
		for prop in element_styles[element_id]:
			var value = element_styles[element_id][prop]
			# Skip empty values and zero measurements (except for 0px border)
			if value == "" or (value.ends_with("px") and value.trim_suffix("px").to_int() == 0 and prop != "border-width"):
				continue
			# Add # prefix to hex colors
			if prop in ["color", "background-color", "border-color"] and value.is_valid_html_color():
				value = "#" + value
			css_rules += "    %s: %s;\n" % [prop, value]
		css_rules += "}\n\n"
	
	for button in $CanvasLayer.get_children():
		if button.is_in_group("draggable_buttons") and html_snippets.has(button.name):
			if button.get_current_html()!="":
				html_snippets[button.name]=button.get_current_html()
	var html_content = html_template.format({"content": combine_html_snippets()})
	var final_html = html_template.format({
		"styles": css_rules,
		"content": html_content
	})
	if OS.has_feature("HTML5"):
		show_html_output(final_html)
	else:
		save_html_file(final_html)
func load_ui_config():
	var load_path = "user://projects/%s.json" % Global.current_project
	if FileAccess.file_exists(load_path):
		var file = FileAccess.open(load_path, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data:
				# Clear existing data
				for child in $CanvasLayer.get_children():
					if child is TextureButton:
						child.queue_free()
				
				# Load all saved data
				html_snippets = data.get("html_snippets", {})
				element_styles = data.get("element_styles", {})  # NEW: Load CSS styles
				
				for button_data in data.get("buttons", []):
					var original_button = load("res://draggable_button.tscn")
					var new_button = original_button.instantiate()
					
					# Basic properties
					new_button.name = button_data["name"]
					new_button.position = Vector2(button_data["position"]["x"], button_data["position"]["y"])
					new_button.custom_minimum_size = Vector2(
						button_data.get("size", {}).get("x", 64),
						button_data.get("size", {}).get("y", 64)
					)
					
					# Scaling
					if button_data.has("scale"):
						new_button.scale = Vector2(button_data["scale"]["x"], button_data["scale"]["y"])
					
					# Visuals
					if button_data["texture"]:
						new_button.texture_normal = load(button_data["texture"])
					
					# Add to workspace
					$CanvasLayer.add_child(new_button)
					new_button.is_in_workspace = true
					
					# Connect signals
					new_button.connect("code_added", Callable(self, "_on_code_added"))
					new_button.connect("button_deleted", Callable(self, "_on_button_deleted"))
					
					# Restore data
					if html_snippets.has(new_button.name):
						new_button.codes[new_button.name] = html_snippets[new_button.name]
					
					# NEW: Visual feedback for styled elements
					if button_data.get("has_styles", false):
						new_button.modulate = Color(0.9, 1, 0.9)  # Light green tint
				
				# Generate initial HTML with styles
				generate_html()
func save_ui_config() -> void:
	Global.update_all_projects(Global.current_project)
	var ui_data = {
		"project_name": Global.current_project,
		"buttons": [],
		"html_snippets": html_snippets,
		"element_styles": element_styles,  # NEW: Save CSS styles
		"ui_scale": 1.0,
	}
	
	for button in $CanvasLayer.get_children():
		if button is TextureButton:
			ui_data["buttons"].append({
				"name": button.name,
				"position": {"x": button.position.x, "y": button.position.y},
				"size": {
					"x": button.custom_minimum_size.x if button.has_method("get_custom_minimum_size") else 64,
					"y": button.custom_minimum_size.y if button.has_method("get_custom_minimum_size") else 64
				},
				"scale": {"x": button.scale.x, "y": button.scale.y},
				"texture": button.texture_normal.resource_path if button.texture_normal else "",
				"html_code": html_snippets.get(button.name, ""),
				"has_styles": element_styles.has(button.name)  # NEW: Style indicator
			})
	
	var save_path = "user://projects/%s.json" % Global.current_project
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("projects"):
		dir.make_dir("projects")
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(ui_data, "\t"))
func update_button_type(button_name:String,new_type:String)->void:
	html_snippets[button_name]=Global.button_or_input(new_type,button_name)
	print(html_snippets[button_name])
	generate_html()
func show_html_output(html_content: String):
	# Open in new tab for web version
	JavaScriptBridge.eval("""
		var newWindow = window.open();
		newWindow.document.open();
		newWindow.document.write(`%s`);
		newWindow.document.close();
	""" % html_content.replace("`", "\\`"))
