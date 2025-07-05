# Global.gd
extends Node

var current_project := ""
var all_projects := {}  
var dic:={}
var values:={}
# Helper function to format dates
func _format_readable_date() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "{year}-{month}-{day} {hour}:{minute}".format({
		"year": datetime["year"],
		"month": str(datetime["month"]).pad_zeros(2),
		"day": str(datetime["day"]).pad_zeros(2),
		"hour": str(datetime["hour"]).pad_zeros(2),
		"minute": str(datetime["minute"]).pad_zeros(2)
	})

func print_dec(dec:Dictionary)->void:
	print(dec)
func update_code(btn_name: String, key: String, txt: String,html:String) -> void:
	var value: String = txt
	var element_id = key
	var element_class = ""
	var content = ""
	if value.is_empty():
		dic[key]=html
	else:
		match btn_name:
			"DraggableButton":
				content = "<h1>%s</h1>" % value
				element_class = "heading-1"
			"DraggableButton2":
				content = "<h2>%s</h2>" % value
				element_class = "heading-2"
			"DraggableButton3":
				content = "<h3>%s</h3>" % value
				element_class = "heading-3"
			"DraggableButton4":
				content = "<h4>%s</h4>" % value
				element_class = "heading-4"
			"DraggableButton5":
				content = "<a href='%s'>Link</a>" % value
				element_class = "link"
			"DraggableButton6", "DraggableButton7":
				content = "<p>%s <span class='blue-text'>blue</span> eyes.</p>" % value
				element_class = "paragraph"
			"DraggableButton8":
				content = "<strong>%s</strong>" % value
				element_class = "strong-text"
			"DraggableButton9":
				content = "<textarea rows='3' cols='20'>%s</textarea>" % value
				element_class = "text-input"
			"DraggableButton10":
				values=parse_html_attributes(html)
				content = "<button type='%s'>%s</button>" % [values["type"],value]
				element_class = "custom-button"
			"DraggableButton11":
				values=parse_html_attributes(html)
				content = "<img src='%s' alt='%s' class='image'>" % [values["src"],value]
				element_class = "image-container"
			"DraggableButton12":
				values=parse_html_attributes(html)
				if values["type"]=="image":
					content = "<input type='image' src='%s' alt='%s'>" % [values["src"],values]
					element_class = "image-input"
				else:
					content = "<input type='%s' value='%s'>" % [values["type"],value]
					element_class=values["type"]+"-input"
	# Wrap updated content with same structurey
	dic[key] = "<div id='%s' class='draggable-element %s'>%s</div>" % [element_id, element_class, content]

# Global.gd

# Store metadata as a dictionary with project names as keys

# Load metadata from JSON file
func load_meta_data() -> void:
	var file_path = "user://projects_meta.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json = file.get_as_text()
			all_projects = JSON.parse_string(json)
			file.close()
	# Initialize if empty or failed to load
	if all_projects == null:
		all_projects = {}

# Save metadata to JSON file
func save_meta_data() -> void:
	DirAccess.make_dir_recursive_absolute("user://")
	var file = FileAccess.open("user://projects_meta.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(all_projects, "\t"))
		file.close()

# Update project metadata
func update_all_projects(project_name: String) -> void:
	var timestamp = Time.get_datetime_string_from_system()
	if not all_projects.has(project_name):
		all_projects[project_name] = {
			"created": timestamp,
			"modified": timestamp
		}
	else:
		all_projects[project_name]["modified"] = timestamp
	save_meta_data()
func button_or_input(type:String,btn_name:String)->String:
	var btn_type = btn_name.split("_copy_")[0]
	var value:String=""
	var content=""
	var element_class=""
	if value.is_empty():
		value=type
	if btn_type=="DraggableButton10":
		element_class = "custom-button"
		content="<button type='%s'>%s</button>" % [type,value]
	elif btn_type=="DraggableButton12":
		element_class=type+"-input"
		if type=="image":
			content="<input type='image' src='images/webcraft.jpg' alt='%s'>"% value
		else:
			content="<input type='%s'  value='%s'>"%[type,value]
	return "<div id='%s' class='draggable-element %s'>%s</div>" % [btn_name, element_class, content]
func parse_html_attributes(html: String) -> Dictionary:
	var result = {
		"type": "",
		"value": "",
		"src": ""
	}
	var main_tag = ""
	if "<button" in html:
		main_tag = "button"
	elif "<input" in html:
		main_tag = "input"
	elif "<img" in html:
		main_tag = "img"
	else:
		return result  # Not a supported element
	
	# Extract attributes using regex
	var regex = RegEx.new()
	
	# Get type attribute
	regex.compile("type=['\"](.*?)['\"]")
	var type_match = regex.search(html)
	if type_match:
		result["type"] = type_match.get_string(1)
	
	# Get value attribute
	regex.compile("value=['\"](.*?)['\"]")
	var value_match = regex.search(html)
	if value_match:
		result["value"] = value_match.get_string(1)
	
	# Get src attribute (for images)
	regex.compile("src=['\"](.*?)['\"]")
	var src_match = regex.search(html)
	if src_match:
		result["src"] = src_match.get_string(1)
	print(result)
	return result
