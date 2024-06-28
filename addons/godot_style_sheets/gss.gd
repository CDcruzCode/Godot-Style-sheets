class_name GSS
extends Node

static var comment_pattern: RegEx = RegEx.create_from_string("\\/\\*[^*]*\\*+([^/*][^*]*\\*+)*\\/")

static var gss_property_map: Dictionary = {
	":active": [{"resource": "Control", "property": "%s/styles/pressed"}],
	":checked": [{"resource": "Control", "property": "%s/styles/pressed"}],
	":default": [{"resource": "Control", "property": "%s/styles/normal"}],
	":disabled": [{"resource": "Control", "property": "%s/styles/disabled"}],
	":focus": [{"resource": "Control", "property": "%s/styles/focus"}],
	":hover": [{"resource": "Control", "property": "%s/styles/hover"}],
	"background-color": [{"resource": "StyleBox", "property": "bg_color"}],
	"border-radius": [
		{"resource": "StyleBox", "property": "corner_radius_top_left"},
		{"resource": "StyleBox", "property": "corner_radius_top_right"},
		{"resource": "StyleBox", "property": "corner_radius_bottom_right"},
		{"resource": "StyleBox", "property": "corner_radius_bottom_left"},
	],
	"border-top-left-radius": [{"resource": "StyleBox", "property": "corner_radius_top_left"}],
	"border-top-right-radius": [{"resource": "StyleBox", "property": "corner_radius_top_right"}],
	"border-bottom-left-radius": [{"resource": "StyleBox", "property": "corner_radius_bottom_left"}],
	"border-bottom-right-radius": [
		{"resource": "StyleBox", "property": "corner_radius_bottom_right"}
	],
	"font-color": [{"resource": "Control", "property": "%s/colors/font_color"}],
	"font-size": [{"resource": "Control", "property": "%s/font_sizes/font_size"}],
}


static func parse(text: String) -> Dictionary:
	var lines: PackedStringArray = text.split("\n")
	var styles: Dictionary = {}
	var key: String = ""
	
	for i: int in range(lines.size()):
		var line: String = lines[i].strip_edges()
		var last_char: String = line.substr(line.length() - 1)
		
		if "{" == last_char:
			key = line.trim_suffix("{").rstrip(" ")
		elif "}" == last_char:
			key = ""
		elif line and key:
			if !styles.has(key):
				styles[key] = []
			styles[key].append(line.trim_suffix(";"))
	
	return styles


static func parse_file(path: String) -> Dictionary:
	var gss_file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var gss: String = gss_file.get_as_text()
	
	return parse(strip_comments(gss))


static func to_tres(path: String, output_path: String = "") -> void:
	var theme := Theme.new()
	var styles: Dictionary = parse_file(path)
	
	if !output_path:
		output_path = "%s.tres" % path.trim_suffix(".txt")
	
	for key in styles.keys():
		var type: String = key.get_slice(":", 0)
		var state: String = key.substr(type.length())
		var rules: Array = styles[key]
		
		if !state:
			state = ":default"
		
		theme.add_type(type)
		print(type, state)
		
		for rule in rules:
			var prop: String = rule.get_slice(":", 0)
			var value: String = rule.get_slice(":", 1)
			var theme_props: Array = gss_property_map[prop] if gss_property_map.has(prop) else []
			
			if !theme_props:
				continue
			
			for theme_prop in theme_props:
				prints(theme_prop, value)
	
	ResourceSaver.save(theme, output_path)


static func strip_comments(text: String) -> String:
	return comment_pattern.sub(text, '', true)
