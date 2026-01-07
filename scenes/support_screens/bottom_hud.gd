extends CanvasLayer

@onready var button_panel: PanelContainer = $ButtonPanel


func _ready() -> void:
	Styler.style_panel(button_panel, Color.from_rgba8(16,18,24,220), Color.from_rgba8(255,255,255,30))


func _on_btn_profile_pressed() -> void:
	SignalManager.signal_PageChanged.emit(0)


func _on_btn_location_pressed() -> void:
	SignalManager.signal_PageChanged.emit(1)


func _on_btn_inventory_pressed() -> void:
	SignalManager.signal_PageChanged.emit(2)
