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
	"邮箱": preload("res://Scene/operation_manual.tscn"),
	"禁止打开": preload("res://Scene/forbidden_access.tscn"),
}

# 底栏快捷按钮节点名 -> SCENE_MAP 键名映射
const BOTTOM_BAR_MAP = {
	"judge_program": "判断程序",
	"info_library": "信息库",
	"operation_manual": "邮箱",
	"forbidden_access": "禁止打开",
}

# 是否正在加载中（防止双击重复触发）
var _is_loading := false

# 当前已打开的页面（item_name -> Control 实例）
var _open_pages := {}

# 当前选中的桌面图标（单击高亮框）
var _selected_item: TextureRect = null

# 桌面图标选中高亮框（场景中已创建的 Panel 节点）
@onready var _selection_indicator: Panel = $Single_Click_Rect

# 底部导航栏的日期时间标签
@onready var _date_time_label: Label = $Bottom_navigation/DateTimeLabel

# --- 音量面板 ---
const PANEL_HEIGHT := 250.0
const START_PANEL_HEIGHT := 61.0
const BOTTOM_BAR_HEIGHT := 80.0

var _is_audio_panel_open := false

@onready var _audio_panel: Control = $AudioPanel
@onready var _master_slider: HSlider = $AudioPanel/Panel/MarginContainer/VBoxContainer/MasterRow/Slider
@onready var _bgm_slider: HSlider = $AudioPanel/Panel/MarginContainer/VBoxContainer/BgmRow/Slider
@onready var _sfx_slider: HSlider = $AudioPanel/Panel/MarginContainer/VBoxContainer/SfxRow/Slider

# --- 开始菜单面板 ---
var _is_start_panel_open := false

@onready var _start_panel: Control = $StartPanel

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

	# 确保选中框不拦截鼠标事件且默认隐藏
	_selection_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_indicator.hide()

	# 点击根节点空白区域时取消图标选中
	gui_input.connect(_on_root_gui_input)

	# 遍历 VBoxContainer 下的所有子节点，为每个图标绑定输入事件
	for child in $VBoxContainer.get_children():
		if child is TextureRect:
			# 让 Label 不拦截鼠标事件，透传到 TextureRect
			for grandchild in child.get_children():
				if grandchild is Label:
					grandchild.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# 连接输入事件（单击选中 + 双击打开）
			child.gui_input.connect(_on_item_gui_input.bind(child))

	# 连接音量开关按钮
	$Bottom_navigation/Audio.pressed.connect(_toggle_audio_panel)
	# 连接开始菜单按钮
	$Bottom_navigation/Start.pressed.connect(_toggle_start_panel)
	# 连接底栏快捷按钮（HBoxContainer 下的 Button）
	for button in $Bottom_navigation/HBoxContainer.get_children():
		if button is Button:
			button.pressed.connect(_on_bottom_bar_button_pressed.bind(button))
	# 连接关机按钮
	$StartPanel/Panel/ShutdownButton.pressed.connect(_on_shutdown_pressed)
	# 连接音量滑块
	_master_slider.value_changed.connect(_on_master_volume_changed)
	_bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	# 初始化滑块值为当前总线音量
	_master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	_bgm_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")))
	_sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))

# 更新底部导航栏右侧的日期时间显示（上段时间，下段日期）
func _update_date_time():
	var now := Time.get_datetime_dict_from_system()
	var time_str := "%02d:%02d:%02d" % [now.hour, now.minute, now.second]
	var date_str := "%04d-%02d-%02d" % [now.year, now.month, now.day]
	_date_time_label.text = "%s\n%s" % [time_str, date_str]


# 处理图标输入事件（单击选中 + 双击打开）
func _on_item_gui_input(event: InputEvent, item: TextureRect):
	if _is_loading:
		return
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		if event.double_click:
			_open_item_from_icon(item)
		else:
			_select_item(item)


# 双击图标：打开对应页面
func _open_item_from_icon(item: TextureRect):
	var item_name = _get_item_name(item)
	if item_name == "":
		return
	# 页面已存在（未关闭）
	if _open_pages.has(item_name):
		# 如果是最小化状态则恢复，否则不做任何事
		if not _open_pages[item_name].visible:
			_restore_page(item_name)
		return
	_is_loading = true
	await _start_loading(item_name)
	AudioManager.play_sfx(sfx_MouseClick)
	_is_loading = false


