class_name GSS
extends Node

const DATA_TYPE_UNKNOWN: int = -1
const DEFAULT_COLOR: Color = Color.WHITE

const REGEX_COLOR: String = r"(?:Color\.([A-Z_]+))|(?:Color\(([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\))|(?:#?([A-Fa-f0-9]{3}(?:[A-Fa-f0-9]{3})?(?:[A-Fa-f0-9]{2})?))"
const REGEX_COMMENT: String = r"(?m)(^[ \t]*#+(?![a-fA-F0-9]).*$|[ \t]*#+(?![a-fA-F0-9]).*$)"
const REGEX_PIXEL_SIZE: String = r"^\d+(\.\d+)?px$"
const REGEX_GSS_PROPERTY: String = r"(\w+)\s*:\s*(?:\"?([^\";\n]+)\"?;?|([^;\n]+))"
const REGEX_GSS_THEME_TYPE: String = r"(\w+)(?:\(([^)]*)\))?"
const REGEX_THEME_OVERRIDE: String = r"theme_override_([a-z_]+)/([a-z_]+)"
const REGEX_VECTOR2: String = r"Vector2?i?\s*\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)"

static var regex: Dictionary = {
	"color": RegEx.create_from_string(REGEX_COLOR),
	"comment": RegEx.create_from_string(REGEX_COMMENT),
	"gss_property": RegEx.create_from_string(REGEX_GSS_PROPERTY),
	"gss_theme_type": RegEx.create_from_string(REGEX_GSS_THEME_TYPE),
	"pixel_size": RegEx.create_from_string(REGEX_PIXEL_SIZE),
	"theme_override": RegEx.create_from_string(REGEX_THEME_OVERRIDE),
	"vector2": RegEx.create_from_string(REGEX_VECTOR2),
}

static var theme_property_types: Dictionary = {
	"colors": Theme.DATA_TYPE_COLOR,
	"constants": Theme.DATA_TYPE_CONSTANT,
	"fonts": Theme.DATA_TYPE_FONT,
	"font_sizes": Theme.DATA_TYPE_FONT_SIZE,
	"icons": Theme.DATA_TYPE_ICON,
	"styles": Theme.DATA_TYPE_STYLEBOX,
}


static func file_to_dict(path: String) -> Dictionary:
	var gss_file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var gss: String = gss_file.get_as_text()
	
	return _parse_gss(gss)


static func file_to_theme(path: String) -> Theme:
	var theme := Theme.new()
	var gss: Dictionary = file_to_dict(path)
	
	# Loop through each key in the GSS dictionary.
	for key in gss.keys():
		var props: Dictionary = gss[key]
		
		# The `key` will be something like "TextEdit", "Button:pressed", or "default".
		var theme_type: String = key.get_slice(":", 0)
		var theme_props: Dictionary = _get_theme_property_types(theme_type)
		
		# Theme type styles (e.g. "pressed", "hover") appears after the `:`, if present.
		var style: String = key.get_slice(":", 1) if ":" in key else "normal"
		
		if not style in theme_props.keys() or Theme.DATA_TYPE_STYLEBOX != theme_props[style]:
			push_warning("[GSS] Invalid theme type style: %s")
			continue
		
		# Instantiate a new StyleBox that can have properties applied to it.
		var stylebox_type: String = props.get("stylebox", "StyleBoxFlat")
		var stylebox = ClassDB.instantiate(stylebox_type)
		var stylebox_props: Dictionary = _get_stylebox_property_types(stylebox_type)
		
		# Loop through each key/value pair in the current GSS property array.
		for prop: String in props.keys():
			var value: String = props[prop]
			var data_type: int = theme_props.get(prop, DATA_TYPE_UNKNOWN)
			
			if DATA_TYPE_UNKNOWN == data_type:
				_set_stylebox_property(stylebox, stylebox_props, prop, theme_type, value)
			else:
				_set_theme_property(theme, data_type, prop, theme_type, value)
					
		
		theme.set_stylebox(style, theme_type, stylebox)
	
	return theme


static func file_to_tres(path: String, output_path: String = "") -> String:
	var theme: Theme = file_to_theme(path)
	
	if !output_path:
		output_path = "%s.tres" % path.trim_suffix(".txt")
	
	ResourceSaver.save(theme, output_path)
	
	return output_path


