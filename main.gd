extends Node2D

const ADDRESS := "127.0.0.1"
const PORT := 6678
const MAX_PLAYERS := 4

var other_guy_id:= 1




# ---- HOST / JOIN STUFF

func _ready() -> void:
	multiplayer.peer_connected.connect( _on_peer_connected )

func _on_peer_connected( id:int ) -> void:
	# This sets the other client id, if you're a  client the "other" guy is the server hence the 1 declaration
	if multiplayer.is_server():
		other_guy_id = id
		spawn_existing_players_on_new_client( id )



func host_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server( PORT, MAX_PLAYERS )
	if error != OK:
		print("Could not create server!")
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer( peer )
	print("Hosting!")


func join_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client( ADDRESS, PORT )
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer( peer )





# ---- PLAYER STUFF

@rpc ("any_peer", "call_local")
func spawn_player( auth_id:int ) -> void:
	var new_player = load("res://player.tscn").instantiate()
	new_player.auth_id = auth_id
	add_child( new_player )


@rpc ("any_peer", "call_local", "reliable")
func delete_player( auth_id:int ) -> void:
	for player in get_tree().get_nodes_in_group("Player_" + str(auth_id) ):
		player.queue_free()

@rpc ("any_peer", "call_remote")
func spawn_existing_players_on_new_client( auth_id:int ) -> void:
	# Spawn players on the new _client
	for player in get_tree().get_nodes_in_group("Player_" + str(multiplayer.get_unique_id()) ):
		spawn_player.rpc_id(auth_id, multiplayer.get_unique_id())


@rpc ("any_peer", "call_local")
func ask_auth_to_delete() -> void:
	delete_player.rpc( multiplayer.get_unique_id() )


func _on_create_player_pressed() -> void:
	spawn_player.rpc( multiplayer.get_unique_id() )


func _on_delete_player_pressed() -> void:
	# WORKS, so telling the other guys to call the rpc from his end produced no errors, but calling it for them via rpc_id broke it
	ask_auth_to_delete.rpc_id( other_guy_id )
	
	# WORKS - Can delete all players from all clients using the test method
	#for player in get_tree().get_nodes_in_group("Player"):
		#ask_auth_to_delete.rpc_id( player.get_multiplayer_authority() )
	
	# PRODUCESS - Transferring authority to me first RECURSIVELY (true)
	#for player in get_tree().get_nodes_in_group("Player_" + str(other_guy) ):
		#player.set_multiplayer_authority( 1, true )
	#delete_player.rpc( other_guy )
	
	# PRODUCES FOREVER - delete the other clients player from this one
	#delete_player( other_guy )
	
	# PRODUCES - Delete the other guy's node on both from this node
	#delete_player.rpc( other_guy )
	
	# HAPPENS INFINATELY
	#delete_player.rpc_id( other_guy, multiplayer.get_unique_id() )
	
	# DOES NOT - only delete it on the auth, but it's still on this one
	#delete_player.rpc_id(other_guy, other_guy)
	
	# PRODUCES - calling delete.rpc_id form here
	#delete_player.rpc_id(other_guy, other_guy)
	#delete_player( other_guy )
