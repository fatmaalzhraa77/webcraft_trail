extends Button
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var del_btn: Button = $ScrollContainer/VBoxContainer/Button
@onready var tx_btn: Button = $ScrollContainer/VBoxContainer/Button2
@onready var css_btn: Button = $ScrollContainer/VBoxContainer/Button3
@onready var type_btn: OptionButton = $ScrollContainer/VBoxContainer/OptionButton
@onready var lb: Label = $ScrollContainer/VBoxContainer/Label
@onready var image_btn:Button=$ScrollContainer/VBoxContainer/Button4
#---------------------------------------------------------------
signal edit_option_selected(option: String)  # 'delete', 'text', or 'css'
signal type_change(new_type:String)
#------------------------------------------------------------------
var parent_button: TextureButton
var flag:bool=false
var image:bool=false
func _ready():
	scroll_container.visible = false
	hide()  
	parent_button = get_parent() as TextureButton
	if not parent_button:
		push_error("EditButton must be child of a TextureButton")
		return
	
	# Connect signals
	del_btn.pressed.connect(_on_option_pressed.bind("delete"))
	tx_btn.pressed.connect(_on_option_pressed.bind("text"))
	css_btn.pressed.connect(_on_option_pressed.bind("css"))
	image_btn.pressed.connect(_on_option_pressed.bind("image"))
	type_btn.item_selected.connect(_on_type_selected)  
	self.pressed.connect(_on_edit_pressed)
	_setup_type_options()

func _on_edit_pressed():
	scroll_container.visible = !scroll_container.visible
	if scroll_container.visible:
		lb.visible=flag
		type_btn.visible=flag
		image_btn.visible=image
		edit_option_selected.emit("edit_opened")
		_hide_all_ui_elements()


func _hide_all_ui_elements():
	if parent_button.has_node("DeleteButton"):
		parent_button.get_node("DeleteButton").hide()
	if parent_button.has_node("CSSButton"):
		parent_button.get_node("CSSButton").hide()
	if parent_button.has_node("Panel"):
		parent_button.get_node("Panel").hide()

func _setup_type_options():
	type_btn.clear()
	if parent_button.name.begins_with("DraggableButton10"):
		flag=true
		type_btn.add_item("button")
		type_btn.add_item("reset")
		type_btn.add_item("submit")
	elif parent_button.name.begins_with("DraggableButton12"):
		flag=true
		image=true
		var input_types = [
			"image", "checkbox", "color", "date", "datetime-local",
			"email", "file", "hidden", "button", "month",
			"number", "password", "radio", "range", "reset",
			"search", "submit", "tel", "text", "time",
			"url", "week"
		]
		for type in input_types:
			type_btn.add_item(type)
	elif parent_button.name.begins_with("DraggableButton11"):
		image=true

func _on_option_pressed(option: String):
	scroll_container.visible = false
	edit_option_selected.emit(option)
func _on_type_selected(index: int):
	var selected_type = type_btn.get_item_text(index)
	emit_signal("type_change", selected_type)
