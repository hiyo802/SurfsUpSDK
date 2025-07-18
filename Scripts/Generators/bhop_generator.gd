@tool
class_name BhopGenerator
extends Node3D

## A tool for generating linear and grid ascending bhop maps with CSGBox3D platforms
## Creates platforms with consistent height progression for vertical gameplay

@export_group("Generation Settings")
@export_enum("Linear", "Grid", "Spiral") var pattern_type: int = 0
@export var platform_count: int = 30
@export var start_position: Vector3 = Vector3.ZERO

@export_group("Platform Settings")
@export var platform_size: Vector3 = Vector3(5.0, 0.5, 5.0)
@export var platform_spacing: float = 8.0
@export var height_increment_per_platform: float = 2.0
@export var use_size_variation: bool = false
@export var size_variation: float = 0.2

@export_group("Linear Pattern Settings")
@export var use_straight_direction: bool = false
@export_enum("Forward", "Right", "Back", "Left") var straight_direction: int = 0
@export var linear_direction: Vector3 = Vector3(1, 0, 1)
@export var linear_zigzag: bool = false
@export var zigzag_amplitude: float = 10.0

@export_group("Grid Pattern Settings")
@export var grid_columns: int = 5
@export var grid_rows: int = 6
@export var grid_spacing_x: float = 10.0
@export var grid_spacing_z: float = 10.0
@export var grid_height_per_row: float = 3.0
@export var grid_stagger: bool = false

@export_group("Spiral Pattern Settings")
@export var spiral_radius_start: float = 5.0
@export var spiral_radius_increment: float = 2.0
@export var spiral_angle_increment: float = 45.0
@export var spiral_height_per_rotation: float = 10.0
@export var spiral_clockwise: bool = true

@export_group("Visual Settings")
@export var platform_scene: PackedScene
@export var platform_material: Material
@export var use_gradient_colors: bool = false
@export var start_color: Color = Color.BLUE
@export var end_color: Color = Color.RED
@export var platform_operation: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION

@export_group("Actions")
@export var generate_platforms: bool = false : set = _generate_platforms
@export var clear_platforms: bool = false : set = _clear_platforms

var generated_platforms: Array[Node3D] = []

func _generate_platforms(value: bool) -> void:
	if not value or not Engine.is_editor_hint():
		return

	_clear_existing_platforms()

	match pattern_type:
		0: _generate_linear()
		1: _generate_grid()
		2: _generate_spiral()


func _generate_linear() -> void:
	var direction: Vector3

	if use_straight_direction:
		# Use predefined straight directions
		match straight_direction:
			0: direction = Vector3.FORWARD  # (0, 0, -1)
			1: direction = Vector3.RIGHT    # (1, 0, 0)
			2: direction = Vector3.BACK     # (0, 0, 1)
			3: direction = Vector3.LEFT     # (-1, 0, 0)
	else:
		# Use custom direction
		direction = linear_direction.normalized()

	var perpendicular = Vector3(-direction.z, 0, direction.x).normalized()
	var current_height = 0.0

	for i in range(platform_count):
		var pos = start_position

		# Move along direction
		pos += direction * (i * platform_spacing)

		# Add height
		current_height = i * height_increment_per_platform
		pos.y += current_height

		# Add zigzag if enabled
		if linear_zigzag:
			var zigzag_offset = sin(i * PI / 3.0) * zigzag_amplitude
			pos += perpendicular * zigzag_offset

		_create_platform_at_position(pos, i)


func _generate_grid() -> void:
	var platform_index = 0
	var total_platforms = min(grid_columns * grid_rows, platform_count)

	for row in range(grid_rows):
		for col in range(grid_columns):
			if platform_index >= total_platforms:
				break

			var pos = start_position

			# Calculate grid position
			pos.x += (col - grid_columns / 2.0) * grid_spacing_x
			pos.z += (row - grid_rows / 2.0) * grid_spacing_z

			# Add stagger effect if enabled
			if grid_stagger and row % 2 == 1:
				pos.x += grid_spacing_x * 0.5

			# Add height based on row
			pos.y += row * grid_height_per_row

			_create_platform_at_position(pos, platform_index)
			platform_index += 1


