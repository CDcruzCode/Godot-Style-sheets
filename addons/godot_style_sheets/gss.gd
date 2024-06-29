class_name GSS
extends Node

const DATA_TYPE_COLOR: int = Theme.DATA_TYPE_COLOR
const DATA_TYPE_CONSTANT: int = Theme.DATA_TYPE_CONSTANT
const DATA_TYPE_FONT: int = Theme.DATA_TYPE_FONT
const DATA_TYPE_FONT_SIZE: int = Theme.DATA_TYPE_FONT_SIZE
const DATA_TYPE_ICON: int = Theme.DATA_TYPE_ICON
const DATA_TYPE_STYLEBOX: int = Theme.DATA_TYPE_STYLEBOX
const DATA_TYPE_GROUP: int = Theme.DATA_TYPE_MAX + 1

static var class_pattern := RegEx.create_from_string(r"(\w+)(?:\(([^)]*)\))?")
static var comment_pattern := RegEx.create_from_string(r"(?m)^[ \t]*#+(?![a-fA-F0-9]).*$")
static var property_pattern := RegEx.create_from_string(r"(\w+)\s*:\s*(?:\"?([^\";\n]+)\"?;?|([^;\n]+))")
static var pixel_size_pattern := RegEx.create_from_string(r"^\d+(\.\d+)?px$")

static var property_map: Dictionary = {
	"anti_aliasing": {"type": DATA_TYPE_STYLEBOX},
	"anti_aliasing_size": {"type": DATA_TYPE_STYLEBOX},
	"align_to_largest_stylebox": {"type": DATA_TYPE_CONSTANT},
	"bg_color": {"type": DATA_TYPE_STYLEBOX},
	"border_blend": {"type": DATA_TYPE_STYLEBOX},
	"border_width": {"type": DATA_TYPE_GROUP},
	"border_width_bottom": {"type": DATA_TYPE_STYLEBOX},
	"border_width_left": {"type": DATA_TYPE_STYLEBOX},
	"border_width_right": {"type": DATA_TYPE_STYLEBOX},
	"border_width_top": {"type": DATA_TYPE_STYLEBOX},
	"corner_detail": {"type": DATA_TYPE_STYLEBOX},
	"corner_radius": {"type": DATA_TYPE_GROUP},
	"corner_radius_bottom_left": {"type": DATA_TYPE_STYLEBOX},
	"corner_radius_bottom_right": {"type": DATA_TYPE_STYLEBOX},
	"corner_radius_top_left": {"type": DATA_TYPE_STYLEBOX},
	"corner_radius_top_right": {"type": DATA_TYPE_STYLEBOX},
	"draw_center": {"type": DATA_TYPE_STYLEBOX},
	"expand_margin": {"type": DATA_TYPE_GROUP},
	"expand_margin_bottom": {"type": DATA_TYPE_STYLEBOX},
	"expand_margin_left": {"type": DATA_TYPE_STYLEBOX},
	"expand_margin_right": {"type": DATA_TYPE_STYLEBOX},
	"expand_margin_top": {"type": DATA_TYPE_STYLEBOX},
	"font": {"type": DATA_TYPE_FONT},
	"font_color": {"type": DATA_TYPE_COLOR},
	"font_disabled_color": {"type": DATA_TYPE_COLOR},
	"font_focus_color": {"type": DATA_TYPE_COLOR},
	"font_hover_color": {"type": DATA_TYPE_COLOR},
	"font_hover_pressed_color": {"type": DATA_TYPE_COLOR},
	"font_outline_color": {"type": DATA_TYPE_COLOR},
	"font_pressed_color": {"type": DATA_TYPE_COLOR},
	"font_size": {"type": DATA_TYPE_FONT_SIZE},
	"h_separation": {"type": DATA_TYPE_CONSTANT},
	"icon": {"type": DATA_TYPE_ICON},
	"icon_disabled_color": {"type": DATA_TYPE_COLOR},
	"icon_focus_color": {"type": DATA_TYPE_COLOR},
	"icon_hover_color": {"type": DATA_TYPE_COLOR},
	"icon_hover_pressed_color": {"type": DATA_TYPE_COLOR},
	"icon_max_width": {"type": DATA_TYPE_CONSTANT},
	"icon_normal_color": {"type": DATA_TYPE_COLOR},
	"icon_pressed_color": {"type": DATA_TYPE_COLOR},
	"outline_size": {"type": DATA_TYPE_CONSTANT},
	"shadow_color": {"type": DATA_TYPE_STYLEBOX},
	"shadow_offset": {"type": DATA_TYPE_STYLEBOX},
	"shadow_size": {"type": DATA_TYPE_STYLEBOX},
}

