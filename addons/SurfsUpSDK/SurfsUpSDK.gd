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


func _extract_path_from_dependency(dep: String) -> String:
	if dep.contains("::::"):
		return dep.split("::::")[1]
	elif dep.contains("::"):
		return dep.split("::")[2]
	elif dep.begins_with("res://"):
		return dep
	else:
		return ""


func _get_all_dependencies_recursive(resource_path: String, visited: Dictionary = {}) -> Array:
	visited[resource_path] = true
	var all_deps = []

	var dependencies = ResourceLoader.get_dependencies(resource_path)

	for dep in dependencies:
		var actual_path = _extract_path_from_dependency(dep)
		if actual_path != "" and actual_path not in visited:
			all_deps.append(actual_path)
			all_deps.append_array(_get_all_dependencies_recursive(actual_path, visited))

	if resource_path.ends_with(".tscn") or resource_path.ends_with(".scn"):
		var resource = load(resource_path)
		if resource is PackedScene:
			var scene_state = resource.get_state()
			for i in range(scene_state.get_node_count()):
				for j in range(scene_state.get_node_property_count(i)):
					var prop_value = scene_state.get_node_property_value(i, j)
					_scan_resource_for_dependencies(prop_value, all_deps, visited)

	elif resource_path.ends_with(".glb") or resource_path.ends_with(".gltf") or resource_path.ends_with(".fbx") \
	or resource_path.ends_with(".obj") or resource_path.ends_with(".mtl"):
		# GLB files are imported resources, we need to include both the source and imported files
		if FileAccess.file_exists(resource_path):
			# Include the .import file
			var import_file = resource_path + ".import"
			if FileAccess.file_exists(import_file) and import_file not in visited:
				visited[import_file] = true
				all_deps.append(import_file)

				# Read the import file to find any generated resources
				var import_config = ConfigFile.new()
				if import_config.load(import_file) == OK:
					# Get the imported scene file path
					var imported_path = import_config.get_value("remap", "path", "")
					if imported_path != "" and FileAccess.file_exists(imported_path) and imported_path not in visited:
						visited[imported_path] = true
						all_deps.append(imported_path)
						# Recursively scan the imported scene
						all_deps.append_array(_get_all_dependencies_recursive(imported_path, visited))

	elif resource_path.ends_with(".png") or resource_path.ends_with(".jpg") or resource_path.ends_with(".jpeg") or resource_path.ends_with(".webp") \
	or resource_path.ends_with(".svg") or resource_path.ends_with(".exr") or resource_path.ends_with(".hdr") \
	or resource_path.ends_with(".wav") or resource_path.ends_with(".mp3") or resource_path.ends_with(".ogg") \
	or resource_path.ends_with(".gdshader"):
		# Image and audio files need their import files and imported resources
		if FileAccess.file_exists(resource_path):
			# Include the .import file
			var import_file = resource_path + ".import"
			if FileAccess.file_exists(import_file) and import_file not in visited:
				visited[import_file] = true
				all_deps.append(import_file)

				# Read the import file to find the imported resource
				var import_config = ConfigFile.new()
				if import_config.load(import_file) == OK:
					# Get all possible imported resource file paths
					var remap_section = "remap"
					if import_config.has_section(remap_section):
						for key in import_config.get_section_keys(remap_section):
							if key.begins_with("path"):
								var imported_path = import_config.get_value(remap_section, key, "")
								if imported_path != "" and FileAccess.file_exists(imported_path) and imported_path not in visited:
									visited[imported_path] = true
									all_deps.append(imported_path)

					# Also check dest_files array
					var dest_files = import_config.get_value("deps", "dest_files", [])
					for dest_file in dest_files:
						if dest_file != "" and FileAccess.file_exists(dest_file) and dest_file not in visited:
							visited[dest_file] = true
							all_deps.append(dest_file)

	return all_deps


func _scan_node_and_children(node: Node, all_deps: Array, visited: Dictionary):
	if node is MeshInstance3D:
		_scan_resource_for_dependencies(node, all_deps, visited)
	elif node is GeometryInstance3D and node.material_override != null:
		_scan_resource_for_dependencies(node.material_override, all_deps, visited)

	for child in node.get_children():
		_scan_node_and_children(child, all_deps, visited)


