extends CharacterBody2D


const SPEED = 300.0
var auth_id : int


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _enter_tree() -> void:
	set_multiplayer_authority( auth_id, true )
	name = "Player_" + str(auth_id)
	add_to_group( "Player_" + str(auth_id) )

func _physics_process(_delta):
	if is_multiplayer_authority():
		var direction = Vector2( Input.get_axis( "ui_left","ui_right" ), Input.get_axis( "ui_up","ui_down" ))
		velocity = direction.normalized() * SPEED
		$Sprite.scale.x = -1 if velocity.x > 0.0 else 1
		
		move_and_slide()
