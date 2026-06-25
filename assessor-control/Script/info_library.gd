extends Control

signal closed
signal minimized

# 搜索关键词 → 文本内容映射表（可自由增删）
var _text_db := {
	"凝聚意志":
"""凝聚意志，保卫人类

这是全体人类的共同使命。在这个充满挑战的时代，我们必须团结一致，以坚定的意志捍卫我们的文明与未来。

历史告诉我们，唯有团结才能战胜挑战。无论面对何种困难，只要我们凝聚意志，就没有克服不了的障碍。

——摘自《人类宣言》""",

	"保卫人类":
"""保卫人类

人类文明历经数千年的发展，积累了丰富的知识与智慧。在面对未知挑战时，我们应当秉持理性与勇气，运用科技与智慧守护我们的家园。

每一个个体都是人类文明的重要组成部分，保卫人类就是保卫我们共同的未来。

核心原则：
• 尊重生命，保护每一个人的尊严
• 传承文明，守护知识与智慧
• 面向未来，勇于探索与创新""",

	"操作指南":
"""操作指南

欢迎使用信息库系统。您可以通过以下方式进行操作：

1. 在搜索框中输入关键词
2. 按下回车键确认搜索
3. 系统将显示匹配的文本内容
4. 点击左上角「< 返回」按钮返回搜索

可用关键词：
• 凝聚意志
• 保卫人类
• 操作指南
• 信息库
• 关于本系统""",

	"信息库":
"""信息库

信息库是一个集知识检索、文档查阅于一体的综合信息平台。这里收录了各类重要文献、技术文档和参考资料。

功能特点：
• 关键词搜索：快速定位所需信息
• 全文阅读：支持长文档浏览与滚动
• 安全可靠：数据经过严格审核""",

	"关于本系统":
"""关于本系统

Assessor-Control 信息管理系统

版本：1.0.0

本系统致力于为用户提供安全、高效的信息检索与管理服务。系统采用模块化设计，支持灵活扩展。

技术栈：Godot Engine 4
字体：NanoDyongSong
界面设计：经典 Windows 风格""",
}

@onready var _line_edit: LineEdit = $Panel/SearchHBox/LineEdit
@onready var _search_hbox: Panel = $Panel/SearchHBox
@onready var _content_scroll: ScrollContainer = $Panel/ContentScroll
@onready var _content_label: RichTextLabel = $Panel/ContentScroll/Content
@onready var _back_btn: Button = $Panel/Top_Line/BackButton


func _ready():
	$Panel/Top_Line/Quit_Button.pressed.connect(_on_close)
	$Panel/Top_Line/minimization_Button.pressed.connect(_on_minimized)
	_line_edit.text_submitted.connect(_on_search_submitted)
	_back_btn.pressed.connect(_on_back_pressed)

	# 初始状态：显示搜索框，隐藏内容和返回按钮
	_content_scroll.hide()
	_back_btn.hide()


## 按下回车时触发搜索
func _on_search_submitted(text: String):
	var trimmed := text.strip_edges()
	if trimmed == "":
		return

	if _text_db.has(trimmed):
		_content_label.text = _text_db[trimmed]
	else:
		_content_label.text = "[center]未找到与「%s」相关的内容。[/center]" % trimmed

	_search_hbox.hide()
	_content_scroll.show()
	_back_btn.show()


## 点击返回按钮，回到搜索界面
func _on_back_pressed():
	_search_hbox.show()
	_content_scroll.hide()
	_back_btn.hide()
	_line_edit.clear()
	_line_edit.grab_focus()


func _on_minimized():
	minimized.emit()


func _on_close():
	closed.emit()
	queue_free()
