extends Control

signal closed


func _ready():
	$Panel/CloseButton.pressed.connect(_on_close)


func _on_close():
	closed.emit()
	queue_free()
