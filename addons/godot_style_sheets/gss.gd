class_name GSS
extends Node

## Used to indicate that a GSS property is not a Theme.DATA_TYPE_* property and is most likely a StyleBox property.
const DATA_TYPE_UNKNOWN: int = -1

## Used when parsing a Color value from a GSS file, because `Color.from_string()` requires a default value.
const DEFAULT_COLOR: Color = Color.WHITE

## RegEx pattern for identifying Color values. Matches values like "Color.RED" in the first capture group; "0.2",
## "1.0", "0.7", and "0.8" from "Color(0.2, 1.0, 0.7, 0.8)" in the second through fifth capture groups; and
## "#55aaFF", "#55AAFF20", "55AAFF", or "#F2C" in the sixth capture group.
const REGEX_COLOR: String = r"(?:Color\.([A-Z_]+))|(?:Color\(([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\))|(?:#?([A-Fa-f0-9]{3}(?:[A-Fa-f0-9]{3})?(?:[A-Fa-f0-9]{2})?))"

## RegEx pattern for identifying Godot-style comments (i.e. that begin with `#`).
const REGEX_COMMENT: String = r"(?m)(^[ \t]*#+(?![a-fA-F0-9]).*$|[ \t]*#+(?![a-fA-F0-9]).*$)"

## RegEx pattern for identifying pixel size values. Matches values like "12" from "12px"; or "0.5" from "0.5px".
const REGEX_PIXEL_SIZE: String = r"^\d+(\.\d+)?px$"

## RegEx pattern for identifying GSS properties in a GSS file. Matches values like "font" and "res://font.tres" from
## 'font: "res://font.tres"'; or "color" and "Color.RED" from "color: Color.RED;". Ignores trailing semicolons.
const REGEX_GSS_PROPERTY: String = r"(\w+)\s*:\s*(?:\"?([^\";\n]+)\"?;?|([^;\n]+))"

## RegEx pattern for identifying GSS theme types in a GSS file. Matches values like "Button" and "pressed" from
## "Button(pressed):"; or "TextEdit" and "" from "TextEdit:".
const REGEX_GSS_THEME_TYPE: String = r"(\w+)(?:\(([^)]*)\))?"

## RegEx pattern for identifying theme override properties. Matches values like "colors" and "TextEdit" from
## "theme_override_colors/TextEdit"; or "fonts" and "font" from "theme_override_fonts/font".
const REGEX_THEME_OVERRIDE: String = r"theme_override_([a-z_]+)/([a-z_]+)"

## RegEx pattern for identifying Vector2 values. Matches values like "5" and "20" from "Vector2(5, 20)";
## or "-20" and "100" from "Vector2(-20, 100)".
const REGEX_VECTOR2: String = r"Vector2?i?\s*\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)"

## Dictionary of RegEx objects used to match patterns.
static var regex: Dictionary = {
	"color": RegEx.create_from_string(REGEX_COLOR),
	"comment": RegEx.create_from_string(REGEX_COMMENT),
	"gss_property": RegEx.create_from_string(REGEX_GSS_PROPERTY),
	"gss_theme_type": RegEx.create_from_string(REGEX_GSS_THEME_TYPE),
	"pixel_size": RegEx.create_from_string(REGEX_PIXEL_SIZE),
	"theme_override": RegEx.create_from_string(REGEX_THEME_OVERRIDE),
	"vector2": RegEx.create_from_string(REGEX_VECTOR2),
}

## Dictionary of `theme_override_*` keys and their corresponding Theme.DATA_TYPE_* integer values.
static var theme_property_types: Dictionary = {
	"colors": Theme.DATA_TYPE_COLOR,
	"constants": Theme.DATA_TYPE_CONSTANT,
	"fonts": Theme.DATA_TYPE_FONT,
	"font_sizes": Theme.DATA_TYPE_FONT_SIZE,
	"icons": Theme.DATA_TYPE_ICON,
	"styles": Theme.DATA_TYPE_STYLEBOX,
}


