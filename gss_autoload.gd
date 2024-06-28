extends Node

const gss_file_path:String = "res://gss_test_style.txt"
var raw_gss:String = "";


###LOADING GSS###
func _ready() -> void:
	raw_gss = load_file(gss_file_path)
	if(raw_gss.strip_edges() == ""):
		push_error("[GSS] Invalid file path provided for gss file.")
		return
	
	var parser:Dictionary = parse_gss(raw_gss)
	print(parser)
	apply_styling(parser)

func load_file(path:String)->String:
	if FileAccess.file_exists(path):
		var file:FileAccess = FileAccess.open(path, FileAccess.READ)
		var content:String = file.get_as_text()
		file.close()
		return content
	return ""
###LOADING GSS###

###PARSING GSS###
func parse_gss(gss:String)->Dictionary:
	#Clear up GSS
	gss = gss_remove_comments(gss)
	var sorted_rules:Array = gss_sort_rules(gss)
	
	var styles:Dictionary = {}
	for elem:Array in sorted_rules:
		var property_string:String = elem[1]
		var properties:Array = property_string.split(";", false)
		var property_list:Array = []
		for style:String in properties:
			var style_split:PackedStringArray = str(style).split(":", true, 1)
			var property:String = style_split[0].strip_edges().strip_escapes().to_lower()
			var pvalue:String = style_split[1].strip_edges().strip_escapes().to_lower()
			property_list.append( [property, pvalue] )
		
		styles[elem[0]] = property_list
		
	
	return styles

func gss_remove_comments(gss:String)->String:
	var regex:RegEx = RegEx.new()
	regex.compile(r'/\*.*?\*/')
	gss = regex.sub(gss, '', true)
	return gss

func gss_sort_rules(gss:String)->Array:
	const regex_rule:String = r"([#.a-zA-Z\d0-9-:]+\s*){([\sa-z-:;0-9#\(\),-\\]*)}"
	var regex:RegEx = RegEx.new()
	regex.compile(regex_rule)
	
	var rule_arr:Array = []
	var matched_arr:Array[RegExMatch] = regex.search_all(gss)
	
	for i in matched_arr:
		rule_arr.append(
			[i.get_string(1).strip_edges(), #Object
			i.get_string(2).strip_escapes().strip_edges() #Style Properties
		])
	
	return rule_arr
###PARSING GSS###


###APPLYING STYLES###
var selector_current:String
var property_current:String

