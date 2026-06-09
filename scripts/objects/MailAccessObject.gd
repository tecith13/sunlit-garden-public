extends GenericInteractable
class_name MailAccessObject

@export var mailAccessId: String = "mailbox_home"
@export var isRepaired: bool = false
@export var hasUnreadMail: bool = false

@export var brokenFeedback: String = "The mailbox is old and stuck shut."
@export var emptyFeedback: String = "There is no mail right now."
@export var unreadFeedback: String = "There is a letter inside."

@export var drawDebugMailboxVisual: bool = true


func _ready() -> void:
	super._ready()
	add_to_group("mail_access_object")
	queue_redraw()
	
	if debugLog:
		print("MailAccessObject ready: ", mailAccessId)


func onInteract() -> void:
	if not isRepaired:
		onBrokenMailAccess()
		return
	
	if hasUnreadMail:
		onUnreadMailAccess()
	else:
		onEmptyMailAccess()


func onBrokenMailAccess() -> void:
	showFeedback(brokenFeedback)
	
	if debugLog:
		print("Broken mail access: ", mailAccessId)


func onEmptyMailAccess() -> void:
	showFeedback(emptyFeedback)
	
	if debugLog:
		print("Empty mail access: ", mailAccessId)


func onUnreadMailAccess() -> void:
	showFeedback(unreadFeedback)
	
	if debugLog:
		print("Unread mail access: ", mailAccessId)


func _draw() -> void:
	if drawDebugMailboxVisual:
		drawMailboxVisual()


func drawMailboxVisual() -> void:
	var postColor: Color = Color(0.34, 0.21, 0.12, 1.0)
	var postDark: Color = Color(0.16, 0.09, 0.05, 1.0)
	var metalColor: Color = Color(0.64, 0.58, 0.48, 1.0)
	var metalDark: Color = Color(0.27, 0.24, 0.20, 1.0)
	var highlight: Color = Color(0.88, 0.78, 0.58, 0.55)
	var flagColor: Color = Color(0.65, 0.22, 0.16, 1.0)
	
	if isRepaired:
		metalColor = Color(0.72, 0.67, 0.56, 1.0)
		flagColor = Color(0.82, 0.28, 0.18, 1.0)
	
	# Pivot 기준: 우편통 바닥/기둥 하단 근처.
	draw_rect(Rect2(Vector2(-5, -4), Vector2(10, 42)), postColor, true)
	draw_rect(Rect2(Vector2(-5, -4), Vector2(10, 42)), postDark, false, 1.2)
	draw_rect(Rect2(Vector2(-20, 34), Vector2(40, 7)), postDark, true)
	
	var bodyRect: Rect2 = Rect2(Vector2(-34, -46), Vector2(68, 34))
	draw_rect(bodyRect, metalColor, true)
	draw_rect(bodyRect, metalDark, false, 2.0)
	
	draw_arc(
		bodyRect.position + Vector2(bodyRect.size.x * 0.5, 2.0),
		bodyRect.size.x * 0.5,
		PI,
		TAU,
		24,
		metalDark,
		2.0
	)
	
	var doorRect: Rect2 = Rect2(bodyRect.position + Vector2(6, 7), Vector2(25, 20))
	draw_rect(doorRect, Color(0.52, 0.48, 0.40, 1.0), true)
	draw_rect(doorRect, metalDark, false, 1.0)
	
	draw_line(
		bodyRect.position + Vector2(38, 8),
		bodyRect.position + Vector2(60, 8),
		highlight,
		1.5
	)
	
	draw_rect(Rect2(bodyRect.position + Vector2(bodyRect.size.x - 10, -18), Vector2(5, 22)), metalDark, true)
	draw_rect(Rect2(bodyRect.position + Vector2(bodyRect.size.x - 8, -20), Vector2(24, 12)), flagColor, true)
	draw_rect(Rect2(bodyRect.position + Vector2(bodyRect.size.x - 8, -20), Vector2(24, 12)), metalDark, false, 1.0)
	
	if not isRepaired:
		draw_line(bodyRect.position + Vector2(10, 25), bodyRect.position + Vector2(24, 14), metalDark, 1.4)
		draw_line(bodyRect.position + Vector2(48, 27), bodyRect.position + Vector2(58, 18), metalDark, 1.2)


func getSaveData() -> Dictionary:
	return {
		"mailAccessId": mailAccessId,
		"isRepaired": isRepaired,
		"hasUnreadMail": hasUnreadMail
	}


func loadSaveData(data: Dictionary) -> void:
	if data.has("mailAccessId"):
		mailAccessId = str(data["mailAccessId"])
	
	if data.has("isRepaired"):
		isRepaired = bool(data["isRepaired"])
	
	if data.has("hasUnreadMail"):
		hasUnreadMail = bool(data["hasUnreadMail"])
	
	queue_redraw()
