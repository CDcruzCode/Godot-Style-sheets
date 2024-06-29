extends Node2D


func _ready() -> void:
	#GSS.to_tres("res://examples/test_stylesheet.txt")
	var gss: Dictionary = GSS.file_to_dict("res://examples/test_stylesheet.txt")
	print(gss)