func apply_styling(stylesheet:Dictionary)->bool:
	var theme:Theme = Theme.new()
	
	#var style_box = StyleBoxFlat.new()
	#style_box.bg_color = Color.RED
	#style_box.border_color = Color(0.8, 0.8, 0.8)
	
	#theme.set_stylebox("normal", "Button", style_box)
	
	var selectors:Array = stylesheet.keys()
	print("KEYS: ", selectors)
	
	#Apply styles to default elements
	for selector:String in selectors:
		selector_current = selector
		var stylebox_current:StyleBoxFlat = StyleBoxFlat.new()
		print("[applying_style] Processing selector: ", selector.to_lower())
		match(selector.to_lower()):
			":root":
				pass
			"button":
				if(theme.has_stylebox("normal", "Button")):
					stylebox_current = theme.get_stylebox("normal", "Button").duplicate()
				theme.set_stylebox("normal", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				###SET FONT COLOUR
				if(property_list_get(stylesheet.get(selector), "font-color") != ""):
					theme.set_color("font_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
				elif(property_list_get(stylesheet.get(selector), "color") != ""):
					theme.set_color("font_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "color")))
				elif(property_list_get(stylesheet.get(selector), "font-colour") != ""):
					theme.set_color("font_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-colour")))
				elif(property_list_get(stylesheet.get(selector), "colour") != ""):
					theme.set_color("font_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "colour")))
				###
				###SET FONT SIZE
				if(property_list_get(stylesheet.get(selector), "font-size") != ""):
					theme.set_font_size("font_size", "Button", int(property_list_get(stylesheet.get(selector), "font-size")) )
				###
				continue
			"button:hover":
				if(theme.has_stylebox("normal", "Button")):
					stylebox_current = theme.get_stylebox("normal", "Button").duplicate()
				theme.set_stylebox("hover", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				###SET FONT COLOUR
				if(property_list_get(stylesheet.get(selector), "font-color") != ""):
					theme.set_color("font_hover_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
				elif(property_list_get(stylesheet.get(selector), "color") != ""):
					theme.set_color("font_hover_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "color")))
				elif(property_list_get(stylesheet.get(selector), "font-colour") != ""):
					theme.set_color("font_hover_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-colour")))
				elif(property_list_get(stylesheet.get(selector), "colour") != ""):
					theme.set_color("font_hover_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "colour")))
				###
				###SET FONT SIZE
				if(property_list_get(stylesheet.get(selector), "font-size") != ""):
					theme.set_font_size("font_size", "Button", int(property_list_get(stylesheet.get(selector), "font-size")) )
				###
				continue
			"button:pressed":
				if(theme.has_stylebox("normal", "Button")):
					stylebox_current = theme.get_stylebox("normal", "Button").duplicate()
				theme.set_stylebox("pressed", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				###SET FONT COLOUR
				if(property_list_get(stylesheet.get(selector), "font-color") != ""):
					theme.set_color("font_pressed_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
				elif(property_list_get(stylesheet.get(selector), "color") != ""):
					theme.set_color("font_pressed_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "color")))
				elif(property_list_get(stylesheet.get(selector), "font-colour") != ""):
					theme.set_color("font_pressed_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-colour")))
				elif(property_list_get(stylesheet.get(selector), "colour") != ""):
					theme.set_color("font_pressed_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "colour")))
				###
				###SET FONT SIZE
				if(property_list_get(stylesheet.get(selector), "font-size") != ""):
					theme.set_font_size("font_size", "Button", int(property_list_get(stylesheet.get(selector), "font-size")) )
				###
				continue
			"button:hover-pressed":
				#if(theme.has_stylebox("normal", "Button")):
				#	stylebox_current = theme.get_stylebox("normal", "Button").duplicate()
				#theme.set_stylebox("hover", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				###SET FONT COLOUR
				if(property_list_get(stylesheet.get(selector), "font-color") != ""):
					theme.set_color("font_hover_pressed_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
				elif(property_list_get(stylesheet.get(selector), "color") != ""):
					theme.set_color("font_hover_pressed_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "color")))
				elif(property_list_get(stylesheet.get(selector), "font-colour") != ""):
					theme.set_color("font_hover_pressed_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-colour")))
				elif(property_list_get(stylesheet.get(selector), "colour") != ""):
					theme.set_color("font_hover_pressed_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "colour")))
				###
				###SET FONT SIZE
				if(property_list_get(stylesheet.get(selector), "font-size") != ""):
					theme.set_font_size("font_size", "Button", int(property_list_get(stylesheet.get(selector), "font-size")) )
				###
				continue
			"button:focus":
				if(theme.has_stylebox("normal", "Button")):
					stylebox_current = theme.get_stylebox("normal", "Button").duplicate()
				theme.set_stylebox("focus", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				###SET FONT COLOUR
				if(property_list_get(stylesheet.get(selector), "font-color") != ""):
					theme.set_color("font_focus_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
				elif(property_list_get(stylesheet.get(selector), "color") != ""):
					theme.set_color("font_focus_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "color")))
				elif(property_list_get(stylesheet.get(selector), "font-colour") != ""):
					theme.set_color("font_focus_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-colour")))
				elif(property_list_get(stylesheet.get(selector), "colour") != ""):
					theme.set_color("font_focus_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "colour")))
				###
				###SET FONT SIZE
				if(property_list_get(stylesheet.get(selector), "font-size") != ""):
					theme.set_font_size("font_size", "Button", int(property_list_get(stylesheet.get(selector), "font-size")) )
				###
				continue
			"button:disabled":
				if(theme.has_stylebox("normal", "Button")):
					stylebox_current = theme.get_stylebox("normal", "Button").duplicate()
				theme.set_stylebox("disabled", "Button", create_styleboxflat(stylesheet.get(selector), stylebox_current) )
				###SET FONT COLOUR
				if(property_list_get(stylesheet.get(selector), "font-color") != ""):
					theme.set_color("font_disabled_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-color")))
				elif(property_list_get(stylesheet.get(selector), "color") != ""):
					theme.set_color("font_disabled_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "color")))
				elif(property_list_get(stylesheet.get(selector), "font-colour") != ""):
					theme.set_color("font_disabled_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "font-colour")))
				elif(property_list_get(stylesheet.get(selector), "colour") != ""):
					theme.set_color("font_disabled_color", "Button", set_valid_colour(property_list_get(stylesheet.get(selector), "colour")))
				###
				###SET FONT SIZE
				if(property_list_get(stylesheet.get(selector), "font-size") != ""):
					theme.set_font_size("font_size", "Button", int(property_list_get(stylesheet.get(selector), "font-size")) )
				###
				continue
	
	
	
	get_tree().root.theme = theme
	return true

func create_styleboxflat(styling:Array, stylebox:StyleBoxFlat = StyleBoxFlat.new())->StyleBoxFlat:
	
	for style:Array in styling:
		var property:String = style[0]
		print("[styleboxflat] processing property: ", property)
		var pvalue:String = style[1]
		match(property):
			"background-color", "background-colour": stylebox.bg_color = set_valid_colour(pvalue)
			"border-color", "border-colour": set_border_colour(stylebox, pvalue)
			"border-top": stylebox.border_width_top = set_valid_width(pvalue)
			"border-right": stylebox.border_width_right = set_valid_width(pvalue)
			"border-bottom": stylebox.border_width_bottom = set_valid_width(pvalue)
			"border-left": stylebox.border_width_left = set_valid_width(pvalue)
			"border": apply_border(stylebox, pvalue)
			"border-top-left-radius", "corner_radius_top_left": stylebox.corner_radius_top_left = set_valid_radius(pvalue)
			"border-top-right-radius", "corner_radius_top_right": stylebox.corner_radius_top_right = set_valid_radius(pvalue)
			"border-bottom-right-radius", "corner_radius_bottom_right": stylebox.corner_radius_bottom_right = set_valid_radius(pvalue)
			"border-bottom-left-radius", "corner_radius_bottom_left": stylebox.corner_radius_bottom_left = set_valid_radius(pvalue)
			"border-radius", "corner-radius": apply_radius(stylebox, pvalue)
			"shadow": apply_shadow(stylebox, pvalue)
			"padding", "content-margin": apply_padding(stylebox, pvalue)
	return stylebox

func apply_border(stylebox:StyleBoxFlat, values:String)->void:
	var arr:Array = values.split(" ", false, 0)
	if(arr.size() == 0 || arr.size() > 4):
		push_warning("[GSS] -"+selector_current+"- Border width not set, invalid values!")
		return
	elif(arr.size() == 1):
		stylebox.border_width_top = set_valid_width(arr[0])
		stylebox.border_width_right = set_valid_width(arr[0])
		stylebox.border_width_bottom = set_valid_width(arr[0])
		stylebox.border_width_left = set_valid_width(arr[0])
	elif(arr.size() == 2):
		stylebox.border_width_top = set_valid_width(arr[0])
		stylebox.border_width_bottom = set_valid_width(arr[0])
		stylebox.border_width_left = set_valid_width(arr[1])
		stylebox.border_width_right = set_valid_width(arr[1])
	elif(arr.size() == 3):
		stylebox.border_width_top = set_valid_width(arr[0])
		stylebox.border_width_left = set_valid_width(arr[1])
		stylebox.border_width_right = set_valid_width(arr[1])
		stylebox.border_width_bottom = set_valid_width(arr[2])
	elif(arr.size() == 4):
		stylebox.border_width_top = set_valid_width(arr[0])
		stylebox.border_width_right = set_valid_width(arr[1])
		stylebox.border_width_bottom = set_valid_width(arr[2])
		stylebox.border_width_left = set_valid_width(arr[3])

func set_valid_width(size:String)->int:
	if(!size.ends_with("px")):
		push_warning("[GSS] -"+selector_current+"- Could not set property '"+property_current+"'! border width must be in pixels. Like 'border-bottom: 10px'.")
		return 0
	
	return int(size.trim_suffix("px"))

func set_border_colour(stylebox:StyleBoxFlat, values:String)->void:
	var arr:Array = values.split(" ", false, 2)
	if(arr.size() == 0):
		return
	if(arr.size() > 0):
		stylebox.border_color = set_valid_colour(arr[0])
	
	if(arr.size() == 2 && str(arr[1]).to_lower() == "blend" ):
		stylebox.border_blend = true
	else:
		stylebox.border_blend = false



func apply_radius(stylebox:StyleBoxFlat, values:String)->void:
	var arr:Array = values.split(" ", false, 0)
	if(arr.size() == 0 || arr.size() > 4):
		push_warning("[GSS] -"+selector_current+"- Corner radius not set, invalid values!")
		return
	elif(arr.size() == 1):
		stylebox.corner_radius_top_left = set_valid_radius(arr[0])
		stylebox.corner_radius_top_right = set_valid_radius(arr[0])
		stylebox.corner_radius_bottom_right = set_valid_radius(arr[0])
		stylebox.corner_radius_bottom_left = set_valid_radius(arr[0])

func set_valid_radius(size:String)->int:
	if(!size.ends_with("px")):
		push_warning("[GSS] -"+selector_current+"- Could not set property '"+property_current+"'! corner radius must be in pixels. Like 'border-top-left-radius: 10px'.")
		return 0
	
	return int(size.trim_suffix("px"))

func set_valid_offset(size:String)->float:
	if(!size.ends_with("px")):
		push_warning("[GSS] -"+selector_current+"- Could not set property '"+property_current+"'! corner radius must be in pixels. Like 'shadow: red 2px 10px 30px'.")
		return 0
	
	return float(size.trim_suffix("px"))



func apply_shadow(stylebox:StyleBoxFlat, values:String)->void:
	var vals:PackedStringArray = values.split(" ");
	if(vals.size() == 0):
		return
	
	if(vals.size() >= 1):
		#Set shadow colour
		stylebox.shadow_color = set_valid_colour(vals[0])
	
	if(vals.size() >= 2):
		stylebox.shadow_size = set_valid_width(vals[1])
	
	if(vals.size() >= 3):
		stylebox.shadow_offset = Vector2(set_valid_offset(vals[2]), 0)
	
	if(vals.size() >= 4):
		stylebox.shadow_offset = Vector2(set_valid_offset(vals[2]), set_valid_offset(vals[3]))

func apply_padding(stylebox:StyleBoxFlat, values:String)->void:
	var arr:Array = values.split(" ", false, 0)
	if(arr.size() == 0 || arr.size() > 4):
		push_warning("[GSS] -"+selector_current+"- Margin not set, invalid values!")
		return
	elif(arr.size() == 1):
		stylebox.content_margin_top = set_valid_width(arr[0])
		stylebox.content_margin_right = set_valid_width(arr[0])
		stylebox.content_margin_bottom = set_valid_width(arr[0])
		stylebox.content_margin_left = set_valid_width(arr[0])
	elif(arr.size() == 2):
		stylebox.content_margin_top = set_valid_width(arr[0])
		stylebox.content_margin_bottom = set_valid_width(arr[0])
		stylebox.content_margin_left = set_valid_width(arr[1])
		stylebox.content_margin_right = set_valid_width(arr[1])
	elif(arr.size() == 3):
		stylebox.content_margin_top = set_valid_width(arr[0])
		stylebox.content_margin_left = set_valid_width(arr[1])
		stylebox.content_margin_right = set_valid_width(arr[1])
		stylebox.content_margin_bottom = set_valid_width(arr[2])
	elif(arr.size() == 4):
		stylebox.content_margin_top = set_valid_width(arr[0])
		stylebox.content_margin_right = set_valid_width(arr[1])
		stylebox.content_margin_bottom = set_valid_width(arr[2])
		stylebox.content_margin_left = set_valid_width(arr[3])









func set_valid_colour(colour:String)->Color:
	var new_colour:Color = Color.HOT_PINK
	if(colour.begins_with("rgb") && !colour.begins_with("rgba")):
		var colour_split:Array = colour.trim_prefix("rgb").replacen("(","").replacen(")","").split_floats(",", false)
		if(colour_split.size() != 3):
			push_error("[set_valid_colour] -"+selector_current+"- invalid RGB colour: ", colour_split)
			return new_colour
		
		if(colour_split[0] > 1.0 || colour_split[1] > 1.0  || colour_split[2] > 1.0 ):
			return Color8(int(colour_split[0]), int(colour_split[1]), int(colour_split[2]))
		
		return Color(colour_split[0], colour_split[1], colour_split[2])
	
	if(colour.begins_with("rgba")):
		var colour_split:Array = colour.split_floats(",", false)
		if(colour_split.size() != 4):
			push_error("[set_valid_colour] invalid RGBA colour: ", colour_split)
			return new_colour
		
		if(colour_split[0] > 1.0 || colour_split[1] > 1.0  || colour_split[2] > 1.0 || colour_split[3] > 1.0 ):
			return Color8(int(colour_split[0]), int(colour_split[1]), int(colour_split[2]), int(colour_split[3]))
		
		return Color(colour_split[0], colour_split[1], colour_split[2], colour_split[3])
	
	return Color.from_string(colour, Color.HOT_PINK) #If not rgb or rgba, try to return a named colour

func property_list_get(list:Array, item:String)->String:
	for i:Array in list:
		if(i[0] == item):
			return i[1]
	push_error("[GSS] -"+selector_current+"- No property named: "+item+" found!")
	return ""

#func scale_num_to_range(number:float, old_min:float, old_max:float, new_min:float, new_max:float)->float:
	#var old_range:float = old_max - old_min
	#var new_range:float = new_max - new_min
	#return (number - old_min) / old_range * new_range + new_min
##APPLYING STYLES###
