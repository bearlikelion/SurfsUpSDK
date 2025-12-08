@tool
class_name RampGenerator
extends Node3D

enum RampPathMode { MANUAL, GENERATED }
enum PathBehavior { STRAIGHT, CURVE_UP, CURVE_DOWN, CURVE_LEFT, CURVE_RIGHT }
enum RampDirection { CENTER, LEFT, RIGHT }
enum MirrorAxis { NONE, X_AXIS, Y_AXIS, Z_AXIS }
enum ClipOperation { INTERSECTION, SUBTRACTION }
enum CapForwardAxis { X_PLUS, X_MINUS, Y_PLUS, Y_MINUS, Z_PLUS, Z_MINUS }
enum CapOperation { UNION, INTERSECTION, SUBTRACTION }

const MIN_ANGLE: float = 45.573

var _ramp_direction: RampDirection = RampDirection.CENTER
var _triangle_angle: float = 45.573
var _triangle_height: float = 4.1
var _triangle_base: float = 4.0
var _ramp_material: Material = null

var _mode: RampPathMode = RampPathMode.MANUAL
var _path_behavior: PathBehavior = PathBehavior.STRAIGHT
var _path_length: float = 20.0
var _path_height: float = 10.0
var _path_curvature: float = 0.5

var _mirror_axis: MirrorAxis = MirrorAxis.NONE
var _mirror_offset: float = 5.0
var _live_mirror: bool = false

var _enable_clipping: bool = false
var _clip_shape: PackedVector2Array = PackedVector2Array([Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)])
var _clip_operation: ClipOperation = ClipOperation.INTERSECTION
var _keep_trim: bool = false
var _trim_material: Material = null

# Cap Settings
var _enable_caps: bool = false
var _cap_shape: PackedScene = null
var _cap_forward_axis: CapForwardAxis = CapForwardAxis.X_PLUS
var _cap_operation: CapOperation = CapOperation.SUBTRACTION

# Internal guard to prevent recursive dependent updates between angle/base/height
var _suspend_dependent_updates: bool = false

