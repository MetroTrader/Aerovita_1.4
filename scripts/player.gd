extends CharacterBody3D

# Player nodes

@onready var nek = $nek
@onready var head = $nek/head
@onready var eyes = $nek/head/eyes
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var camera = $nek/head/eyes/Camera3D
@onready var camera_3d = $nek/head/eyes/Camera3D
@onready var cam_rotation_amount : float = 0.01
@onready var animation_player = $nek/head/eyes/AnimationPlayer
@onready var view_model_camera = $nek/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera
@onready var animation_player2 = $nek/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera/Weapons_Manager/fps_rig/boxy/AnimationPlayer
@onready var weapon_holder : Node3D = $nek/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera/Weapons_Manager/fps_rig
@onready var weapon_sway_amount : float = 5
@onready var weapon_rotation_amount : float = 1
# Speed vars

var current_speed = 5.0

const walking_speed = 5.0
const springting_speed = 8.0
const crouching_speed = 3.0

#States

var walking = false
var springting = false
var crouching = false
var free_looking = false
var sliding = false

#Slide vars

var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0
#Head bobbing vars

const head_bobbing_springting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_springting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

var boxy_in_use = false;

var head_bobbing_
#Movement vars

var crouching_deph = -0.5

const jump_velocity = 4.5

var def_weapon_holder_pos : Vector3

var lerp_speed = 10.0
var air_lerp_speed = 3.0
var free_look_tilt_amount = 8

var last_velocity = Vector3.ZERO

#Input vars

var direction = Vector3.ZERO
const mouse_sens = 0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	def_weapon_holder_pos = weapon_holder.position
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$nek/head/eyes/Camera3D/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()
	

func _input(event):

	if(event.is_action_pressed("shoot")):
		animation_player2.play("fire")
		
	if(event.is_action_pressed("reload")):
		animation_player2.play("reload")
		
	if(event.is_action_pressed("use")):
		boxy_in_use = !boxy_in_use
		if(boxy_in_use):
			animation_player2.play("pull_away")
		else:
			animation_player2.play("pull_up")
	
	# Mouse looking logic
	if event is InputEventMouseMotion:
		if free_looking:
			nek.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			nek.rotation.y = clamp(nek.rotation.y, deg_to_rad(-120),deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89),deg_to_rad(89))
		view_model_camera.sway(Vector2(event.relative.x,event.relative.y))

