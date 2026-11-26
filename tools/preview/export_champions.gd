extends SceneTree

const ArenaView = preload("res://scripts/arena_view.gd")
const ArenaMatch = preload("res://scripts/arena_match.gd")
const Pantheon = preload("res://scripts/pantheon.gd")


func _initialize() -> void:
	call_deferred("_export_champions")


func _export_champions() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty() or arguments.size() > 2 or not arguments[0].is_absolute_path() or (arguments.size() == 2 and arguments[1] != "--animated"):
		push_error("Pass an absolute output directory and optional --animated after --.")
		quit(1)
		return
	var output: String = arguments[0]
	var animated := arguments.size() == 2
	var created := DirAccess.make_dir_recursive_absolute(output)
	if created != OK:
		push_error("Cannot create output directory %s (%s)." % [output, error_string(created)])
		quit(1)
		return

	var arena_view = ArenaView.new()
	root.add_child(arena_view)
	var roster: Array[Dictionary] = []
	var fighter_index := 0
	for class_id: String in ArenaMatch.CLASS_INFO:
		var kit: Dictionary = ArenaMatch.CLASS_INFO[class_id]
		var champion: Array = Pantheon.GODS[class_id]
		var pawn: Dictionary = arena_view._create_pawn(fighter_index, class_id, 0, 100.0)
		if not pawn.has("model"):
			push_error("%s is missing its authored champion model." % class_id)
			quit(1)
			return
		var model = pawn.model
		var animator: AnimationPlayer = model.player
		if animated:
			animator.stop()
		else:
			animator.play("cast_1")
			animator.seek(animator.get_animation("cast_1").length * 0.45, true)
			animator.get_parent().remove_child(animator)
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var status := document.append_from_scene(model, state)
		if not animated:
			animator.free()
		if status == OK:
			status = document.write_to_filesystem(state, output.path_join(class_id + ".glb"))
		if status != OK:
			push_error("%s mesh export failed (%s)." % [class_id, error_string(status)])
			quit(1)
			return
		roster.append({"id": class_id, "class": kit.name, "champion": champion[2], "god": champion[0], "title": champion[1]})
		fighter_index += 1

	var manifest := FileAccess.open(output.path_join("champions.json"), FileAccess.WRITE)
	if manifest == null:
		push_error("Cannot write the preview roster.")
		quit(1)
		return
	manifest.store_string(JSON.stringify(roster, "\t"))
	print("Exported %d actual arena champion meshes." % roster.size())
	quit()