# 单击图标：显示选中高亮框（居中于图标）
func _select_item(item: TextureRect):
	if _selected_item == item:
		return
	_selected_item = item
	_selection_indicator.position = item.global_position + (item.size - Vector2(160, 140)) / 2.0
	_selection_indicator.size = Vector2(160, 170)
	_selection_indicator.show()


# 取消选中
func _deselect_item():
	_selected_item = null
	_selection_indicator.hide()


# 点击根节点空白区域时取消图标选中
func _on_root_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		_deselect_item()


# 兜底：点击任何未被其他控件处理的位置时取消选中（例如 VBoxContainer 缝隙）
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		_deselect_item()


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
	# 注册到已打开页面字典
	_open_pages[item_name] = instance
	# 页面关闭时自动清理追踪
	if instance.has_signal("closed"):
		instance.closed.connect(_on_page_closed.bind(item_name))
	# 页面最小化时隐藏
	if instance.has_signal("minimized"):
		instance.minimized.connect(_on_page_minimized.bind(item_name))
	add_child(instance)
	# 将新页面移至底部导航栏下方，确保底栏始终可交互
	move_child(instance, $Bottom_navigation.get_index())


## 页面关闭时从追踪字典中移除
func _on_page_closed(item_name: String):
	_open_pages.erase(item_name)


## 页面最小化时隐藏
func _on_page_minimized(item_name: String):
	var instance = _open_pages.get(item_name)
	if instance:
		instance.hide()


## 恢复已最小化的页面（直接显示，无加载动画）
func _restore_page(item_name: String):
	var instance = _open_pages.get(item_name)
	if instance:
		instance.show()
		# 将页面置于底栏下方
		move_child(instance, $Bottom_navigation.get_index())
		# 确保底栏始终在渲染最上层（最后一个子节点）
		move_child($Bottom_navigation, get_child_count() - 1)


# ========== 底栏快捷按钮 ==========

## 底栏图标点击时直接打开对应页面（无需双击和加载动画）
func _on_bottom_bar_button_pressed(button: Button):
	var item_name = BOTTOM_BAR_MAP.get(button.name)
	if item_name == null:
		return
	# 页面已存在（未关闭）
	if _open_pages.has(item_name):
		# 如果是最小化状态则恢复，否则不做任何事
		if not _open_pages[item_name].visible:
			_restore_page(item_name)
		return
	if _is_loading:
		return
	_is_loading = true
	await _start_loading(item_name)
	_is_loading = false


# ========== 音量面板 ==========

## 切换音量面板展开/收起（带滑入/滑出动画）
func _toggle_audio_panel():
	if _is_audio_panel_open:
		_close_audio_panel()
	else:
		_open_audio_panel()


func _open_audio_panel():
	_is_audio_panel_open = true
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(_audio_panel, "offset_top", -(PANEL_HEIGHT + BOTTOM_BAR_HEIGHT), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_audio_panel, "offset_bottom", -BOTTOM_BAR_HEIGHT, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _close_audio_panel():
	_is_audio_panel_open = false
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(_audio_panel, "offset_top", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_audio_panel, "offset_bottom", PANEL_HEIGHT, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)


func _on_master_volume_changed(value: float):
	print("master",value)
	AudioManager.set_volume(AudioManager.Bus.MASTER, value)

func _on_bgm_volume_changed(value: float):
	print("bgm",value)
	AudioManager.set_volume(AudioManager.Bus.BGM, value)

func _on_sfx_volume_changed(value: float):
	print("sfx",value)
	AudioManager.set_volume(AudioManager.Bus.SFX, value)


# ========== 开始菜单面板 ==========

func _toggle_start_panel():
	if _is_start_panel_open:
		_close_start_panel()
	else:
		_open_start_panel()


func _open_start_panel():
	_is_start_panel_open = true
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(_start_panel, "offset_top", -(START_PANEL_HEIGHT + BOTTOM_BAR_HEIGHT), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_start_panel, "offset_bottom", -BOTTOM_BAR_HEIGHT, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _close_start_panel():
	_is_start_panel_open = false
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(_start_panel, "offset_top", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_start_panel, "offset_bottom", START_PANEL_HEIGHT, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)


func _on_shutdown_pressed():
	get_tree().quit()