var _was_on_floor_last_frame = false
var _snapped_to_stairs_last_frame = false
func _snap_down_to_stairs_check():
	var did_snap = false
	if not is_on_floor() and velocity.y <= 0 and (_was_on_floor_last_frame or _snapped_to_stairs_last_frame) and $StairsBelowRayCast3D.is_colliding():
		var body_test_result = PhysicsTestMotionResult3D.new()
		var params = PhysicsTestMotionParameters3D.new()
		var max_step_down = -0.5
		params.from = self.global_transform
		params.motion = Vector3(0,max_step_down,0)
		if PhysicsServer3D.body_test_motion(self.get_rid(), params, body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true

	_was_on_floor_last_frame = is_on_floor()
	_snapped_to_stairs_last_frame = did_snap
	
@onready var _initial_separation_ray_dist = abs($StepUpSeparationRay_F.position.z)
var _last_xz_vel : Vector3 = Vector3(0,0,0)
func _rotate_step_up_separation_ray():
	var xz_vel = velocity * Vector3(1,0,1)
	
	if xz_vel.length() < 0.1:
		xz_vel = _last_xz_vel
	else:
		_last_xz_vel = xz_vel
	
	var xz_f_ray_pos = xz_vel.normalized() * _initial_separation_ray_dist
	$StepUpSeparationRay_F.global_position.x = self.global_position.x + xz_f_ray_pos.x
	$StepUpSeparationRay_F.global_position.z = self.global_position.z + xz_f_ray_pos.z

	var xz_l_ray_pos = xz_f_ray_pos.rotated(Vector3(0,1.0,0), deg_to_rad(-50))
	$StepUpSeparationRay_F.global_position.x = self.global_position.x + xz_f_ray_pos.x
	$StepUpSeparationRay_F.global_position.z = self.global_position.z + xz_f_ray_pos.z
	
	var xz_r_ray_pos = xz_f_ray_pos.rotated(Vector3(0,1.0,0), deg_to_rad(-50))
	$StepUpSeparationRay_F.global_position.x = self.global_position.x + xz_f_ray_pos.x
	$StepUpSeparationRay_F.global_position.z = self.global_position.z + xz_f_ray_pos.z
	
func _physics_process(delta):
	$nek/head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera.global_transform = camera.global_transform
	#Getting movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	#Handle movement state
	
	#Crouching
	
	if Input.is_action_pressed("crouch") || sliding:
		
		current_speed = lerp(current_speed,crouching_speed,delta*lerp_speed)
		head.position.y = lerp(head.position.y,crouching_deph,delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		#Slide begin logic
		
		if springting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
			print("Slide begin")
		
		walking = false
		springting = false
		crouching = true
		
	elif !ray_cast_3d.is_colliding(): 
	
	# Standing
	
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		
		head.position.y = lerp(head.position.y,0.0,delta*lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			# Springting
			current_speed = lerp(current_speed,springting_speed,delta*lerp_speed)
			
			walking = false
			springting = true
			crouching = false
			
		else:
			#Walking
			current_speed = lerp(current_speed,walking_speed,delta*lerp_speed)
			
			walking = true
			springting = false
			crouching = false
	
	# Handle free looking
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z,-deg_to_rad(3.0),delta*lerp_speed)
		else:
			eyes.rotation.z = -deg_to_rad(nek.rotation.y*free_look_tilt_amount)
	else:
		free_looking = false
		nek.rotation.y = lerp(nek.rotation.y,0.0,delta*lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z,0.0,delta*lerp_speed)
	
	# Handle sliding
	
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			print("Slide end")
			free_looking = false
			
	#Handle headbob
	if springting:
		head_bobbing_current_intensity = head_bobbing_springting_intensity
		head_bobbing_index += head_bobbing_springting_speed*delta
	elif walking: 
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed*delta
	elif crouching: 
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed*delta
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2)+0.5
		
		eyes.position.y = lerp(eyes.position.y,head_bobbing_vector.y*(head_bobbing_current_intensity/2.0),delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,head_bobbing_vector.x*head_bobbing_current_intensity,delta*lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y,0.0,delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,0.0,delta*lerp_speed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false
		animation_player.play("jump")
		
	#Handle landing
	if is_on_floor():
		if last_velocity.y < -10.0:
			animation_player.play("roll")
		elif last_velocity.y < -04.0:
			animation_player.play("landing")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*air_lerp_speed)

	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x,0,slide_vector.y)).normalized()
		current_speed = (slide_timer + 0.1) * slide_speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		

	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
	last_velocity = velocity
	
	_rotate_step_up_separation_ray()
	move_and_slide()
	_snap_down_to_stairs_check()
	cam_tilt(input_dir.x, delta)
	weapon_tilt(input_dir.x, delta)
	
func cam_tilt(input_x, delta):
	if camera:
		camera.rotation.z = lerp(camera.rotation.z, -input_x * cam_rotation_amount, 10 * delta)

func weapon_tilt(input_x, delta):
	if weapon_holder:
		weapon_holder.rotation.z = lerp(weapon_holder.rotation.z, -input_x * cam_rotation_amount, 10 * delta)
		
func weapon_bob(vel : float, delta):
	if weapon_holder:
		if vel > 0:
			var bob_amount : float = 0.1
			var bob_freq : float = 0.1
			weapon_holder.position.y = lerp(weapon_holder.position.y, def_weapon_holder_pos.y + sin(Time.get_ticks_msec() * bob_freq) * bob_amount, 10 * delta)
			weapon_holder.position.x = lerp(weapon_holder.position.x, def_weapon_holder_pos.x + sin(Time.get_ticks_msec() * bob_freq * 5) * bob_amount, 10 * delta)
			
		else:
			weapon_holder.position.y = lerp(weapon_holder.position.y, def_weapon_holder_pos.y, 10 * delta)
			weapon_holder.position.x = lerp(weapon_holder.position.x, def_weapon_holder_pos.x, 10 * delta)
func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
