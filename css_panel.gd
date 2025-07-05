extends Panel

signal css_updated(element_id: String, properties: Dictionary)
signal panel_closed
# Control references
@onready var color_picker = $Color
@onready var bg_color_picker = $bk_Color
@onready var board_color = $BorderColor
@onready var border_style = $BorderStyleOptionButton
@onready var border_width = $BorderWidthSpin
@onready var font_size_spin = $FontSpin
@onready var width_spin = $width
@onready var height_spin = $HeightSpin
@onready var padding_top = $paddingTopSpin
@onready var padding_left = $paddingLeftSpin
@onready var padding_right = $paddingRightSpin
@onready var padding_bottom = $paddingButtomSpin
@onready var margin_top = $marginTopSpin
@onready var margin_right = $marginRightSpin
@onready var margin_left = $marginLeftSpin
@onready var margin_bottom = $marginButtonSpin
@onready var text_align = $TextAlginOptionButton
@onready var ok_btn = $ok_btn
@onready var cancel_btn = $close_btn
var current_element_id: String = ""
var main_node: Node
func _ready():
	main_node = get_tree().root.get_node("main")
	ok_btn.pressed.connect(_on_apply_pressed)
	cancel_btn.pressed.connect(hide)
	
	# Initialize border style options if not set in editor

func show_panel(element_id: String, current_styles: Dictionary):
	current_element_id = element_id
	_load_styles(current_styles)
	show()


func _load_spacing_property(prop: String, styles: Dictionary, controls: Array):
	if styles.has(prop):
		var values = styles[prop].split(" ")
		for i in min(values.size(), controls.size()):
			controls[i].value = values[i].to_float()

func _on_apply_pressed():
	var styles = _collect_styles()
	emit_signal("css_updated", current_element_id, styles)
	hide()
	emit_signal("panel_closed")

func _on_cancel_pressed():
	hide()
	emit_signal("panel_closed")

func _collect_styles() -> Dictionary:
	var styles = {}
	# Only include properties with valid values
	if color_picker.color != Color.TRANSPARENT:
		styles["color"] = color_picker.color.to_html(false) # Remove alpha
	
	if bg_color_picker.color != Color.TRANSPARENT:
		styles["background-color"] = bg_color_picker.color.to_html(false)
	
	if board_color.color != Color.TRANSPARENT:
		styles["border-color"] = board_color.color.to_html(false)
	
	if border_width.value > 0:
		styles["border-width"] = "%dpx" % border_width.value
		styles["border-style"] = border_style.get_item_text(border_style.selected)
	
	if font_size_spin.value > 0:
		styles["font-size"] = "%dpx" % font_size_spin.value
	
	# Only include if at least one value is non-zero
	var padding = _format_spacing_values([padding_top, padding_right, padding_bottom, padding_left])
	if "0px 0px 0px 0px" != padding:
		styles["padding"] = padding
	
	var margin = _format_spacing_values([margin_top, margin_right, margin_bottom, margin_left])
	if "0px 0px 0px 0px" != margin:
		styles["margin"] = margin
	
	var align = text_align.get_item_text(text_align.selected)
	if align != "":
		styles["text-align"] = align
	
	return styles
func _format_spacing_values(controls: Array) -> String:
	return "%dpx %dpx %dpx %dpx" % [
		controls[0].value,
		controls[1].value,
		controls[2].value,
		controls[3].value
	]
func show_for_element(element_id: String):
	# Get reference to viewport for sizing
	var viewport = get_viewport_rect().size
	# Center the panel
	position = (viewport - size) / 2
	# Get current styles
	var current_styles = main_node.element_styles.get(element_id, {})
	show_panel(element_id, current_styles)
func _load_styles(styles: Dictionary):
	# Color properties
	if styles.has("color"):
		color_picker.color = Color(styles["color"])
	if styles.has("background-color"):
		bg_color_picker.color = Color(styles["background-color"])
	if styles.has("border-color"):
		board_color.color = Color(styles["border-color"])
	
	# Border properties
	if styles.has("border-style"):
		var target_style = styles["border-style"]
		for i in border_style.item_count:
			if border_style.get_item_text(i) == target_style:
				border_style.selected = i
				break
	
	if styles.has("border-width"):
		border_width.value = styles["border-width"].to_float()
	
	# Sizing
	if styles.has("width"):
		width_spin.value = styles["width"].to_float()
	if styles.has("height"):
		height_spin.value = styles["height"].to_float()
	
	# Spacing
	_load_spacing_property("padding", styles, 
						 [padding_top, padding_right, padding_bottom, padding_left])
	_load_spacing_property("margin", styles,
						 [margin_top, margin_right, margin_bottom, margin_left])
	
	# Text alignment
	if styles.has("text-align"):
		var target_align = styles["text-align"]
		for i in text_align.item_count:
			if text_align.get_item_text(i) == target_align:
				text_align.selected = i
				break
