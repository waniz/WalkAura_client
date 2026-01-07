class_name CharacterHUD extends Control

@onready var character_hud: CharacterHUD = $"."

@onready var avatar: TextureRect = $Avatar
@onready var name_level: RichTextLabel = $Avatar/MainBars/Name_level
@onready var hp_bar: ProgressBar = $Avatar/MainBars/HPBar
@onready var hp_label: Label = $Avatar/MainBars/HPBar/HPLabel
@onready var mp_bar: ProgressBar = $Avatar/MainBars/MPBar
@onready var mp_label: Label = $Avatar/MainBars/MPBar/MPLabel
@onready var shield_bar: ProgressBar = $Avatar/MainBars/ShieldBar
@onready var shield_label: Label = $Avatar/MainBars/ShieldBar/ShieldLabel
@onready var activity_label: Label = $Avatar/MainBars/HBoxContainer/ActivityLabel
@onready var texture_rect: TextureRect = $Avatar/MainBars/HBoxContainer/PanelContainer/TextureRect
@onready var panel_container: PanelContainer = $Avatar/MainBars/HBoxContainer/PanelContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	AccountManager.signal_AccountDataReceived.connect(_update_character_hud)
	
	# Make bars look “splendid”: rounded, shadowed, colored
	Styler.style_bar(hp_bar, Color.from_rgba8(220, 60, 60), Color.from_rgba8(40, 20, 20))   
	Styler.style_bar(mp_bar, Color.from_rgba8(70, 120, 255), Color.from_rgba8(20, 30, 60))  
	Styler.style_bar(shield_bar, Color.from_rgba8(64, 190, 255), Color.from_rgba8(20, 30, 60))
	
	Styler.style_name_label(activity_label, Color.from_rgba8(255, 128, 128))
	Styler.style_panel_no_margins(panel_container, Color.from_rgba8(16,18,24,220), Color.from_rgba8(255,255,255,30))
	
	_update_character_hud(true)
	
	
func set_stats(hp_current: int, hp_max: int, mp_current: int, mp_max: int, shield_current: int, shield_max: int, xp_current: int, xp_max: int) -> void:
	_set_bar(hp_bar, hp_label, hp_current, hp_max)
	_set_bar(mp_bar, mp_label, mp_current, mp_max)
	_set_bar(shield_bar, shield_label, shield_current, shield_max)
	
func _set_bar(bar: ProgressBar, label: Label, cur: int, maxv: int) -> void:
	bar.max_value = max(1, maxv)
	label.text = "%d / %d" % [cur, maxv]
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bar, "value", clamp(cur, 0, maxv), 0.25)
	
func _update_character_hud(value):
	# print("_update_character_hud: {0}".format([value]))
	character_hud.set_stats(
		Account.hp,
		Account.hp_max,
		Account.mp,
		Account.mp_max,
		Account.shield,
		Account.shield_max,
		Account.buffer_steps,
		Account.buffer_steps_max,
	)
	name_level.text = "[color=green]{0}[/color]  Lv [color=orange]{1}[/color]".format([Account.username, Account.level])
	var current_activity_name = GameTextEn.activities_texts[Account.activity]

	if current_activity_name.to_lower() == "no":
		texture_rect.visible = false
		activity_label.text = "No Activity"
	else:
		texture_rect.visible = true
		texture_rect.texture = ItemDB.ICONS[current_activity_name.to_lower()]
		activity_label.text = current_activity_name
	