## Returns an array of keys from `props` that are prefixed with the given key. For example, if
## the given `props` dictionary contained the Button theme properties, and "border_width" was
## the given `key` parameter, this function would return:
## ["border_width_bottom", "border_width_left", "border_width_right", "border_width_top"]
static func _get_property_group(props: Dictionary, key: String) -> Array:
	return props.keys().filter(func(k): return k != key and k.begins_with(key))


static func _get_class_property_types(cls: Variant, no_inheritance: bool = false) -> Dictionary:
	var result: Dictionary = {}
	
	if !ClassDB.class_exists(cls):
		push_warning("[GSS] Class does not exist: %s" % cls)
		return result
	
	var props: Array[Dictionary] = ClassDB.class_get_property_list(cls, no_inheritance)
	
	for prop in props:
		var key: String = prop["name"]
		var value: int = prop["type"]
		result[key] = value
	
	return result


static func _get_classes_with_theme_properties() -> Array:
	var classes_with_theme: Array = []
	var all_classes: PackedStringArray = ClassDB.get_class_list()
	
	for _class_name: String in all_classes:
		if _has_theme_properties(_class_name):
			classes_with_theme.append(_class_name)
	
	return classes_with_theme


static func _get_stylebox_property_types(cls: String) -> Dictionary:
	var no_inheritance: bool = true
	var result: Dictionary = _get_class_property_types(cls, no_inheritance)
	
	if "StyleBox" != cls:
		result.merge(_get_class_property_types("StyleBox", no_inheritance))
	
	return result


static func _get_theme_property_types(theme_type: String) -> Dictionary:
	var result: Dictionary = {}
	
	if !ClassDB.class_exists(theme_type):
		push_warning("[GSS] Class does not exist: %s" % theme_type)
		return result
	
	var temp_instance: Variant = ClassDB.instantiate(theme_type)
	var props: Array[Dictionary] = temp_instance.get_property_list()
	
	if temp_instance is Object:
		temp_instance.free()
	
	for prop: Dictionary in props:
		var _match: RegExMatch = regex.theme_override.search(prop.name)
		
		if !_match:
			continue
		
		var key: String = _match.get_string(2)
		var value: int = theme_property_types.get(_match.get_string(1), DATA_TYPE_UNKNOWN)
		
		result[key] = value
	
	return result


static func _has_theme_properties(_class_name: String) -> bool:
	var properties: Array[Dictionary] = ClassDB.class_get_property_list(_class_name)
	
	for property: Dictionary in properties:
		if property["name"] == "theme":
			return true
	
	return false


static func _parse_bool(text: String) -> bool:
	if !text:
		return false
	
	text = text.to_lower().strip_edges()
	
	if text in ["false", "0"]:
		return false
	
	return true


static func _parse_color(text: String) -> Color:
	var _match: RegExMatch = regex.color.search(text)
	
	if !_match:
		push_warning("[GSS] Invalid Color value: %s" % text)
		return DEFAULT_COLOR
	
	# Handle values like "Color.RED"
	if _match.get_string(1):
		return Color.from_string(_match.get_string(1), DEFAULT_COLOR)
	
	# Handle values like "Color(0.2, 1.0, 0.7, 0.8)"
	if _match.get_string(2):
		var r := float(_match.get_string(2))
		var g := float(_match.get_string(3))
		var b := float(_match.get_string(4))
		var a := float(_match.get_string(5))
		return Color(r, g, b, a)
	
	# Handle values like "#55aaFF", "#55AAFF20", "55AAFF", or "#F2C"
	if _match.get_string(6):
		return Color.from_string(_match.get_string(6), DEFAULT_COLOR)
	
	return DEFAULT_COLOR


static func _parse_constant(value: String) -> int:
	return value as int


static func _parse_font(value: String) -> Font:
	return load(value)


static func _parse_font_size(value: String) -> int:
	return value as int


