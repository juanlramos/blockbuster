extends CharacterBody2D

@export var PlayerSprite: AnimatedSprite2D
@export var PlayerCollider: CollisionShape2D

#const SPEED = 30.0
#const JUMP_VELOCITY = -300.0
#movimentação
@export var maxSpeed: float = 150.0
@export var timeToReachMaxSpeed: float = 0.2
@export var timeToReachZeroSpeed: float = 0.2

#pulo
@export var jumpHeight: float = 1

#pulo duplo talvez
@export var jumps: int = 1

#força em que o jogador vai ser puxado para baixo
@export var gravityScale: float = 20.0
@export var terminalVelocity: float = 500.0
@export var descendingGravityFactor: float = 1.3

#Corte de força do pulo
@export var shortHop: bool = true
@export var jumpVariable: float = 2

#coyote e buffering
@export var coyoteTime: float = 0.05
@export var jumpBuffering: float = 0.1

#Corner cutting
@export var correctionAmount: float = 1.5
@export var leftRaycast: RayCast2D
@export var middleRaycast: RayCast2D
@export var rightRaycast: RayCast2D

#crouch?

#variaveis
var appliedGravity: float
var maxSpeedLock: float
var appliedTerminalVelocity: float

var friction: float
var acceleration: float
var deceleration: float
var instantAccel: bool = false
var instantStop: bool = false

var jumpMagnitude: float = 100.0
var jumpCount: int
var jumpWasPressed: bool = false
var coyoteActive: bool = false
var dashMagnitude: float
var gravityActive: bool = true

var wasMovingR: bool
var wasPressingR: bool
var movementInputMonitoring: Vector2 = Vector2(true, true) #movementInputMonitoring.x addresses right direction while .y addresses left direction

var gdelta: float = 1
var dset = false

var colliderScaleLockY
var colliderPosLockY

#anim tem praticamente a mesma função anterior
var anim
var col
var animScaleLock : Vector2

#Input Variables for the whole script
var leftHold
var leftTap
var leftRelease
var rightHold
var rightTap
var rightRelease
var jumpTap
var jumpRelease

func _ready():
	wasMovingR = true
	anim = PlayerSprite
	col = PlayerCollider
	
	_updateData()


func _updateData():
	acceleration = maxSpeed / timeToReachMaxSpeed
	deceleration = -maxSpeed / timeToReachZeroSpeed

	jumpMagnitude = 400.0 * jumpHeight 
	jumpCount = jumps
	
	maxSpeedLock = maxSpeed
	animScaleLock = abs(anim.scale)
	colliderScaleLockY = col.scale.y
	colliderPosLockY = col.position.y
	
	maxSpeedLock = maxSpeed
	
	animScaleLock = abs(anim.scale)
	colliderScaleLockY = col.scale.y
	colliderPosLockY = col.position.y
	
	if timeToReachMaxSpeed == 0:
		instantAccel = true
		timeToReachMaxSpeed = 1
	elif timeToReachMaxSpeed < 0:
		timeToReachMaxSpeed = abs(timeToReachMaxSpeed)
		instantAccel = false
	else:
		instantAccel = false
		
	if timeToReachZeroSpeed == 0:
		instantStop = true
		timeToReachZeroSpeed = 1
	elif timeToReachMaxSpeed < 0:
		timeToReachMaxSpeed = abs(timeToReachMaxSpeed)
		instantStop = false
	else:
		instantStop = false
	
	coyoteTime = abs(coyoteTime)
	jumpBuffering = abs(jumpBuffering)
	
func _process(_delta):
	#directions
	if rightHold:
		anim.scale.x = animScaleLock.x
	if leftHold:
		anim.scale.x = animScaleLock.x * -1
	
	#walk
	if abs(velocity.x) > 0.1 and is_on_floor():
		anim.speed_scale = abs(velocity.x / 150)
		anim.play("run")
	elif abs(velocity.x) < 0.1 and is_on_floor():
		anim.speed_scale = 1
		anim.play("idle")
		
	#jump
	if velocity.y < 0:
		anim.speed_scale = 1
		anim.play("jump")
		
	#if velocity.y > 40:
	#	anim.speed_scale = 1
	#	anim.play("falling")

