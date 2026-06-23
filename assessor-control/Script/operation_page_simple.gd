extends Control

# ============================================
# 审查/判断页面 - Godot 4.x 完整实现
# ============================================

@export var total_items: int = 6
@export var auto_jump: bool = true

# ---- 节点引用：左边邮箱列表按钮 ----
@onready var email_1: Button = $ItemList/Email1
@onready var email_2: Button = $ItemList/Email2
@onready var email_3: Button = $ItemList/Email3
@onready var email_4: Button = $ItemList/Email4
@onready var email_5: Button = $ItemList/Email5
@onready var email_6: Button = $ItemList/Email6

# 用数组管理，方便循环处理
var email_buttons: Array[Button] = []

# ---- 节点引用：右边内容区 ----
@onready var progress_container: HBoxContainer = $VBoxContainer/ProgressBarContainer
@onready var current_label: Label = $VBoxContainer/CurrentLabel
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
	{"text": "第一条信息", "img": "res://assets/item1.png"},
	{"text": "用户B  这是一条测试内容", "img": "res://assets/item2.png"},
	{"text": "用户C  另一条待判断信息", "img": "res://assets/item3.png"},
	{"text": "用户D  第四条信息内容", "img": ""},
	{"text": "用户E  第五条信息内容", "img": ""},
	{"text": "用户F  第六条信息内容", "img": ""},
]

func _ready():
	# 初始化按钮数组
	email_buttons = [email_1, email_2, email_3, email_4, email_5, email_6]
	
	_connect_signals()
	_update_all()


func _connect_signals():
	# 连接6个邮箱按钮
	for i in range(email_buttons.size()):
		email_buttons[i].pressed.connect(_on_email_pressed.bind(i + 1))
	

# ========== 更新显示 ==========
func _update_all():
	_update_content()
	_update_email_buttons()  # 刷新按钮状态


func _update_content():
	if current_index <= item_data.size():
		var data = item_data[current_index - 1]
		content_text.text = data.get("text", "")
		var path = data.get("img", "")
		content_image.texture = load(path) if ResourceLoader.exists(path) else null

# 刷新邮箱按钮的显示状态
func _update_email_buttons():
	for i in range(email_buttons.size()):
		var btn = email_buttons[i]
		var index = i + 1
		
		# 基础文本
		var btn_text = "第" + _to_chinese(index) + "条"
		
		# 已判断的标记
		if judgments.has(index):
			var status = "安全" if judgments[index] == "safe" else "异常"
			btn_text += " [" + status + "]"
			btn.modulate = C_GREEN if judgments[index] == "safe" else C_RED
		else:
			btn.modulate = C_GRAY  # 未判断灰色
		
		# 当前选中高亮
		if index == current_index:
			btn.modulate = C_CURRENT
			btn_text += " ←"  # 标记当前项
		
		btn.text = btn_text


# ========== 邮箱按钮回调 ==========
func _on_email_pressed(index: int):
	current_index = index
	_update_all()


# ========== 判断按钮回调 ==========
func _on_safe():
	_judge("safe")

func _on_unsafe():
	_judge("unsafe")

func _judge(result: String):
	# 记录/覆盖判断结果
	judgments[current_index] = result

	# 进度条闪烁动画（如果有）
	if progress_bars.size() >= current_index:
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
