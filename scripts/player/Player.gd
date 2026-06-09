extends CharacterBody2D

@export var moveSpeed: float = 100.0
@export var clearHitTime: float = 0.14
@export var clearEndTime: float = 0.34
@export var hoeHitTime: float = 0.14
@export var hoeEndTime: float = 0.34

@onready var oldAnimatedSprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var bodySprite: AnimatedSprite2D = $CharacterVisual/BodyAnimatedSprite2D
@onready var outfitSprite: AnimatedSprite2D = $CharacterVisual/OutfitAnimatedSprite2D
@onready var shoesSprite: AnimatedSprite2D = $CharacterVisual/ShoesAnimatedSprite2D
@onready var hairSprite: AnimatedSprite2D = $CharacterVisual/HairAnimatedSprite2D
@onready var faceSprite: AnimatedSprite2D = $CharacterVisual/FaceAnimatedSprite2D

var lastDirection: String = "down"
var isActionLocked: bool = false
var pendingClearTarget: Node = null
var pendingHoeCallable: Callable
var hasPendingHoeCallable: bool = false


func _ready() -> void:
	if oldAnimatedSprite != null:
		oldAnimatedSprite.visible = false


func _physics_process(delta: float) -> void:
	if isActionLocked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var inputVector := Vector2.ZERO

	inputVector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	inputVector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	if inputVector.length() > 0:
		inputVector = inputVector.normalized()
		velocity = inputVector * moveSpeed
		playWalkAnimation(inputVector)
	else:
		velocity = Vector2.ZERO
		playIdleAnimation()

	move_and_slide()


func getCharacterSprites() -> Array[AnimatedSprite2D]:
	return [
		bodySprite,
		outfitSprite,
		shoesSprite,
		hairSprite,
		faceSprite
	]


func playAnimationOnAll(animationName: String) -> void:
	for sprite in getCharacterSprites():
		if sprite == null:
			continue

		if sprite.sprite_frames == null:
			continue

		if sprite.sprite_frames.has_animation(animationName) == false:
			continue

		if sprite.animation != animationName or sprite.is_playing() == false:
			sprite.play(animationName)


func stopAnimationOnAllAtFirstFrame(animationName: String) -> void:
	for sprite in getCharacterSprites():
		if sprite == null:
			continue

		if sprite.sprite_frames == null:
			continue

		if sprite.sprite_frames.has_animation(animationName) == false:
			continue

		if sprite.animation != animationName:
			sprite.play(animationName)

		sprite.stop()
		sprite.frame = 0


func playWalkAnimation(inputVector: Vector2) -> void:
	# 현재는 down 방향만 적용한 상태
	lastDirection = "down"
	playAnimationOnAll("walk_down")


func playIdleAnimation() -> void:
	stopAnimationOnAllAtFirstFrame("idle_down")


func playClearAnimation() -> void:
	lastDirection = "down"
	playAnimationOnAll("clear_down")


func playHoeAnimation() -> void:
	lastDirection = "down"
	playAnimationOnAll("hoe_down")


func startClearAction(target: Node) -> void:
	if isActionLocked:
		return

	if target == null:
		return

	isActionLocked = true
	pendingClearTarget = target
	velocity = Vector2.ZERO

	playClearAnimation()

	await get_tree().create_timer(clearHitTime).timeout

	if pendingClearTarget != null and is_instance_valid(pendingClearTarget):
		if pendingClearTarget.has_method("clearDeadGrass"):
			pendingClearTarget.clearDeadGrass()
		elif pendingClearTarget.has_method("clear"):
			pendingClearTarget.clear()

	await get_tree().create_timer(max(clearEndTime - clearHitTime, 0.01)).timeout

	pendingClearTarget = null
	isActionLocked = false
	playIdleAnimation()


func startHoeAction(actionCallable: Callable) -> bool:
	if isActionLocked:
		return false

	if actionCallable.is_valid() == false:
		return false

	isActionLocked = true
	pendingHoeCallable = actionCallable
	hasPendingHoeCallable = true
	velocity = Vector2.ZERO

	playHoeAnimation()
	runHoeActionAsync()

	return true


func runHoeActionAsync() -> void:
	await get_tree().create_timer(hoeHitTime).timeout

	if hasPendingHoeCallable and pendingHoeCallable.is_valid():
		pendingHoeCallable.call()

	await get_tree().create_timer(max(hoeEndTime - hoeHitTime, 0.01)).timeout

	hasPendingHoeCallable = false
	pendingHoeCallable = Callable()
	isActionLocked = false
	playIdleAnimation()