func _physics_process(delta):
	if !dset:
		gdelta = delta
		dset = true

		
	leftHold = Input.is_action_pressed("ui_left")
	rightHold = Input.is_action_pressed("ui_right")
	leftTap = Input.is_action_just_pressed("ui_left")
	rightTap = Input.is_action_just_pressed("ui_right")
	leftRelease = Input.is_action_just_released("ui_left")
	rightRelease = Input.is_action_just_released("ui_right")
	jumpTap = Input.is_action_just_pressed("ui_accept")
	jumpRelease = Input.is_action_just_released("ui_accept")
	
	#movimento direita e esquerda
	if rightHold and leftHold and movementInputMonitoring:
		if !instantStop:
			_decelerate(delta, false)
		else:
			velocity.x = -0.1
	elif rightHold and movementInputMonitoring.x:
		if velocity.x > maxSpeed or instantAccel:
			velocity.x = maxSpeed
		else:
			velocity.x += acceleration * delta
		if velocity.x < 0:
			if !instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = -0.1
	elif leftHold and movementInputMonitoring.y:
		if velocity.x < -maxSpeed or instantAccel:
			velocity.x = -maxSpeed
		else:
			velocity.x -= acceleration * delta
		if velocity.x > 0:
			if !instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = 0.1
	
	if velocity.x > 0:
		wasMovingR = true
	elif velocity.x < 0:
		wasMovingR = false
		
	if rightTap:
		wasPressingR = true
	if leftTap:
		wasPressingR = false
	
	
	maxSpeed = maxSpeedLock
	col.scale.y = colliderScaleLockY
	col.position.y = colliderPosLockY
	
	if !(leftHold or rightHold):
		if !instantStop:
			_decelerate(delta, false)
		else:
			velocity.x = 0

	#pulo
	if velocity.y > 0:
		appliedGravity = gravityScale * descendingGravityFactor * 60
	else:
		appliedGravity = gravityScale * 60
	
	# Aplica a gravidade se o corpo não estiver no chão (ou sempre que gravityActive for true)
	if gravityActive:
		if not is_on_floor():
			velocity.y += appliedGravity * delta
		else:
			# Se estiver no chão, zera a descida para colar o player no chão
			velocity.y = 0.0

		# Limita a velocidade terminal de queda
		if velocity.y > terminalVelocity:
			velocity.y = terminalVelocity

	if shortHop and jumpRelease and velocity.y < 0:
		velocity.y = velocity.y / jumpVariable
	
	if !is_on_floor() and coyoteTime > 0:
		coyoteActive = true
		_coyoteTime()
	if jumpTap:
		if coyoteActive:
			coyoteActive = false
			_jump()
		if jumpBuffering > 0:
			jumpWasPressed = true
			_bufferJump()
		elif jumpBuffering == 0 and coyoteTime == 0 and is_on_floor():
			_jump()
	elif jumpTap and is_on_floor():
		_jump()
		
	if is_on_floor():
		jumpCount = jumps
		if coyoteTime > 0:
			coyoteActive = true
		else:
			coyoteActive = false
		if jumpWasPressed:
			_jump()
	
	#corner cutting
	if velocity.y < 0 and leftRaycast.is_colliding() and !rightRaycast.is_colliding() and !middleRaycast.is_colliding():
		position.x += correctionAmount
	if velocity.y < 0 and !leftRaycast.is_colliding() and rightRaycast.is_colliding() and !middleRaycast.is_colliding():
		position.x -= correctionAmount
	
	move_and_slide()
	
func _bufferJump():
	await get_tree().create_timer(jumpBuffering).timeout
	jumpWasPressed = false
	
func _coyoteTime():
	await get_tree().create_timer(coyoteTime).timeout
	coyoteActive = false
	
func _jump():
	if jumpCount > 0:
		velocity.y = -jumpMagnitude
		jumpCount += -1
		jumpWasPressed = false
	
func _inputPauseReset(time):
	await get_tree().create_timer(time).timeout
	movementInputMonitoring = Vector2(true, true)
	
func _decelerate(delta, vertical):
	if !vertical:
		if (abs(velocity.x) > 0) and (abs(velocity.x) <= abs(deceleration * delta)):
			velocity.x = 0 
		elif velocity.x > 0:
			velocity.x += deceleration * delta
		elif velocity.x < 0:
			velocity.x -= deceleration * delta
	elif vertical and velocity.y > 0:
		velocity.y += deceleration * delta
	
func _pauseGravity(time):
	gravityActive = false
	await get_tree().create_timer(time).timeout
	gravityActive = true
	
func _placeHolder():
	print("")