## Converts a GSS file to a Dictionary that can be parsed into a Theme.
static func file_to_dict(path: String) -> Dictionary:
	var gss_file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var gss: String = gss_file.get_as_text()
	
	return _parse_gss(gss)


## Converts a GSS file to a Theme object.
static func file_to_theme(path: String) -> Theme:
	var theme := Theme.new()
	var gss: Dictionary = file_to_dict(path)
	
	# Loop through each key in the GSS dictionary.
	for key in gss.keys():
		var props: Dictionary = gss[key]
		
		# The `key` will be something like "TextEdit" or "Button:pressed".
		var theme_type: String = key.get_slice(":", 0)
		var theme_props: Dictionary = _get_theme_property_types(theme_type)
		
		# Theme type style (e.g. "pressed", "hover") appears after the `:`, if present.
		var style: String = key.get_slice(":", 1) if ":" in key else "normal"
		
		if !_is_valid_style(style, theme_props):
			push_warning("[GSS] Invalid theme type style: %s")
			continue
		
		# Instantiate a new StyleBox that can have properties applied to it.
		var stylebox_type: String = props.get("stylebox", "StyleBoxFlat")
		var stylebox = ClassDB.instantiate(stylebox_type)
		var stylebox_props: Dictionary = _get_stylebox_property_types(stylebox_type)
		
		# Loop through each property in the GSS dictionary.
		for prop: String in props.keys():
			var value: String = props[prop]
			var data_type: int = theme_props.get(prop, DATA_TYPE_UNKNOWN)
			
			if DATA_TYPE_UNKNOWN == data_type:
				_set_stylebox_property(stylebox, stylebox_props, prop, theme_type, value)
			else:
				_set_theme_property(theme, data_type, prop, theme_type, value)
					
		# Apply the StyleBox to the Theme.
		theme.set_stylebox(style, theme_type, stylebox)
	
	return theme


## Converts a GSS file to a Theme object and saves it to a `.tres` resource file.
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


## Returns a dictionary of property names and their corresponding data types for the given class.
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


## Returns an array of all class names that have theme properties.
static func _get_classes_with_theme_properties() -> Array:
	var classes_with_theme: Array = []
	var all_classes: PackedStringArray = ClassDB.get_class_list()
	
	for _class_name: String in all_classes:
		if _has_theme_properties(_class_name):
			classes_with_theme.append(_class_name)
	
	return classes_with_theme


## Returns a dictionary of property names and their corresponding data types for the given StyleBox class.
static func _get_stylebox_property_types(cls: String) -> Dictionary:
	var no_inheritance: bool = true
	var result: Dictionary = _get_class_property_types(cls, no_inheritance)
	
	if "StyleBox" != cls:
		result.merge(_get_class_property_types("StyleBox", no_inheritance))
	
	return result


## Returns a dictionary of `theme_override_*` property names and their corresponding data types.
static func _get_theme_property_types(theme_type: String) -> Dictionary:
	var result: Dictionary = {}
	
	if !ClassDB.class_exists(theme_type):
		push_warning("[GSS] Class does not exist: %s" % theme_type)
		return result
	
	# The array returned by `ClassDB.class_get_property_list()` does not include `theme_override_*`
	# properties, so we need to instantiate the class to get them.
	var temp_instance: Variant = ClassDB.instantiate(theme_type)
	var props: Array[Dictionary] = temp_instance.get_property_list()
	
	# Release the temporary instance from memory, if it is an Object.
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


## Returns `true` if the given class has a `theme` property.
static func _has_theme_properties(_class_name: String) -> bool:
	var properties: Array[Dictionary] = ClassDB.class_get_property_list(_class_name)
	
	for property: Dictionary in properties:
		if property.name == "theme":
			return true
	
	return false


## Returns `true` if the given style is a valid StyleBox property.
static func _is_valid_style(style: String, theme_props: Dictionary) -> bool:
	return style in theme_props.keys() and Theme.DATA_TYPE_STYLEBOX == theme_props[style]


