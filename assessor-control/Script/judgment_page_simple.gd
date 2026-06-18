extends Control

# ============================================
# 审查/判断页面 - Godot 4.x 完整实现
# ============================================

@export var total_items: int = 6
@export var auto_jump: bool = true

# ---- 节点引用 ----
@onready var progress_container: HBoxContainer = $VBoxContainer/ProgressBarContainer
@onready var current_label: Label = $VBoxContainer/CurrentLabel
@onready var left_arrow: Button = $VBoxContainer/ButtonContainer/LeftArrow
@onready var right_arrow: Button = $VBoxContainer/ButtonContainer/RightArrow
@onready var content_image: TextureRect = $VBoxContainer/ContentContainer/MarginContainer/VBoxContainer/ContentImage
@onready var content_text: Label = $VBoxContainer/ContentContainer/MarginContainer/VBoxContainer/ContentText
@onready var submit_btn: Button = $VBoxContainer/ButtonContainer/SubmitButton
@onready var safe_btn: Button = $VBoxContainer/ButtonContainer/SafeButton
@onready var unsafe_btn: Button = $VBoxContainer/ButtonContainer/UnsafeButton

# ---- 状态 ----
var current_index: int = 1
var judgments: Dictionary = {}  # {1: "safe", 2: "unsafe", ...}
var progress_bars: Array[Panel] = []

# ---- 颜色 ----
const C_GRAY    = Color("#c8c8c8")   # 未判断
const C_GREEN   = Color("#8bc34a")   # 安全
const C_RED     = Color("#f44336")   # 异常
const C_CURRENT = Color("#689f38")   # 当前（深绿）

# ---- 示例数据 ----
var item_data: Array[Dictionary] = [
	{"text": "春岚  有没有玩影之诗的 想搞个公会", "img": "res://assets/item1.png"},
	{"text": "用户B  这是一条测试内容", "img": "res://assets/item2.png"},
	{"text": "用户C  另一条待判断信息", "img": "res://assets/item3.png"},
	{"text": "用户D  第四条信息内容", "img": ""},
	{"text": "用户E  第五条信息内容", "img": ""},
	{"text": "用户F  第六条信息内容", "img": ""},
]

func _ready():
	_setup_progress_bars()
	_connect_signals()
	_update_all()

# ========== 初始化进度条格子 ==========
func _setup_progress_bars():
	for child in progress_container.get_children():
		child.queue_free()
	progress_bars.clear()

	for i in range(total_items):
		var bar = Panel.new()
		bar.name = "Bar" + str(i + 1)
		bar.custom_minimum_size = Vector2(70, 32)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var style = StyleBoxFlat.new()
		style.bg_color = C_GRAY
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		bar.add_theme_stylebox_override("panel", style)

		progress_container.add_child(bar)
		progress_bars.append(bar)

func _connect_signals():
	left_arrow.pressed.connect(_on_left)
	right_arrow.pressed.connect(_on_right)
	safe_btn.pressed.connect(_on_safe)
	unsafe_btn.pressed.connect(_on_unsafe)
	submit_btn.pressed.connect(_on_submit)

# ========== 更新显示 ==========
func _update_all():
	_update_bars()
	_update_label()
	_update_content()
	_update_buttons()

func _update_bars():
	for i in range(total_items):
		var bar = progress_bars[i]
		var style = bar.get_theme_stylebox("panel").duplicate()

		if i + 1 == current_index:
			# 当前对象：深绿色 + 放大
			style.bg_color = C_CURRENT
			_tween_scale(bar, Vector2(1.3, 1.3))
			bar.z_index = 10
		elif judgments.has(i + 1):
			# 已判断
			style.bg_color = C_GREEN if judgments[i + 1] == "safe" else C_RED
			_tween_scale(bar, Vector2(1.0, 1.0))
			bar.z_index = 0
		else:
			# 未判断
			style.bg_color = C_GRAY
			_tween_scale(bar, Vector2(1.0, 1.0))
			bar.z_index = 0

		bar.add_theme_stylebox_override("panel", style)

func _tween_scale(node: Node, target: Vector2, duration: float = 0.25):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", target, duration)

func _update_label():
	current_label.text = "当前为第" + _to_chinese(current_index) + "条信息"

func _update_content():
	if current_index <= item_data.size():
		var data = item_data[current_index - 1]
		content_text.text = data.get("text", "")
		var path = data.get("img", "")
		content_image.texture = load(path) if ResourceLoader.exists(path) else null

func _update_buttons():
	left_arrow.disabled = current_index <= 1
	right_arrow.disabled = current_index >= total_items

	var has_judged = judgments.has(current_index)
	safe_btn.text = "重新判断为安全" if has_judged else "安全"
	unsafe_btn.text = "重新判断为异常" if has_judged else "异常"

# ========== 按钮回调 ==========
func _on_left():
	if current_index > 1:
		current_index -= 1
		_update_all()

func _on_right():
	if current_index < total_items:
		current_index += 1
		_update_all()

func _on_safe():
	_judge("safe")

func _on_unsafe():
	_judge("unsafe")

func _judge(result: String):
	# 记录/覆盖判断结果
	judgments[current_index] = result

	# 闪烁动画
	var bar = progress_bars[current_index - 1]
	var target_color = C_GREEN if result == "safe" else C_RED
	var tween = create_tween()
	tween.tween_property(bar, "modulate", Color(2, 2, 2), 0.1)
	tween.tween_property(bar, "modulate", target_color, 0.2)

	# 自动跳转
	if auto_jump:
		await get_tree().create_timer(0.3).timeout
		var next = _find_next_unjudged()
		if next == -1:
			next = current_index + 1
		if next <= total_items:
			current_index = next
			_update_all()
		else:
			_update_all()
			print("全部判断完毕！")
	else:
		_update_all()

func _find_next_unjudged() -> int:
	for i in range(current_index + 1, total_items + 1):
		if not judgments.has(i):
			return i
	return -1

func _on_submit():
	if judgments.size() < total_items:
		var missing = []
		for i in range(1, total_items + 1):
			if not judgments.has(i):
				missing.append(i)
		print("未判断: ", missing)
	else:
		print("提交: ", judgments)

# ========== 工具函数 ==========
func _to_chinese(n: int) -> String:
	var c = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
	if n <= 10: return c[n]
	if n < 20: return "十" + (c[n - 10] if n != 10 else "")
	var t = n / 10
	var o = n % 10
	var r = c[t] + "十"
	if o > 0: r += c[o]
	return r