static func _parse_gss(raw_text: String) -> Dictionary:
	var text: String = _strip_comments(raw_text)
	var lines: PackedStringArray = text.split("\n")
	var styles: Dictionary = {}
	var theme_type: String = ""
	
	for i: int in range(lines.size()):
		var line: String = lines[i].strip_edges()
		
		if !line:
			continue  # Ignore blank lines.
		
		var is_indented: bool = lines[i].substr(0, 1) == "\t"
		
		if is_indented:
			_parse_gss_property(line, styles, theme_type)
		else:
			theme_type = _parse_gss_theme_type(line, styles)
	
	return styles


static func _parse_gss_property(text: String, styles: Dictionary, theme_type: String) -> void:
	var _match: RegExMatch = regex.gss_property.search(text)
	
	if !_match:
		return
	
	var prop_key: String = _match.strings[1]
	var prop_value: String = _match.strings[2]
	
	if regex.pixel_size.search(prop_value):
		prop_value = prop_value.trim_suffix("px")
	
	styles[theme_type][prop_key] = prop_value


static func _parse_gss_theme_type(text: String, styles: Dictionary) -> String:
	var _match: RegExMatch = regex.gss_theme_type.search(text)
	
	if !_match:
		return ""
	
	var theme_type: String = _match.strings[1]
	var theme_type_style: String = _match.strings[2]
	
	if theme_type_style:
		theme_type += ":%s" % theme_type_style
	
	if !styles.has(theme_type):
		styles[theme_type] = {}
	
	return theme_type


static func _parse_icon(value: String) -> Texture2D:
	return load(value)


static func _parse_stylebox_property(prop: String, text: String, stylebox_props: Dictionary) -> Variant:
	if !stylebox_props.has(prop):
		push_warning("[GSS] Invalid StyleBox property: %s" % prop)
		return text
	
	match stylebox_props[prop]:
		TYPE_BOOL:
			return _parse_bool(text)
		
		TYPE_COLOR:
			return _parse_color(text)
		
		TYPE_FLOAT:
			return float(text)
		
		TYPE_INT:
			return int(text)
		
		TYPE_STRING:
			return text
		
		TYPE_VECTOR2:
			return _parse_vector2(text)
	
	push_warning("[GSS] No parser found for StyleBox property: %s" % prop)
	return text


static func _parse_vector2(text: String) -> Vector2:
	var _match: RegExMatch = regex.vector2.search(text)
	
	if !_match:
		push_warning("[GSS] Unable to parse Vector2 value from String: %s" % text)
		return Vector2.ZERO
	
	var x: int = _match.get_string(1) as int
	var y: int = _match.get_string(2) as int
	
	return Vector2(x, y)


static func _set_stylebox_property(
	stylebox: StyleBox,
	stylebox_props: Dictionary,
	prop: String,
	theme_type: String,
	value: String,
) -> void:
	if DATA_TYPE_UNKNOWN == stylebox_props.get(prop, DATA_TYPE_UNKNOWN):
		# If property does not appear in `stylebox_props`, it may be a group property
		# (e.g. "border_width", "corner_radius") that has multiple properties for top,
		# bottom, left, and right. If so, call this function recursively for each of
		# the properties prefixed with the group property name.
		for group_prop in _get_property_group(stylebox_props, prop):
			_set_stylebox_property(stylebox, stylebox_props, group_prop, theme_type, value)
	else:
		stylebox.set(prop, _parse_stylebox_property(prop, value, stylebox_props))


static func _set_theme_property(
	theme: Theme,
	data_type: int,
	prop: String,
	theme_type: String,
	value: String,
) -> void:
	match data_type:
		Theme.DATA_TYPE_COLOR:
			theme.set_color(prop, theme_type, _parse_color(value))
		
		Theme.DATA_TYPE_CONSTANT:
			theme.set_constant(prop, theme_type, _parse_constant(value))
		
		Theme.DATA_TYPE_FONT:
			theme.set_font(prop, theme_type, _parse_font(value))
		
		Theme.DATA_TYPE_FONT_SIZE:
			theme.set_font_size(prop, theme_type, _parse_font_size(value))
		
		Theme.DATA_TYPE_ICON:
			theme.set_icon(prop, theme_type, _parse_icon(value))


static func _strip_comments(text: String) -> String:
	return regex.comment.sub(text, '', true)