static var stylebox_keys: Array[String] = [
	"disabled",
	"disabled_mirrored",
	"focus",
	"hover",
	"hover_mirrored",
	"hover_pressed",
	"hover_pressed_mirrored",
	"normal",
	"normal_mirrored",
	"pressed",
	"pressed_mirrored",
]


static func file_to_dict(path: String) -> Dictionary:
	var gss_file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var gss: String = gss_file.get_as_text()
	
	return text_to_dict(strip_comments(gss))


static func file_to_theme(path: String) -> Theme:
	var theme := Theme.new()
	var styles: Dictionary = file_to_dict(path)
	
	for key in styles.keys():
		var cls: String = key.get_slice(":", 0)
		var stylebox_key: String = key.substr(cls.length() + 1)
		var rules: Array = styles[key]
		
		if !stylebox_key:
			stylebox_key = "normal"
		
		# TODO: Add the theme item if it has not yet been added, based on type.
		
		for rule in rules:
			var prop: String = rule.get_slice(":", 0)
			var value: String = rule.substr(prop.length() + 1)
			var meta: Dictionary = property_map[prop] if property_map.has(prop) else {}
			
			if !meta:
				continue
			
			# TODO: Set the property values for Control properties.
			# TODO: Set the property values for StyleBox properties, using StyleBoxFlat.
			prints(meta["type"], value)
	
	return theme


static func file_to_tres(path: String, output_path: String = "") -> void:
	var theme: Theme = file_to_theme(path)
	
	if !output_path:
		output_path = "%s.tres" % path.trim_suffix(".txt")
	
	ResourceSaver.save(theme, output_path)


static func strip_comments(text: String) -> String:
	return comment_pattern.sub(text, '', true)


static func text_to_dict(gss: String) -> Dictionary:
	var lines: PackedStringArray = gss.split("\n")
	var styles: Dictionary = {}
	var key: String = ""
	
	for i: int in range(lines.size()):
		var line: String = lines[i].strip_edges()
		
		# Ignore blank lines.
		if !line:
			continue
		
		var is_indented: bool = lines[i].substr(0, 1) == "\t"
		var property_match: RegExMatch
		
		# If the line starts with a tab character, treat it as a property.
		if is_indented:
			property_match = property_pattern.search(line)
		
		# If the line has the format `key: value`, add it to the `styles` dictionary.
		if property_match:
			var prop_key: String = property_match.strings[1]
			var prop_value: String = property_match.strings[2]
			
			# Check if value is a pixel size with `px` suffix.
			if pixel_size_pattern.search(prop_value):
				prop_value = prop_value.trim_suffix("px")
			
			# Add the key/value pair to the current `key` array in the `styles` dictionary.
			styles[key].append({prop_key: prop_value})
			continue
			
		var class_match: RegExMatch = class_pattern.search(line)
		
		# If the line does not start with a tab character, treat it as a class.
		if !is_indented and class_match:
			key = class_match.strings[1]
			
			# If there is a state (e.g. disabled, hover, pressed), add that to the class name.
			if class_match.strings[2]:
				key += ":%s" % class_match.strings[2]
			
			# If the key does not yet exist in the `styles` dictionary, add it.
			if !styles.has(key):
				styles[key] = []
	
	return styles


static func _create_theme() -> Theme:
	# Create a new Theme
	var theme = Theme.new()
	
	# Create a new StyleBoxFlat for normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.8, 0.8, 0.8)
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_right = 5
	normal_style.corner_radius_bottom_left = 5
	
	# Create a new StyleBoxFlat for hover state
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.3)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(1, 1, 1)
	hover_style.corner_radius_top_left = 5
	hover_style.corner_radius_top_right = 5
	hover_style.corner_radius_bottom_right = 5
	hover_style.corner_radius_bottom_left = 5
	
	# Set styles for Button
	theme.set_stylebox("normal", "Button", normal_style)
	theme.set_stylebox("hover", "Button", hover_style)
	
	# Set colors for Button
	theme.set_color("font_color", "Button", Color(1, 1, 1))
	theme.set_color("font_hover_color", "Button", Color(1, 0.8, 0.8))
	
	# Set font size for Button
	theme.set_font_size("font_size", "Button", 18)
	
	return theme