func _get_property_list() -> Array:
	var properties: Array = []
	# Ramp Settings
	properties.append({"name": "Ramp Settings", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY})
	properties.append({"name": "ramp_direction", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "CENTER,LEFT,RIGHT", "usage": PROPERTY_USAGE_DEFAULT})
	properties.append({"name": "triangle_angle", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "45.573,89.0,0.1", "usage": PROPERTY_USAGE_DEFAULT})
	properties.append({"name": "triangle_height", "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT})
	properties.append({"name": "triangle_base", "type": TYPE_FLOAT, "usage": PROPERTY_USAGE_DEFAULT})
	properties.append({"name": "ramp_material", "type": TYPE_OBJECT, "hint": PROPERTY_HINT_RESOURCE_TYPE, "hint_string": "Material", "usage": PROPERTY_USAGE_DEFAULT})

	# Path Settings
	properties.append({"name": "Path Settings", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY})
	properties.append({"name": "mode", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "MANUAL,GENERATED", "usage": PROPERTY_USAGE_DEFAULT})
	if _mode == RampPathMode.GENERATED:
		properties.append({"name": "path_behavior", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "STRAIGHT,CURVE_UP,CURVE_DOWN,CURVE_LEFT,CURVE_RIGHT", "usage": PROPERTY_USAGE_DEFAULT})
		properties.append({"name": "path_length", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "1.0,100.0,0.1", "usage": PROPERTY_USAGE_DEFAULT})
		properties.append({"name": "path_height", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.0,50.0,0.1", "usage": PROPERTY_USAGE_DEFAULT})
		properties.append({"name": "path_curvature", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.0,1.0,0.01", "usage": PROPERTY_USAGE_DEFAULT})

	# Mirroring Settings
	properties.append({"name": "Mirroring Settings", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY})
	properties.append({"name": "mirror_axis", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "NONE,X_AXIS,Y_AXIS,Z_AXIS", "usage": PROPERTY_USAGE_DEFAULT})
	if _mirror_axis != MirrorAxis.NONE:
		properties.append({"name": "mirror_offset", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.0,50.0,0.1", "usage": PROPERTY_USAGE_DEFAULT})
		properties.append({"name": "live_mirror", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})

	# Clipping Settings
	properties.append({"name": "Clipping Settings", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY})
	properties.append({"name": "enable_clipping", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})
	if _enable_clipping:
		properties.append({"name": "clip_shape", "type": TYPE_PACKED_VECTOR2_ARRAY, "usage": PROPERTY_USAGE_DEFAULT})
		properties.append({"name": "clip_operation", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "INTERSECTION,SUBTRACTION", "usage": PROPERTY_USAGE_DEFAULT})
		properties.append({"name": "keep_trim", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})
		properties.append({"name": "trim_material", "type": TYPE_OBJECT, "hint": PROPERTY_HINT_RESOURCE_TYPE, "hint_string": "Material", "usage": PROPERTY_USAGE_DEFAULT})


	# Cap Settings
	properties.append({"name": "Cap Settings", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY})
	properties.append({"name": "enable_caps", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_DEFAULT})
	if _enable_caps:
		properties.append({"name": "cap_shape", "type": TYPE_OBJECT, "hint": PROPERTY_HINT_RESOURCE_TYPE, "hint_string": "PackedScene", "usage": PROPERTY_USAGE_DEFAULT})
		properties.append({"name": "cap_forward_axis", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "X_PLUS,X_MINUS,Y_PLUS,Y_MINUS,Z_PLUS,Z_MINUS", "usage": PROPERTY_USAGE_DEFAULT})
		properties.append({"name": "cap_operation", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "UNION,INTERSECTION,SUBTRACTION", "usage": PROPERTY_USAGE_DEFAULT})

	return properties

func _get(property: StringName) -> Variant:
	match property:
		"ramp_direction":
			return _ramp_direction
		"triangle_angle":
			return _triangle_angle
		"triangle_height":
			return _triangle_height
		"triangle_base":
			return _triangle_base
		"ramp_material":
			return _ramp_material
		"mode":
			return _mode
		"path_behavior":
			return _path_behavior
		"path_length":
			return _path_length
		"path_height":
			return _path_height
		"path_curvature":
			return _path_curvature
		"mirror_axis":
			return _mirror_axis
		"mirror_offset":
			return _mirror_offset
		"live_mirror":
			return _live_mirror
		"enable_clipping":
			return _enable_clipping
		"clip_shape":
			return _clip_shape
		"clip_operation":
			return _clip_operation
		"keep_trim":
			return _keep_trim
		"trim_material":
			return _trim_material
		"enable_caps":
			return _enable_caps
		"cap_shape":
			return _cap_shape
		"cap_forward_axis":
			return _cap_forward_axis
		"cap_operation":
			return _cap_operation
	return null

func _set(property: StringName, value: Variant) -> bool:
	match property:
		"ramp_direction":
			_set_ramp_direction(value)
			return true
		"triangle_angle":
			_set_triangle_angle(value)
			return true
		"triangle_height":
			_set_triangle_height(value)
			return true
		"triangle_base":
			_set_triangle_base(value)
			return true
		"ramp_material":
			_set_ramp_material(value)
			return true
		"mode":
			_set_mode(value)
			notify_property_list_changed()
			return true
		"path_behavior":
			_set_path_behavior(value)
			return true
		"path_length":
			_set_path_length(value)
			return true
		"path_height":
			_set_path_height(value)
			return true
		"path_curvature":
			_set_path_curvature(value)
			return true
		"mirror_axis":
			_set_mirror_axis(value)
			notify_property_list_changed()
			return true
		"mirror_offset":
			_set_mirror_offset(value)
			return true
		"live_mirror":
			_set_live_mirror(value)
			return true
		"enable_clipping":
			_set_enable_clipping(value)
			notify_property_list_changed()
			return true
		"clip_shape":
			_set_clip_shape(value)
			return true
		"clip_operation":
			_set_clip_operation(value)
			return true
		"keep_trim":
			_set_keep_trim(value)
			notify_property_list_changed()
			return true
		"trim_material":
			_set_trim_material(value)
			return true
		"enable_caps":
			_set_enable_caps(value)
			notify_property_list_changed()
			return true
		"cap_shape":
			_set_cap_shape(value)
			return true
		"cap_forward_axis":
			_set_cap_forward_axis(value)
			return true
		"cap_operation":
			_set_cap_operation(value)
			return true
	return false

var _dirty: bool = false
var _last_curve_hash: int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		_request_apply()


func _process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		_apply()
	if Engine.is_editor_hint() and _live_mirror and _mirror_axis != MirrorAxis.NONE:
		_update_live_mirror_curve_if_changed()
	# Keep caps in sync with any path edits (editor or runtime)
	_update_caps_curve_if_changed()

func _set_ramp_direction(value: RampDirection) -> void:
	_ramp_direction = value
	# Keep base consistent when switching to CENTER
	if _ramp_direction == RampDirection.CENTER:
		var angle_rad_c := deg_to_rad(_triangle_angle)
		var new_base_c: float = 2.0 * _triangle_height / max(tan(angle_rad_c), 0.0001)
		_suspend_dependent_updates = true
		set("triangle_base", new_base_c)
		_suspend_dependent_updates = false
	_request_apply()

func _set_triangle_angle(value: float) -> void:
	_triangle_angle = clampf(value, MIN_ANGLE, 89.0)
	if _ramp_direction == RampDirection.CENTER:
		var angle_rad: float = deg_to_rad(_triangle_angle)
		var new_base: float = 2.0 * _triangle_height / max(tan(angle_rad), 0.0001)
		# Route through property setter so Inspector updates immediately
		if not _suspend_dependent_updates:
			_suspend_dependent_updates = true
			set("triangle_base", new_base)
			_suspend_dependent_updates = false
	_request_apply()

func _set_triangle_height(value: float) -> void:
	_triangle_height = value
	# When centered, adjust base to maintain angle relation
	if _ramp_direction == RampDirection.CENTER:
		var angle_rad_h: float = deg_to_rad(_triangle_angle)
		var new_base_h: float = 2.0 * _triangle_height / max(tan(angle_rad_h), 0.0001)
		if not _suspend_dependent_updates:
			_suspend_dependent_updates = true
			set("triangle_base", new_base_h)
			_suspend_dependent_updates = false
	_request_apply()

func _set_triangle_base(value: float) -> void:
	_triangle_base = value
	# When centered, adjust angle to reflect base change
	if _ramp_direction == RampDirection.CENTER and not _suspend_dependent_updates:
		var denom: float = max(_triangle_base, 0.0001)
		var new_angle: float = rad_to_deg(atan(2.0 * _triangle_height / denom))
		new_angle = clampf(new_angle, MIN_ANGLE, 89.0)
		_suspend_dependent_updates = true
		set("triangle_angle", new_angle)
		_suspend_dependent_updates = false
	_request_apply()

func _set_ramp_material(value: Material) -> void:
	_ramp_material = value
	_request_apply()

func _set_mode(value: RampPathMode) -> void:
	_mode = value
	_request_apply()

func _set_path_behavior(value: PathBehavior) -> void:
	_path_behavior = value
	_request_apply()

func _set_path_length(value: float) -> void:
	_path_length = value
	_request_apply()

func _set_path_height(value: float) -> void:
	_path_height = value
	_request_apply()

func _set_path_curvature(value: float) -> void:
	_path_curvature = clampf(value, 0.0, 1.0)
	_request_apply()

func _set_mirror_axis(value: MirrorAxis) -> void:
	_mirror_axis = value
	_request_apply()

func _set_mirror_offset(value: float) -> void:
	_mirror_offset = value
	_request_apply()

func _set_live_mirror(value: bool) -> void:
	_live_mirror = value
	_request_apply()

func _set_enable_clipping(value: bool) -> void:
	_enable_clipping = value
	_request_apply()

func _set_clip_shape(value: PackedVector2Array) -> void:
	_clip_shape = value
	_request_apply()

func _set_clip_operation(value: ClipOperation) -> void:
	_clip_operation = value
	_request_apply()

func _set_keep_trim(value: bool) -> void:
	_keep_trim = value
	_request_apply()

func _set_trim_material(value: Material) -> void:
	_trim_material = value
	_request_apply()

func _set_enable_caps(value: bool) -> void:
	_enable_caps = value
	_request_apply()

func _set_cap_shape(value: PackedScene) -> void:
	_cap_shape = value
	_request_apply()

func _set_cap_forward_axis(value: CapForwardAxis) -> void:
	_cap_forward_axis = value
	_request_apply()

func _set_cap_operation(value: CapOperation) -> void:
	_cap_operation = value
	_request_apply()

func _request_apply() -> void:
	_dirty = true

func _apply() -> void:
	_ensure_core_nodes()
	_update_polygon()
	_update_path()
	_apply_materials()
	_update_clipping_tree()
	_update_trim_material_target()
	_update_caps()
	_update_live_mirror()
	_update_curve_hash()

# Core node helpers
func _ensure_core_nodes() -> void:
	if not get_node_or_null("RampPath"):
		var p := Path3D.new()
		p.name = "RampPath"
		add_child(p)
		if Engine.is_editor_hint() and owner != null:
			p.owner = owner
	if not get_node_or_null("RampCSG"):
		var c := CSGPolygon3D.new()
		c.name = "RampCSG"
		c.operation = CSGPolygon3D.OPERATION_UNION
		c.mode = CSGPolygon3D.MODE_PATH
		c.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH
		c.path_local = true
		c.use_collision = true
		add_child(c)
		if Engine.is_editor_hint() and owner != null:
			c.owner = owner
	# Always ensure RampCSG is bound to the current RampPath (important after reload)
	var _path_node := get_node("RampPath") as Path3D
	var _ramp_csg := get_node("RampCSG") as CSGPolygon3D
	if _path_node and _ramp_csg:
		_ramp_csg.path_node = _ramp_csg.get_path_to(_path_node)

func _update_polygon() -> void:
	var ramp_csg := get_node("RampCSG") as CSGPolygon3D
	var pts: PackedVector2Array
	match _ramp_direction:
		RampDirection.CENTER:
			pts = PackedVector2Array([
				Vector2(-_triangle_base / 2.0, 0),
				Vector2(_triangle_base / 2.0, 0),
				Vector2(0, _triangle_height),
			])
		RampDirection.LEFT:
			pts = PackedVector2Array([
				Vector2(-_triangle_base, 0),
				Vector2(0, 0),
				Vector2(-_triangle_base, _triangle_height),
			])
		RampDirection.RIGHT:
			pts = PackedVector2Array([
				Vector2(0, 0),
				Vector2(_triangle_base, 0),
				Vector2(_triangle_base, _triangle_height),
			])
	ramp_csg.polygon = pts

func _update_path() -> void:
	var path_node := get_node("RampPath") as Path3D
	if _mode == RampPathMode.GENERATED:
		var curve := Curve3D.new()
		match _path_behavior:
			PathBehavior.STRAIGHT:
				curve.add_point(Vector3.ZERO)
				curve.add_point(Vector3(_path_length, 0, 0))
			PathBehavior.CURVE_UP:
				curve.add_point(Vector3.ZERO)
				curve.add_point(Vector3(_path_length * 0.5, _path_height * _path_curvature, 0))
				curve.add_point(Vector3(_path_length, _path_height, 0))
				var t_up := _path_curvature * 2.0
				curve.set_point_in(1, Vector3(-_path_length * 0.25 * t_up, -_path_height * 0.25 * t_up, 0))
				curve.set_point_out(1, Vector3(_path_length * 0.25 * t_up, _path_height * 0.25 * t_up, 0))
			PathBehavior.CURVE_DOWN:
				curve.add_point(Vector3.ZERO)
				curve.add_point(Vector3(_path_length * 0.5, -_path_height * _path_curvature, 0))
				curve.add_point(Vector3(_path_length, -_path_height, 0))
				var t_down := _path_curvature * 2.0
				curve.set_point_in(1, Vector3(-_path_length * 0.25 * t_down, _path_height * 0.25 * t_down, 0))
				curve.set_point_out(1, Vector3(_path_length * 0.25 * t_down, -_path_height * 0.25 * t_down, 0))
			PathBehavior.CURVE_LEFT:
				curve.add_point(Vector3.ZERO)
				curve.add_point(Vector3(_path_length * 0.5, 0, -_path_height * _path_curvature))
				curve.add_point(Vector3(_path_length, 0, -_path_height))
				var t_left := _path_curvature * 2.0
				curve.set_point_in(1, Vector3(-_path_length * 0.25 * t_left, 0, _path_height * 0.25 * t_left))
				curve.set_point_out(1, Vector3(_path_length * 0.25 * t_left, 0, -_path_height * 0.25 * t_left))
			PathBehavior.CURVE_RIGHT:
				curve.add_point(Vector3.ZERO)
				curve.add_point(Vector3(_path_length * 0.5, 0, _path_height * _path_curvature))
				curve.add_point(Vector3(_path_length, 0, _path_height))
				var t_right := _path_curvature * 2.0
				curve.set_point_in(1, Vector3(-_path_length * 0.25 * t_right, 0, -_path_height * 0.25 * t_right))
				curve.set_point_out(1, Vector3(_path_length * 0.25 * t_right, 0, _path_height * 0.25 * t_right))
		path_node.curve = curve

func _apply_materials() -> void:
	var ramp_csg := get_node("RampCSG") as CSGPolygon3D
	ramp_csg.material = _ramp_material

func _update_clipping_tree() -> void:
	var ramp_csg := get_node("RampCSG") as CSGPolygon3D
	if not _enable_clipping:
		var existing := ramp_csg.get_node_or_null("ClipCSG")
		if existing: existing.queue_free()
		var trim := get_node_or_null("Trim")
		if trim: trim.queue_free()
		return
	var clip := ramp_csg.get_node_or_null("ClipCSG") as CSGPolygon3D
	if not clip:
		clip = CSGPolygon3D.new()
		clip.name = "ClipCSG"
		clip.mode = CSGPolygon3D.MODE_PATH
		clip.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH
		clip.path_local = true
		clip.use_collision = false
		ramp_csg.add_child(clip)
		if Engine.is_editor_hint() and owner != null:
			clip.owner = owner
	clip.polygon = _clip_shape
	clip.operation = CSGPolygon3D.OPERATION_INTERSECTION if _clip_operation == ClipOperation.INTERSECTION else CSGPolygon3D.OPERATION_SUBTRACTION
	var path := get_node("RampPath") as Path3D
	# Rebind clip path node each apply to guard against broken NodePaths after reload
	clip.path_node = clip.get_path_to(path)
	if _keep_trim:
		_ensure_trim_subtree()
		_update_trim_subtree()
	else:
		var trim := get_node_or_null("Trim")
		if trim: trim.queue_free()

func _ensure_trim_subtree() -> void:
	if not get_node_or_null("Trim"):
		var t := Node3D.new()
		t.name = "Trim"
		add_child(t)
		if Engine.is_editor_hint() and owner != null:
			t.owner = owner
		var p := Path3D.new()
		p.name = "TrimPath"
		t.add_child(p)
		if Engine.is_editor_hint() and owner != null:
			p.owner = owner
		var c := CSGPolygon3D.new()
		c.name = "TrimCSG"
		c.operation = CSGPolygon3D.OPERATION_UNION
		c.mode = CSGPolygon3D.MODE_PATH
		c.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH
		c.path_local = true
		c.use_collision = false
		t.add_child(c)
		if Engine.is_editor_hint() and owner != null:
			c.owner = owner
		var cc := CSGPolygon3D.new()
		cc.name = "TrimClipCSG"
		cc.mode = CSGPolygon3D.MODE_PATH
		cc.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH
		cc.path_local = true
		cc.use_collision = false
		c.add_child(cc)
		if Engine.is_editor_hint() and owner != null:
			cc.owner = owner

func _update_trim_subtree() -> void:
	var trim := get_node("Trim") as Node3D
	var trim_path := trim.get_node("TrimPath") as Path3D
	var trim_csg := trim.get_node("TrimCSG") as CSGPolygon3D
	var trim_clip := trim_csg.get_node("TrimClipCSG") as CSGPolygon3D
	var ramp_path := get_node("RampPath") as Path3D
	var ramp_csg := get_node("RampCSG") as CSGPolygon3D
	if ramp_path.curve:
		trim_path.curve = ramp_path.curve.duplicate()
	trim_csg.polygon = ramp_csg.polygon
	# Rebind trim path nodes each apply to fix references after reload
	trim_csg.path_node = trim_csg.get_path_to(trim_path)
	trim_clip.operation = CSGPolygon3D.OPERATION_SUBTRACTION if _clip_operation == ClipOperation.INTERSECTION else CSGPolygon3D.OPERATION_INTERSECTION
	trim_clip.polygon = _clip_shape
	trim_clip.path_node = trim_clip.get_path_to(trim_path)


func _update_trim_material_target() -> void:
	if not _enable_clipping or not _trim_material:
		return
	if _keep_trim:
		var trim_csg := get_node_or_null("Trim/TrimCSG") as CSGPolygon3D
		if trim_csg:
			trim_csg.material = _trim_material
	else:
		var clip := (get_node("RampCSG") as CSGPolygon3D).get_node_or_null("ClipCSG") as CSGPolygon3D
		if clip:
			clip.material = _trim_material

# Helper: mark all CSG shapes in subtree as union and non-collidable
func _mark_csg_tree_union_no_collision(node: Node) -> void:
	if node is CSGShape3D:
		var csg := node as CSGShape3D
		csg.operation = CSGPolygon3D.OPERATION_UNION
		csg.use_collision = false
	for ch in node.get_children():
		_mark_csg_tree_union_no_collision(ch)

# Helper: get tangent at start or end of a Curve3D using handles with fallback to neighbor diff
func _get_curve_end_tangent(curve: Curve3D, at_start: bool) -> Vector3:
	var pc := curve.get_point_count()
	if pc == 0:
		return Vector3(1, 0, 0)
	if at_start:
		var t := curve.get_point_out(0)
		if t.length() < 0.0001 and pc >= 2:
			t = curve.get_point_position(1) - curve.get_point_position(0)
		return t.normalized()
	else:
		var last := pc - 1
		var t2 := -curve.get_point_in(last)
		if t2.length() < 0.0001 and pc >= 2:
			t2 = curve.get_point_position(last) - curve.get_point_position(last - 1)
		return t2.normalized()

# Helper: build a cap instance aligned at position and tangent (local space)
func _build_cap_instance_at(pos: Vector3, tangent: Vector3, is_end: bool = false, target_parent: Node3D = null) -> CSGShape3D:
	if not _cap_shape:
		return null
	var inst := _cap_shape.instantiate()
	if not (inst is CSGShape3D):
		return null
	var csg := inst as CSGShape3D
	_mark_csg_tree_union_no_collision(csg)
	# Build global transform that aligns X axis with the path tangent
	var path_node := get_node("RampPath") as Path3D
	var pos_global := path_node.to_global(pos)
	var dir_local := tangent.normalized()
	if dir_local.length() < 0.001:
		dir_local = Vector3(1,0,0)
	var dir_global := (path_node.global_transform.basis * dir_local).normalized()
	# Construct orthonormal basis aligned with forward-axis setting
	var x_axis := dir_global
	var tmp_up := Vector3.UP
	if abs(x_axis.dot(tmp_up)) > 0.99:
		tmp_up = Vector3.RIGHT
	var y_axis := (tmp_up - x_axis * (tmp_up.dot(x_axis))).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	var cap_basis := Basis(x_axis, y_axis, z_axis)
	match _cap_forward_axis:
		CapForwardAxis.X_PLUS:
			pass
		CapForwardAxis.X_MINUS:
			cap_basis = Basis(-x_axis, y_axis, -z_axis)
		CapForwardAxis.Y_PLUS:
			cap_basis = Basis(y_axis, -x_axis, z_axis)
		CapForwardAxis.Y_MINUS:
			cap_basis = Basis(-y_axis, x_axis, z_axis)
		CapForwardAxis.Z_PLUS:
			cap_basis = Basis(z_axis, y_axis, -x_axis)
		CapForwardAxis.Z_MINUS:
			cap_basis = Basis(-z_axis, y_axis, x_axis)
	# For the ending cap, rotate an additional 180 degrees around the cap's LOCAL up axis
	if is_end:
		var bx := cap_basis.x
		var by := cap_basis.y
		var bz := cap_basis.z
		cap_basis = Basis(-bx, by, -bz)
	# Compute local transform relative to the intended parent so moving the root does not misalign caps
	var parent_node := (target_parent if target_parent != null else (get_node("RampCSG") as Node3D))
	var global_xform := Transform3D(cap_basis, pos_global)
	var local_xform := parent_node.global_transform.affine_inverse() * global_xform
	csg.transform = local_xform
	return csg

# Cap shapes (subtractors at path ends)
func _update_caps() -> void:
	var ramp_csg := get_node("RampCSG") as CSGPolygon3D
	var caps_root := ramp_csg.get_node_or_null("Caps") as CSGCombiner3D
	if not _enable_caps or not _cap_shape:
		if caps_root:
			caps_root.queue_free()
		return
	if not caps_root:
		caps_root = CSGCombiner3D.new()
		caps_root.name = "Caps"
		ramp_csg.add_child(caps_root)
		if Engine.is_editor_hint() and owner != null:
			caps_root.owner = owner
	# clear previous children
	for c in caps_root.get_children():
		c.queue_free()
	# Apply combiner operation based on property
	match _cap_operation:
		CapOperation.UNION:
			caps_root.operation = CSGPolygon3D.OPERATION_UNION
		CapOperation.INTERSECTION:
			caps_root.operation = CSGPolygon3D.OPERATION_INTERSECTION
		CapOperation.SUBTRACTION:
			caps_root.operation = CSGPolygon3D.OPERATION_SUBTRACTION
	var path_node := get_node("RampPath") as Path3D
	var curve := path_node.curve if path_node else null
	if not curve or curve.get_point_count() == 0:
		return
	# start cap (local tangent-based)
	var start_pos := curve.get_point_position(0)
	var start_tangent: Vector3 = _get_curve_end_tangent(curve, true)
	var start_inst := _build_cap_instance_at(start_pos, start_tangent, false, caps_root)
	if start_inst:
		caps_root.add_child(start_inst)
		if Engine.is_editor_hint() and owner != null:
			start_inst.owner = owner
	# end cap
	var pc := curve.get_point_count()
	if pc >= 2:
		var end_pos := curve.get_point_position(pc - 1)
		var end_tangent: Vector3 = _get_curve_end_tangent(curve, false)
		var end_inst := _build_cap_instance_at(end_pos, end_tangent, true, caps_root)
		if end_inst:
			caps_root.add_child(end_inst)
			if Engine.is_editor_hint() and owner != null:
				end_inst.owner = owner

# Live mirror
func _update_live_mirror() -> void:
	if _mirror_axis == MirrorAxis.NONE or not _live_mirror:
		var lm := _get_live_mirror_node()
		if lm: lm.queue_free()
		return
	var live := _ensure_live_mirror()
	_copy_state_to_live_mirror(live)
	_set_mirrored_position_only(live)

func _get_live_mirror_node() -> RampGenerator:
	if not get_parent(): return null
	return get_parent().get_node_or_null(name + "_LiveMirror3") as RampGenerator

func _ensure_live_mirror() -> RampGenerator:
	var live := _get_live_mirror_node()
	if not live:
		live = RampGenerator.new()
		live.name = name + "_LiveMirror3"
		if get_parent():
			get_parent().add_child(live)
			if Engine.is_editor_hint() and owner != null:
				live.owner = owner
	return live

func _copy_state_to_live_mirror(live: RampGenerator) -> void:
	live.ramp_direction = _ramp_direction
	live.triangle_angle = _triangle_angle
	live.triangle_height = _triangle_height
	live.triangle_base = _triangle_base
	# Force MANUAL mode so we can reuse a mirrored curve
	live.mode = RampPathMode.MANUAL
	live.path_behavior = _path_behavior
	live.path_length = _path_length
	live.path_height = _path_height
	live.path_curvature = _path_curvature
	live.enable_clipping = _enable_clipping
	live.clip_shape = _clip_shape
	live.clip_operation = _clip_operation
	live.keep_trim = _keep_trim
	live.trim_material = _trim_material
	live.ramp_material = _ramp_material
	live.enable_caps = _enable_caps
	live.cap_shape = _cap_shape
	live.cap_operation = _cap_operation
	live.mirror_axis = MirrorAxis.NONE
	live.live_mirror = false
	# Assign mirrored curve
	var src_path := get_node("RampPath") as Path3D
	var dst_path := live.get_node_or_null("RampPath") as Path3D
	if src_path and src_path.curve and dst_path:
		dst_path.curve = _build_mirrored_curve(src_path.curve, _mirror_axis)
	live._request_apply()

func _set_mirrored_position_only(n: Node3D) -> void:
	var pos := position
	match _mirror_axis:
		MirrorAxis.X_AXIS: pos.x = -position.x - _mirror_offset
		MirrorAxis.Y_AXIS: pos.y = -position.y - _mirror_offset
		MirrorAxis.Z_AXIS: pos.z = -position.z - _mirror_offset
	n.position = pos
	n.scale = Vector3(1,1,1)

func _build_mirrored_curve(curve: Curve3D, axis: MirrorAxis) -> Curve3D:
	var nc := Curve3D.new()
	for i in range(curve.get_point_count()):
		var p := curve.get_point_position(i)
		var pin := curve.get_point_in(i)
		var pout := curve.get_point_out(i)
		match axis:
			MirrorAxis.X_AXIS:
				p.x = -p.x; pin.x = -pin.x; pout.x = -pout.x
			MirrorAxis.Y_AXIS:
				p.y = -p.y; pin.y = -pin.y; pout.y = -pout.y
			MirrorAxis.Z_AXIS:
				p.z = -p.z; pin.z = -pin.z; pout.z = -pout.z
		nc.add_point(p, pin, pout)
	return nc

# Curve change detection
func _update_curve_hash() -> void:
	var path_node := get_node("RampPath") as Path3D
	if not path_node or not path_node.curve:
		_last_curve_hash = 0
		return
	var h := 0
	for i in range(path_node.curve.get_point_count()):
		var p := path_node.curve.get_point_position(i)
		var pin := path_node.curve.get_point_in(i)
		var pout := path_node.curve.get_point_out(i)
		h = h * 31 + int(p.x * 997) + int(p.y * 991) + int(p.z * 983)
		h = h * 31 + int(pin.x * 197) + int(pin.y * 193) + int(pin.z * 191)
		h = h * 31 + int(pout.x * 157) + int(pout.y * 151) + int(pout.z * 149)
	_last_curve_hash = h

func _update_live_mirror_curve_if_changed() -> void:
	var old := _last_curve_hash
	_update_curve_hash()
	if old != _last_curve_hash:
		var live := _get_live_mirror_node()
		if live:
			var src := get_node("RampPath") as Path3D
			var dst := live.get_node_or_null("RampPath") as Path3D
			if src and src.curve and dst:
				dst.curve = _build_mirrored_curve(src.curve, _mirror_axis)
				live._request_apply()

func _update_caps_curve_if_changed() -> void:
	var old := _last_curve_hash
	_update_curve_hash()
	if old != _last_curve_hash and _enable_caps:
		_update_caps()
