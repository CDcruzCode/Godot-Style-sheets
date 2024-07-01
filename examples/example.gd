extends Node2D


func _ready() -> void:
	var button := Button.new()
	var text_edit := TextEdit.new()
	var button_props: Array = button.get_property_list()
	var text_edit_props: Array = text_edit.get_property_list()
	
	for prop: Dictionary in button_props:
		print(prop)
	
	print("***")
	print("***")
	print("***")
	
	for prop: Dictionary in text_edit_props:
		print(prop)
	
	#GSS.file_to_tres("res://examples/test_stylesheet.txt")