func _generate_spiral() -> void:
	var current_angle = 0.0
	var current_radius = spiral_radius_start
	var current_height = 0.0
	var angle_rad = deg_to_rad(spiral_angle_increment)
	var direction_multiplier = 1.0 if spiral_clockwise else -1.0

	for i in range(platform_count):
		var pos = start_position

		# Calculate spiral position
		pos.x += cos(current_angle) * current_radius
		pos.z += sin(current_angle) * current_radius
		pos.y += current_height

		_create_platform_at_position(pos, i)

		# Update angle and radius for next platform
		current_angle += angle_rad * direction_multiplier

		# Increase radius based on angle completion
		var rotations_completed = current_angle / (2.0 * PI)
		current_radius = spiral_radius_start + (rotations_completed * spiral_radius_increment)

		# Update height based on rotations
		current_height = rotations_completed * spiral_height_per_rotation


func _create_platform_at_position(pos: Vector3, index: int) -> void:
	var platform: Node3D

	if platform_scene:
		# Use the provided platform scene
		platform = platform_scene.instantiate()
		platform.name = "BhopPlatform" + str(index)

		# Apply size variation if enabled
		if use_size_variation:
			var variation = 1.0 + randf_range(-size_variation, size_variation)
			platform.scale = Vector3.ONE * variation

		# Apply gradient colors if enabled and the platform has a MeshInstance3D
		if use_gradient_colors:
			var t = float(index) / float(max(platform_count - 1, 1))
			var color = start_color.lerp(end_color, t)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color

			# Try to apply material to all MeshInstance3D children
			for child in platform.get_children():
				if child is MeshInstance3D:
					child.material_override = mat
				elif child is CSGShape3D:
					child.material = mat
	else:
		# Fall back to CSGBox3D
		var csg_platform = CSGBox3D.new()
		csg_platform.name = "BhopPlatform" + str(index)

		# Set size with optional variation
		var size = platform_size
		if use_size_variation:
			var variation = 1.0 + randf_range(-size_variation, size_variation)
			size *= variation
		csg_platform.size = size

		# Set visual properties
		csg_platform.operation = platform_operation

		# Apply material and color
		if use_gradient_colors:
			var t = float(index) / float(max(platform_count - 1, 1))
			var color = start_color.lerp(end_color, t)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color
			csg_platform.material = mat
		elif platform_material:
			csg_platform.material = platform_material

		# Set physics
		csg_platform.use_collision = true
		csg_platform.collision_layer = 1
		csg_platform.collision_mask = 1

		platform = csg_platform

	# Set position
	platform.position = pos

	# Add to scene
	add_child(platform)
	platform.owner = get_tree().edited_scene_root
	generated_platforms.append(platform)


func _clear_platforms(value: bool) -> void:
	if not value or not Engine.is_editor_hint():
		return

	_clear_existing_platforms()


func _clear_existing_platforms() -> void:
	for platform in generated_platforms:
		if is_instance_valid(platform):
			platform.queue_free()
	generated_platforms.clear()

	# Clear any orphaned platforms (both CSGBox3D and custom scene instances)
	for child in get_children():
		if child.name.begins_with("BhopPlatform"):
			child.queue_free()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()

	if platform_count < 1:
		warnings.append("Platform count must be at least 1")

	if platform_size.x <= 0 or platform_size.y <= 0 or platform_size.z <= 0:
		warnings.append("Platform size dimensions must be greater than 0")

	if platform_spacing <= 0:
		warnings.append("Platform spacing must be greater than 0")

	if pattern_type == 0 and linear_direction.length() == 0:
		warnings.append("Linear direction cannot be zero")

	return warnings
