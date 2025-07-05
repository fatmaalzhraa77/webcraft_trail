extends Panel
@onready var tx_edit = $TextEdit
@onready var ok_button = $Button
signal text_submitted(text: String)
var parent:String=""
# Store reference to the button this panel belongs to
var owner_button: TextureButton = null

func _ready():
	hide()
	ok_button.connect("pressed", Callable(self, "_on_ok_pressed"))

# Called from the draggable button to set up the connection
func _on_ok_pressed():
	var text = tx_edit.text
	emit_signal("text_submitted",parent,text)
	hide()
