@tool
extends EditorPlugin

var dir_dialog: FileDialog
var surfsup_menu: PopupMenu = PopupMenu.new()
var export_button: Button

func _enter_tree():
	surfsup_menu.add_item("Set Maps Directory", 0)
	surfsup_menu.add_item("Export Current Scene", 1)
	surfsup_menu.id_pressed.connect(_on_menu_option)

	add_tool_submenu_item("[SurfsUp] SDK Tools", surfsup_menu)

	dir_dialog = FileDialog.new()
	dir_dialog.access = FileDialog.ACCESS_FILESYSTEM
	dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dir_dialog.title = "Select SurfsUp Maps Directory"
	dir_dialog.dir_selected.connect(_on_directory_selected)
	var maps_dir = ProjectSettings.get_setting("surfs_up/maps_directory")
	if maps_dir:
		dir_dialog.current_dir = maps_dir

	get_editor_interface().get_base_control().add_child(dir_dialog)

	# Export Button with Icon
	var export_icon = preload("res://addons/SurfsUpSDK/Icons/export.png")
	export_button = Button.new()
	export_button.flat = true
	export_button.icon = export_icon
	export_button.tooltip_text = "Export Current Scene to Maps Directory"
	export_button.connect("pressed", Callable(self, "_export_current_scene_to_pck"))
	add_control_to_container(CONTAINER_TOOLBAR, export_button)


func _exit_tree():
	remove_tool_menu_item("[SurfsUp] SDK Tools")
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, export_button)
	if dir_dialog:
		dir_dialog.queue_free()


func _on_menu_option(id):
	match id:
		0:
			dir_dialog.popup_centered_ratio()
		1:
			_export_current_scene_to_pck()


func _on_directory_selected(dir_path: String):
	ProjectSettings.set_setting("surfs_up/maps_directory", dir_path)
	ProjectSettings.save()
	print("Maps directory set to: %s" % dir_path)


func _export_current_scene_to_pck():
	var maps_dir = ProjectSettings.get_setting("surfs_up/maps_directory", "")
	if maps_dir == "":
		push_error("Maps directory is not set.")
		return

	var editor_interface = get_editor_interface()
	var edited_scene = editor_interface.get_edited_scene_root()
	if edited_scene == null:
		push_error("No scene is currently open.")
		return

	var scene_path = edited_scene.scene_file_path
	if not FileAccess.file_exists(scene_path):
		push_error("Scene file does not exist: %s" % scene_path)
		return

	# Save scene before export
	if editor_interface.save_scene() != 0:
		push_error("Failed to save the current scene.")
		return

	# Start packing
	var pck_path = maps_dir.path_join(scene_path.get_file().get_basename() + ".pck")
	var packer = PCKPacker.new()
	var result = packer.pck_start(pck_path)
	if result != OK:
		push_error("Failed to start PCK pack: %s" % pck_path)
		return

	var dependencies = ResourceLoader.get_dependencies(scene_path)
	dependencies.push_back(scene_path)

	# print("Deps: %s" % dependencies)

	for file in dependencies:
		var file_path: String = file.get_slice("::", 2)
		# print("PCK Add File: %s" % file_path)
		packer.add_file(file_path, file_path)

	var flush_result = packer.flush()
	if flush_result == OK:
		print("Scene exported to PCK: %s" % pck_path)
	else:
		push_error("Failed to write PCK file.")
