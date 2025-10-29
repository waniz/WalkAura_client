class_name CharacterHUD extends Control

@onready var character_hud: CharacterHUD = $"."

@onready var avatar: TextureRect = $Avatar
@onready var hp_bar: ProgressBar = $Avatar/MainBars/HPBar
@onready var hp_label: Label = $Avatar/MainBars/HPBar/HPLabel
@onready var mp_bar: ProgressBar = $Avatar/MainBars/MPBar
@onready var mp_label: Label = $Avatar/MainBars/MPBar/MPLabel
@onready var shield_bar: ProgressBar = $Avatar/MainBars/ShieldBar
@onready var xp_bar: ProgressBar = $Avatar/MainBars/XPBar
@onready var shield_label: Label = $Avatar/MainBars/ShieldBar/ShieldLabel
@onready var nameplate: PanelContainer = $Avatar/MainBars/Nameplate
@onready var level_label: Label = $Avatar/MainBars/Nameplate/LevelLabel
@onready var activity_plate: PanelContainer = $Avatar/MainBars/ActivityPlate
@onready var activity_label: Label = $Avatar/MainBars/ActivityPlate/ActivityLabel


func _ready() -> void:
	AccountManager.signal_AccountDataReceived.connect(_update_character_hud)
	
	# Make bars look “splendid”: rounded, shadowed, colored
	Styler.style_bar(hp_bar, Color.from_rgba8(220, 60, 60), Color.from_rgba8(40, 20, 20))   
	Styler.style_bar(mp_bar, Color.from_rgba8(70, 120, 255), Color.from_rgba8(20, 30, 60))  
	Styler.style_bar(shield_bar, Color.from_rgba8(64, 190, 255), Color.from_rgba8(20, 30, 60)) 
	Styler.style_bar(xp_bar, Color.from_rgba8(170, 90, 255), Color.from_rgba8(20, 30, 60)) 
	hp_bar.show_percentage = false
	mp_bar.show_percentage = false
	shield_bar.show_percentage = false
	xp_bar.show_percentage = false
	
	Styler.style_name_label(level_label, Color.from_rgba8(255, 215, 128))
	Styler.style_name_label(activity_label, Color.from_rgba8(255, 128, 128))
	
	_update_character_hud(true)

	
func set_stats(hp_current: int, hp_max: int, mp_current: int, mp_max: int, shield_current: int, shield_max: int, xp_current: int, xp_max: int) -> void:
	_set_bar(hp_bar, hp_label, hp_current, hp_max)
	_set_bar(mp_bar, mp_label, mp_current, mp_max)
	_set_bar(shield_bar, shield_label, shield_current, shield_max)
	_set_bar_no_label(xp_bar, xp_current, xp_max)
	
func _set_bar(bar: ProgressBar, label: Label, cur: int, maxv: int) -> void:
	bar.max_value = max(1, maxv)
	label.text = "%d / %d" % [cur, maxv]
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bar, "value", clamp(cur, 0, maxv), 0.25)
	
func _set_bar_no_label(bar: ProgressBar, cur: int, maxv: int) -> void:
	bar.max_value = max(1, maxv)
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bar, "value", clamp(cur, 0, maxv), 0.25)
	
func set_nameplate_text(t: String) -> void:
	level_label.text = t
	
func set_activityplate_text(t: String) -> void:
	activity_label.text = t
	
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
	character_hud.set_nameplate_text("{0} · Lv. {1}".format([Account.username, Account.level]))
	character_hud.set_activityplate_text("Activity - {0} [{1}]".format(
		[GameTextEn.activities_texts[Account.activity],  Account.activity_site])
	)
