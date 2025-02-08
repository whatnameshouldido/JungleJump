extends CharacterBody2D

signal life_changed(value)
signal died

@export var gravity = 750
@export var run_speed = 150
@export var jump_speed = -300
@export var max_jumps = 2
@export var double_jump_factor = 1.5

enum {IDLE, RUN, JUMP, HURT, DEAD}
var state = IDLE
var life = 3: set = set_life
var is_god: bool = false
var jump_count = 0

func _ready():
	change_state(IDLE)

func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			$AnimationPlayer.play("idle")
		RUN:
			$AnimationPlayer.play("run")
		HURT:
			$AnimationPlayer.play("hurt")
			velocity.y = -200
			velocity.x = -100 * sign(velocity.x)
			life -= 1
			await get_tree().create_timer(0.5).timeout
			change_state(IDLE)
		JUMP:
			$AnimationPlayer.play("jump_up")
			jump_count = 1
		DEAD:
			died.emit()
			hide()
			is_god = true
			$GodModeTimer.stop()
			
func get_input():
	if state == HURT:
		return
		
	var right = Input.is_action_pressed("right")
	var left = Input.is_action_pressed("left")
	var jump = Input.is_action_just_pressed("jump")
	
	#모든 상태에서 일어나는 이동
	velocity.x = 0
	if right:
		velocity.x += run_speed
		$Sprite2D.flip_h = false
	if left:
		velocity.x -= run_speed
		$Sprite2D.flip_h = true
	#더블 점프
	if jump and state == JUMP and jump_count < max_jumps and jump_count > 0:
		$AnimationPlayer.play("jump_up")
		velocity.y = jump_speed / double_jump_factor
		jump_count += 1
	#땅에 있을 때만 점프 가능
	if jump and is_on_floor():
		change_state(JUMP)
		velocity.y = jump_speed
	#IDLE에서 움직이면 RUN으로 변환
	if state == IDLE and velocity.x != 0:
		change_state(RUN)
	#RUN에서 가만히 서 있으면 IDLE로 변환
	if state == RUN and velocity.x == 0:
		change_state(IDLE)
	#공중에 있으면 JUMP로 변환
	if state in [IDLE, RUN] and !is_on_floor():
		change_state(JUMP)
		
func _physics_process(delta):
	velocity.y += gravity * delta
	get_input()
	move_and_slide()
	if state == HURT:
		return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("danger"):
			hurt()
		if collision.get_collider().is_in_group("enemies"):
			if position.y < collision.get_collider().position.y:
				collision.get_collider().take_damage()
				velocity.y = -200
			else:
				hurt()
	if state == JUMP and is_on_floor():
		change_state(IDLE)
		jump_count = 0
		$Dust.emitting = true
	if state == JUMP and velocity.y > 0:
		$AnimationPlayer.play("jump_down")
	
func reset(_position):
	position = _position
	show()
	change_state(IDLE)
	life = 3
	
func set_life(value):
	life = value
	life_changed.emit(life)
	if life <= 0:
		change_state(DEAD)

func hurt():
	if not is_god and state != HURT:
		is_god = true
		$GodModeTimer.start()
		change_state(HURT)

func _on_god_mode_timer_timeout():
	is_god = false # Replace with function body.
