extends Control

signal closed
signal minimized

# 搜索关键词 → 文本内容映射表（可自由增删）
@export var text_db := {
	"ROME0222 哈基米": {
		"text": 
			"""
	标签：模因 实体 待研究 危险等级：[color=#00ff00]2[/color]
	
	收容措施：一台寄生着ROME0222的终端机被存于档案处理中心的一间房间中，需要定期对该终端机的硬件进行维护。任何对该实体的研究需要对主管级别的研究员进行申请，需要有另一名研究员在实验后对研究人员进行小规模记忆清楚。一名安保人员被安排在办公室外，检查并销毁任何可能将该实体拷贝带出房间的行为。
	目前真理部正在加紧对无害化该实体的副本的制作。
	
	描述：ROME0222是一种寄生于终端的生物，其保存形式为动态图片或图片。将该实体文件打开后，为一猫类似生物的动态图片或图片，其被怀疑为该实体的本体。当该图片被观测到时，观测者有9.99%的几率将发生以下行为：1.产生猫叫或一些叫声的幻听。2.产生安慰、放松、高兴等情感。3.手动创建该生物副本。4.对该实体产生保护欲，与不喜欢该实体的人激烈争吵。5.否认自己的行为与该实体有关。
	因为可能产生的暴力行为，该实体的危险等级被评估为2级。目前暂不清楚存在多少ROME0222，大量的副本被传播，受其影响的人数可能非常大。信息部进一步检测发现，受该实体影响的部分群体在互联网上创建了名为【数据已丢失】的宗教团体，崇拜一个名为“耄耋”的神明，并且其希望占领地球。目前并不清楚“耄耋”是否存在，该宗教团体正在被多机构联合打击。
	
	图片：一张被无害化处理过的ROME0222的副本
""",
		"image": 
			"res://2D/Info_lib_Image/Good_Cat.png"
	},

	"阿波罗计划":
"""
	真理部提示：此项档案为稳定局内部作战计划，并非异常现象。
	阿波罗计划与国家航空航天局局的登月计划名称相同，是公共稳定局在登月计划开始之后开展的一系列后援任务。最初航空航天局获得的信息显示月球存在人造机器人与建筑，为了掩盖此发现这一计划被紧急启用，但是很快被认定为虚假信息与误判，经证实是部分员工错误的把漫画书中的图片当成了回传影像。
	为减少敌对国家对可能的航天计划与外太空武器研究的警惕与破坏，同时降低民众对相关成本与花费的无意义过度关注。稳定局真理部启动了该计划，以制造宣称并传播阿波罗登月计划为骗局的方式，真理部通过伪造的登月舱和驾驶员，在好莱坞建立了一座伪造的摄影棚，并且拍摄了登月成功的影片，其被用于替换了真实的登月影片。真理部同时制造了大量登月为虚假的信息，通过报纸、电视等各种手段传播。
	但这一手段对敌对国家并不理想，他们已经通过各种手段确认登月的真实性。在2003年后，目标被调整为训练平评估公众对信息的筛选与甄别能力。相信相关话语的用户被判断为“高价值”目标，将持续向其投放类似虚假信息以训练模型。
	使用过的手段包括但不限于：
	聘请作者创作登月阴谋论的书籍。
	拍摄关于登月阴谋论的纪录片。
	将伪造的虚假信息传播进互联网。
	将伪造的虚假信息是虚假信息的信息传播进互联网。
	该计划已被行政部认定为过时，其主要目标已经失败，但是否停止该计划仍在讨论中。

	注1：审计部发现个别部门向“高价值”目标贩卖保健品、净水器、量子美容仪等物品。与“高价值”目标私下通信为违规行为。任何部门禁止以此为资金来源。
	注2：多次重申！一经发现违规行为将以“盗窃稳定局财产”处理。
""",

	"操作指南":
"""
操作指南

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
@onready var _content_label: RichTextLabel = $Panel/ContentScroll/ContentVBox/Content
@onready var _content_image: TextureRect = $Panel/ContentScroll/ContentVBox/ContentImage
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

	if text_db.has(trimmed):
		var entry = text_db[trimmed]
		# 支持两种格式：纯文本字符串 或 {text: ..., image: ...} 字典
		if entry is Dictionary:
			_content_label.text = entry.get("text", "")
			var img_path = entry.get("image", "")
			if img_path != "":
				var tex = load(img_path)
				if tex:
					_content_image.texture = tex
					_content_image.show()
				else:
					_content_image.hide()
			else:
				_content_image.hide()
		else:
			_content_label.text = entry
			_content_image.hide()
	else:
		_content_label.text = "[center]未找到与「%s」相关的内容。[/center]" % trimmed
		_content_image.hide()

	_search_hbox.hide()
	_content_scroll.show()
	_back_btn.show()


## 点击返回按钮，回到搜索界面
func _on_back_pressed():
	_search_hbox.show()
	_content_scroll.hide()
	_back_btn.hide()
	_content_image.hide()
	_line_edit.clear()
	_line_edit.grab_focus()


func _on_minimized():
	minimized.emit()


func _on_close():
	closed.emit()
	queue_free()
