extends Control
#加载BGM
@export var bgm_1:AudioStream
#加载音效
@export var sfx_MouseClick:AudioStream
# 加载中光标场景（旋转动画图标）
const LOADING_CURSOR = preload("res://Scene/loading_cursor.tscn")

# 子节点名称 -> 对应独立场景的映射表
const SCENE_MAP = {
	"判断程序": preload("res://Scene/judge_program.tscn"),
	"信息库": preload("res://Scene/info_library.tscn"),
	"操作手册": preload("res://Scene/operation_manual.tscn"),
	"禁止打开": preload("res://Scene/forbidden_access.tscn"),
}

# 是否正在加载中（防止双击重复触发）
var _is_loading := false

# 底部导航栏的日期时间标签
@onready var _date_time_label: Label = $Bottom_navigation/DateTimeLabel

func _ready():
	#播放背景音乐
	AudioManager.play_music(bgm_1)
	# 初始化日期时间显示，并启动每秒刷新
	_update_date_time()
	var timer := Timer.new()
	timer.timeout.connect(_update_date_time)
	timer.wait_time = 1.0
	timer.autostart = true
	add_child(timer)

	# 遍历 VBoxContainer 下的所有子节点，为每个图标绑定双击事件
	for child in $VBoxContainer.get_children():
		if child is TextureRect:
			# 让 Label 不拦截鼠标事件，透传到 TextureRect
			for grandchild in child.get_children():
				if grandchild is Label:
					grandchild.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# 连接双击输入事件
			child.gui_input.connect(_on_item_double_click.bind(child))


# 更新底部导航栏右侧的日期时间显示（上段时间，下段日期）
func _update_date_time():
	var now := Time.get_datetime_dict_from_system()
	var time_str := "%02d:%02d:%02d" % [now.hour, now.minute, now.second]
	var date_str := "%04d-%02d-%02d" % [now.year, now.month, now.day]
	_date_time_label.text = "%s\n%s" % [time_str, date_str]


# 处理双击事件
func _on_item_double_click(event: InputEvent, item: TextureRect):
	if _is_loading:
		return
	if event is InputEventMouseButton and event.pressed and event.double_click:
		AudioManager.play_sfx(sfx_MouseClick)
		_is_loading = true
		var item_name = _get_item_name(item)
		if item_name == "":
			_is_loading = false
			return
		await _start_loading(item_name)
		_is_loading = false


# 从 TextureRect 的子节点中获取 Label 的文本作为项目名称
func _get_item_name(item: TextureRect) -> String:
	for child in item.get_children():
		if child is Label:
			return child.text
	return ""


# 执行加载动画，然后打开对应的 UI 界面
func _start_loading(item_name: String):
	# 显示旋转加载图标，隐藏系统鼠标
	var loading = LOADING_CURSOR.instantiate()
	add_child(loading)

	# 模拟老电脑加载延迟（1.5 秒）
	await get_tree().create_timer(1.5).timeout

	# 恢复鼠标并移除加载图标
	loading.stop_and_restore_cursor()

	# 打开对应的 UI
	_open_item_scene(item_name)


# 根据项目名称实例化并打开对应的子场景
func _open_item_scene(item_name: String):
	var scene = SCENE_MAP.get(item_name)
	if scene == null:
		return

	var instance = scene.instantiate()
	add_child(instance)