func _scan_resource_for_dependencies(resource, all_deps: Array, visited: Dictionary):
	if resource == null:
		return

	if resource is Resource and resource.resource_path != "" and resource.resource_path not in visited:
		visited[resource.resource_path] = true
		all_deps.append(resource.resource_path)
		var sub_deps = _get_all_dependencies_recursive(resource.resource_path, visited)
		all_deps.append_array(sub_deps)

	if resource is StandardMaterial3D or resource is ORMMaterial3D:
		var textures = []
		if resource is StandardMaterial3D:
			textures = [
				resource.albedo_texture,
				resource.normal_texture,
				resource.orm_texture if resource is ORMMaterial3D else null,
				resource.metallic_texture,
				resource.roughness_texture,
				resource.emission_texture,
				resource.heightmap_texture,
				resource.backlight_texture,
				resource.refraction_texture,
				resource.detail_albedo,
				resource.detail_normal
			]

		for texture in textures:
			if texture != null and texture is Texture and texture.resource_path != "" and texture.resource_path not in visited:
				visited[texture.resource_path] = true
				all_deps.append(texture.resource_path)

	elif resource is ShaderMaterial and resource.shader != null:
		if resource.shader.resource_path != "" and resource.shader.resource_path not in visited:
			visited[resource.shader.resource_path] = true
			all_deps.append(resource.shader.resource_path)

		var shader_params = resource.shader.get_shader_uniform_list()
		for param in shader_params:
			var param_name = param.get("name", "")
			if param_name != "":
				var param_value = resource.get_shader_parameter(param_name)
				if param_value is Texture and param_value.resource_path != "" and param_value.resource_path not in visited:
					visited[param_value.resource_path] = true
					all_deps.append(param_value.resource_path)

	elif resource is ArrayMesh:
		for i in range(resource.get_surface_count()):
			var mat = resource.surface_get_material(i)
			_scan_resource_for_dependencies(mat, all_deps, visited)

	elif resource is MeshInstance3D and resource.mesh != null:
		_scan_resource_for_dependencies(resource.mesh, all_deps, visited)
		for i in range(resource.get_surface_override_material_count()):
			var mat = resource.get_surface_override_material(i)
			_scan_resource_for_dependencies(mat, all_deps, visited)

	elif resource is Array:
		for item in resource:
			_scan_resource_for_dependencies(item, all_deps, visited)


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

	print("Collecting all dependencies for: %s" % scene_path)

	var visited = {}
	visited[scene_path] = true
	var all_files = [scene_path]

	var dependencies = _get_all_dependencies_recursive(scene_path, visited)
	all_files.append_array(dependencies)

	all_files = Array(visited.keys())

	print("Total files found: %d" % all_files.size())

	var included_files = 0
	for file_path in all_files:
		if file_path != "" and FileAccess.file_exists(file_path):
			# Only include .import files and files in .godot directory to reduce size
			if file_path.ends_with(".import") or file_path.contains("/.godot/"):
				packer.add_file(file_path, file_path)
				included_files += 1
			elif file_path.ends_with(".tscn") or file_path.ends_with(".scn") or file_path.ends_with(".tres") or file_path.ends_with(".res"):
				# Always include scene and resource files
				packer.add_file(file_path, file_path)
				included_files += 1
			elif file_path.ends_with(".gdshader"):
				# Include shader files
				packer.add_file(file_path, file_path)
				included_files += 1
			elif file_path.ends_with(".wav") or file_path.ends_with(".mp3") or file_path.ends_with(".ogg"):
				# Include audio source files
				packer.add_file(file_path, file_path)
				included_files += 1

	var flush_result = packer.flush()
	if flush_result == OK:
		print("Scene exported to PCK: %s" % pck_path)
		print("Included %d of %d files (excluded source assets to reduce size)" % [included_files, all_files.size()])
	else:
		push_error("Failed to write PCK file.")
