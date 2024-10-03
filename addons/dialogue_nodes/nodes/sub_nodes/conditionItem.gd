@tool
extends BoxContainer


signal modified
signal delete_requested

@export var is_last := false :
	set(value):
		is_last = value
		if is_instance_valid(combiner):
			combiner.visible = not is_last
@export var show_delete := false :
	set(value):
		show_delete = value
		if is_instance_valid(delete_button):
			delete_button.visible = show_delete

@onready var value1: LineEdit = $MainContainer/Value1
@onready var operator: OptionButton = $MainContainer/Operator
@onready var value2: LineEdit = $MainContainer/Value2
@onready var timer: Timer = $Timer
@onready var combiner: OptionButton = $SideContainer/Combiner
@onready var reset_button: Button = $SideContainer/ResetButton
@onready var delete_button: Button = $SideContainer/DeleteButton

var undo_redo: EditorUndoRedoManager
var cur_condition := {}


func _to_dict() -> Dictionary:
	if is_empty():
		print_rich('[color=yellow]Condition is empty![/color]')
		return {}
	
	var dict:= {
		'value1': value1.text,
		'operator': operator.selected,
		'value2': value2.text
	}
	
	if not is_last:
		dict['combiner'] = combiner.selected
	
	return dict


func _from_dict(dict: Dictionary) -> void:
	cur_condition = dict
	if dict.is_empty():
		dict = {
			'value1': '',
			'operator': 0,
			'value2': '',
			'combiner': 0
		}
		reset_button.hide()
	else:
		reset_button.show()
	
	if value1.text != dict['value1']:
		value1.text = dict['value1']
	if operator.selected != dict['operator']:
		operator.selected = dict['operator']
	if value2.text != dict['value2']:
		value2.text = dict['value2']
	if dict.has('combiner'):
		combiner.selected = dict['combiner']


func is_empty() -> bool:
	return (value1.text == '') and (operator.selected == 0) and (value2.text == '')


func _on_condition_changing(_a=0) -> void:
	timer.stop()
	timer.start()


func _on_condition_changed() -> void:
	if not undo_redo: return
	
	var new_condition : Dictionary = _to_dict()
	
	undo_redo.create_action('Set condition')
	undo_redo.add_do_method(self, '_from_dict', new_condition)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_from_dict', cur_condition)
	undo_redo.commit_action()


func _on_condition_reset() -> void:
	if not undo_redo: return
	
	var new_condition := {}
	
	undo_redo.create_action('Reset condition')
	undo_redo.add_do_method(self, '_from_dict', new_condition)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_from_dict', cur_condition)
	undo_redo.commit_action()


func _on_delete_button_pressed() -> void:
	delete_requested.emit()


func _on_modified() -> void:
	modified.emit()