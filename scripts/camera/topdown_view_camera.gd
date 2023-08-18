extends Node3D

@onready var cam_holder = $CameraHolder
@onready var cam = $CameraHolder/Camera3D

@export var follow_lerp_speed := 1.0
@export var vertical_follow_multiplier := 1.0

#zoom variables
var zoom_level : float = 12.0
@export var min_zoom := 3.0
@export var max_zoom := 15.0
@export var zoom_factor := 0.2
@export var zoom_speed := 0.1

func _process(_delta):
	#send rotation data
	GameData.cam_rotation = cam_holder.rotation.y
	#smooth move to player pos
	cam_holder.position.x = lerp(cam_holder.position.x,GameData.player_position.x, follow_lerp_speed)
	cam_holder.position.z = lerp(cam_holder.position.z,GameData.player_position.z, follow_lerp_speed)
	cam_holder.position.y = lerp(cam_holder.position.y,GameData.player_position.y, follow_lerp_speed * vertical_follow_multiplier)