## Parses a boolean value from a string.
static func _parse_bool(text: String) -> bool:
	if !text:
		return false
	
	text = text.to_lower().strip_edges()
	
	if text in ["false", "0"]:
		return false
	
	return true


## Parses a Color value from a string.
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


## Parses a theme constant value (i.e. an integer) from a string.
static func _parse_constant(value: String) -> int:
	return value as int


## Parses a Font value from a string by loading the font resource from the given path.
static func _parse_font(value: String) -> Font:
	return load(value)


## Parses a font size value (i.e. an integer) from a string.
static func _parse_font_size(value: String) -> int:
	return value as int


## Parses the contents of a GSS file as a dictionary.
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
			# If the line is indented, treat it as a property of the previous theme type.
			_parse_gss_property(line, styles, theme_type)
		else:
			# If the line is not indented, treat it as a new theme type.
			theme_type = _parse_gss_theme_type(line, styles)
	
	return styles


## Parses a GSS property and adds it to the given `styles` dictionary.
static func _parse_gss_property(text: String, styles: Dictionary, theme_type: String) -> void:
	var _match: RegExMatch = regex.gss_property.search(text)
	
	if !_match:
		return
	
	var prop_key: String = _match.strings[1]
	var prop_value: String = _match.strings[2]

	# If the property value is a pixel size, remove the "px" suffix.
	if regex.pixel_size.search(prop_value):
		prop_value = prop_value.trim_suffix("px")
	
	styles[theme_type][prop_key] = prop_value


## Parses a GSS theme type and adds it to the given `styles` dictionary. Returns the theme type.
static func _parse_gss_theme_type(text: String, styles: Dictionary) -> String:
	var _match: RegExMatch = regex.gss_theme_type.search(text)
	
	if !_match:
		return ""
	
	var theme_type: String = _match.strings[1]
	var theme_type_style: String = _match.strings[2]

	# Append the style to the theme type, if present.
	if theme_type_style:
		theme_type += ":%s" % theme_type_style

	# Initialize the theme type in the `styles` dictionary, if it does not already exist.
	if !styles.has(theme_type):
		styles[theme_type] = {}
	
	return theme_type


## Parses an icon value from a string by loading the icon resource from the given path.
static func _parse_icon(value: String) -> Texture2D:
	return load(value)


## Parses a StyleBox property value from a string, based on the property type.
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


## Parses a Vector2 value from a string.
static func _parse_vector2(text: String) -> Vector2:
	var _match: RegExMatch = regex.vector2.search(text)
	
	if !_match:
		push_warning("[GSS] Unable to parse Vector2 value from String: %s" % text)
		return Vector2.ZERO
	
	var x: int = _match.get_string(1) as int
	var y: int = _match.get_string(2) as int
	
	return Vector2(x, y)


## Sets a property on the given StyleBox. If the property is not found in the `stylebox_props` dictionary,
## it may be a group property (e.g. "border_width", "corner_radius") that has multiple properties (e.g.
## "border_width_top", "border_width_bottom"). If so, this function will call itself recursively for each
## of the properties prefixed with the group property name.
static func _set_stylebox_property(
	stylebox: StyleBox,
	stylebox_props: Dictionary,
	prop: String,
	theme_type: String,
	value: String,
) -> void:
	if DATA_TYPE_UNKNOWN == stylebox_props.get(prop, DATA_TYPE_UNKNOWN):
		for group_prop in _get_property_group(stylebox_props, prop):
			_set_stylebox_property(stylebox, stylebox_props, group_prop, theme_type, value)
	else:
		stylebox.set(prop, _parse_stylebox_property(prop, value, stylebox_props))


## Sets a property on the given Theme, based on the property type.
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


## Strips comments from the given text.
static func _strip_comments(text: String) -> String:
	return regex.comment.sub(text, '', true)
