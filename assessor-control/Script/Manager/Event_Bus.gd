extends Node

# ═══════════════════════════════════════════════════════════════
#  Event_Bus — 通用事件总线（Autoload 单例）
#
#  设计思路：
#    采用动态信号机制，不需要预先定义信号，而是在订阅/推送时
#    按需创建信号。通过统一的 "EventBus|<事件名>" 命名规则管理，
#    任何节点都可以通过该总线进行解耦通信。
#
#  使用方式：
#    1. 将该脚本添加为 Autoload（项目设置 → 自动加载 → 添加）
#       路径: res://Scripts/Event_Bus.gd
#       名称: Event_Bus
#    2. 推送事件（发送方）：
#       Event_Bus.push_event("事件名", 数据)
#    3. 订阅事件（接收方）：
#       Event_Bus.subscribe_event("事件名", 回调函数)
#    4. 取消订阅：
#       Event_Bus.cancel_event("事件名", 回调函数)
#
#  示例：
#    发送方：
#      Event_Bus.push_event("player_damaged", [50, self])
#    接收方：
#      Event_Bus.subscribe_event("player_damaged", _on_player_damaged)
#      func _on_player_damaged(amount: int, source: Node):
#          print("受到了 ", amount, " 点伤害")
#
#  注意事项：
#    - 如果 payload 不是数组，会自动包装成数组
#    - 如果 payload 是单个值，直接传即可；如果是多个值，用数组包裹
#    - 取消订阅时 callback 必须是与订阅时相同的可调用对象
# ═══════════════════════════════════════════════════════════════


# ───── 推送事件（发送方调用） ─────

## 推送一个事件到总线上，所有订阅了该事件的回调函数都会被触发
##
## @param destination: String  — 事件名称（如 "player_damaged"、"game_started"）
## @param payload:     Variant — 要传递的数据。
##                                如果是单个值，直接传入；
##                                如果是多个值，用数组包裹 [val1, val2, ...]。
##
## 示例：
##   Event_Bus.push_event("player_damaged", 50)              # 单个参数
##   Event_Bus.push_event("player_damaged", [50, self])      # 多个参数
##
func push_event(destination: String, payload) -> void:
	# 如果 payload 不是数组，将其包装为单元素数组
	# 这样后续 callv 可以统一处理
	if not payload is Array:
		payload = [payload]

	# 将信号名插入到 payload 数组的最前面
	# 最终 payload 结构: [信号名, 参数1, 参数2, ...]
	payload.insert(0, get_destination_signal(destination))

	# 调用 emit_signal，相当于 emit_signal("EventBus|<事件名>", 参数1, 参数2, ...)
	callv("emit_signal", payload)


# ───── 订阅事件（接收方调用） ─────

## 订阅指定事件，注册回调函数
##
## @param destination: String   — 事件名称（必须与 push_event 时一致）
## @param callback:    Callable — 事件触发时要执行的回调函数
##
## 回调函数的参数必须与 push_event 传递的参数匹配。
## 如果已经订阅过同一个事件 + 同一个回调，不会重复订阅。
##
## 示例：
##   Event_Bus.subscribe_event("player_damaged", _on_player_damaged)
##   Event_Bus.subscribe_event("game_started", _on_game_started)
##
func subscribe_event(destination: String, callback: Callable) -> void:
	var dest_signal: String = get_destination_signal(destination)

	# 检查是否尚未连接，避免重复连接导致回调被多次触发
	if not is_connected(dest_signal, callback):
		connect(dest_signal, callback)


# ───── 取消订阅（不再需要接收事件时调用） ─────

## 取消对指定事件的订阅
##
## @param destination: String   — 事件名称
## @param callback:    Callable — 之前订阅时传入的回调函数（必须完全一致）
##
## 通常用于节点被销毁前（如 _exit_tree 中）清理订阅，防止悬垂引用。
##
## 示例：
##   Event_Bus.cancel_event("player_damaged", _on_player_damaged)
##
func cancel_event(destination: String, callback: Callable) -> void:
	var des_signal: String = get_destination_signal(destination)

	# 仅当确实已连接时才断开，避免无谓的错误
	if is_connected(des_signal, callback):
		disconnect(des_signal, callback)


# ───── 获取 / 动态创建信号 ─────

## 根据事件名称获取对应的 Godot 信号名
## 如果该信号尚未注册，会自动创建
##
## 信号命名规则：EventBus|<事件名>
## 例如事件 "player_damaged" 对应信号 "EventBus|player_damaged"
##
## @param destination: String — 事件名称
## @return String — Godot 内部信号名
##
func get_destination_signal(destination: String) -> String:
	var dest_signal: String = "EventBus|%s" % destination

	# 如果该自定义信号尚未注册，动态创建一个
	if not has_user_signal(dest_signal):
		add_user_signal(dest_signal)

	return dest_signal
