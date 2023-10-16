extends Node

var world: World
var player: Player

var rng: RandomNumberGenerator

var enemy_spawn_radius: int = 1000

var enemy_scene = preload("res://scenes/ships/enemy/enemy.tscn")
var enemies: Array[Enemy]

var enemy_spawn_timer: Timer

var already_spawned: Dictionary

func _on_world_ready(_world: World) -> void:
	self.world = _world

func _on_player_ready(_player: Player) -> void:
	self.player = _player
	
	enemy_spawn_timer = Timer.new()
	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.wait_time = 10
	add_child(enemy_spawn_timer)
	enemy_spawn_timer.start()
	enemy_spawn_timer.timeout.connect(self._on_enemy_spawn_timer_timeout)
	rng = RandomNumberGenerator.new()
	check_spawns()

func _on_enemy_destroyed(enemy: Enemy) -> void:
	enemies.erase(enemy)

func _on_enemy_spawn_timer_timeout() -> void:
	check_spawns()

func _on_reset_game() -> void:
	already_spawned.clear()
	enemies.clear()
	enemy_spawn_timer.queue_free()

func _on_object_cleared(object: Node2D):
	if object is Enemy:
		enemies.erase(object)
		already_spawned[object._home] = false

func _ready() -> void:
	EventBus.player_ready.connect(self._on_player_ready)
	EventBus.world_ready.connect(self._on_world_ready)
	EventBus.enemy_destroyed.connect(self._on_enemy_destroyed)
	EventBus.object_cleared.connect(self._on_object_cleared)

func check_spawns() -> void:
	print("test")
	var center = player.position

	var x_from: int = floor(center.x - (enemy_spawn_radius/2.0))
	var x_to: int = ceil(center.x + (enemy_spawn_radius/2.0))
	var y_from: int = floor(center.y - (enemy_spawn_radius/2.0))
	var y_to: int = ceil(center.y + (enemy_spawn_radius/2.0))
	
	while x_from < x_to:
		while y_from < y_to:
			rng.seed = GameState.game_seed + x_from ^ y_from
			var spawn_location: Vector2 = Vector2(x_from, y_from)
			if rng.randf_range(0, 1) <= 0.003 && !already_spawned.has(spawn_location) && already_spawned.get(spawn_location) == true:
				var enemy = enemy_scene.instantiate()
				enemies.append(enemy)
				world.add_object(enemy)
				enemy.position = spawn_location
				already_spawned[spawn_location] = true
			
			y_from += 1
		x_from += 1
	
	if enemies.size() < 2:
		var enemy1 = enemy_scene.instantiate()
		var enemy2 = enemy_scene.instantiate()
		enemies.append(enemy1)
		enemies.append(enemy2)
		world.add_object(enemy1)
		world.add_object(enemy2)
		enemy1.position = Vector2(player.position.x + randi_range(-500, 500), player.position.y + randi_range(-500, 500))
		enemy2.position = Vector2(player.position.x + randi_range(-500, 500), player.position.y + randi_range(-500, 500))
