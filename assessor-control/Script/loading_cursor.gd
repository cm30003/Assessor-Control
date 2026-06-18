extends Control

@onready var _loading_icon: TextureRect = $LoadingIcon
var _tween: Tween


func _ready():
	# 隐藏系统鼠标，使用自定义加载图标
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# 启动旋转动画（绕中心旋转）
	_tween = create_tween().set_loops()
	_tween.tween_property(_loading_icon, "rotation", _loading_icon.rotation + TAU, 1.0).as_relative()


func _process(_delta):
	# 图标跟随鼠标位置，中心对齐
	var mouse_pos = get_global_mouse_position()
	global_position = mouse_pos - size / 2


func stop_and_restore_cursor():
	if _tween and _tween.is_valid():
		_tween.kill()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	queue_free()
