class_name CharacterHUD extends Control

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


func _ready() -> void:
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

	# example values (remove in game)
	set_stats(95, 120, 60, 100, 77, 88, 19, 100)
	set_nameplate_text("THE WANDERER · Lv. 12") 
	
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
