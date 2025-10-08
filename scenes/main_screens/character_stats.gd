extends Control

@onready var rich_text_label: RichTextLabel = $MainParamsHolder/RichTextLabel

@onready var hp_progress_bar: ProgressBar = $MainAttrsHolder/HPProgressBar
@onready var mp_progress_bar: ProgressBar = $MainAttrsHolder/MPProgressBar
@onready var shield_progress_bar: ProgressBar = $MainAttrsHolder/ShieldProgressBar

@onready var str_label: Label = $PrimaryAttrsHolder/VBoxContainer2/STRLabel
@onready var agi_label: Label = $PrimaryAttrsHolder/VBoxContainer2/AGILabel
@onready var vit_label: Label = $PrimaryAttrsHolder/VBoxContainer2/VITLabel
@onready var int_label: Label = $PrimaryAttrsHolder/VBoxContainer2/INTLabel
@onready var spi_label: Label = $PrimaryAttrsHolder/VBoxContainer2/SPILabel

@onready var total_steps_label: RichTextLabel = $StepsHolder/TotalStepsLabel
@onready var buffer_steps_label: RichTextLabel = $StepsHolder/BufferStepsLabel

@onready var atkpowermin_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/ATKpowerminLabel
@onready var atkpowermax_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/ATKpowermaxLabel
@onready var spellpowermin_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/SPELLpowerminLabel
@onready var spellpowermax_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/SPELLpowermaxnLabel
@onready var hitrating_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/HITratingLabel
@onready var critchange_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/CRITchangeLabel
@onready var critdamage_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/CRITdamageLabel
@onready var haste_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/HASTELabel
@onready var armor_pen_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/ARMORPenLabel
@onready var mag_pen_label: RichTextLabel = $OffensiveAttrHolder/VBoxContainer/MagPenLabel

@onready var armor_label: RichTextLabel = $DefensiveAttrHolder/VBoxContainer2/ArmorLabel
@onready var mag_armor_label: RichTextLabel = $DefensiveAttrHolder/VBoxContainer2/MagArmorLabel
@onready var block_chance_label: RichTextLabel = $DefensiveAttrHolder/VBoxContainer2/BlockChanceLabel
@onready var evasion_label: RichTextLabel = $DefensiveAttrHolder/VBoxContainer2/EvasionLabel
@onready var dmg_reduction_label: RichTextLabel = $DefensiveAttrHolder/VBoxContainer2/DMGReductionLabel
@onready var fire_res_label: RichTextLabel = $ResistanceAttrHolder/VBoxContainer2/FireResLabel
@onready var frost_res_label: RichTextLabel = $ResistanceAttrHolder/VBoxContainer2/FrostResLabel
@onready var lightning_res_label: RichTextLabel = $ResistanceAttrHolder/VBoxContainer2/LightningResLabel
@onready var poison_res_label: RichTextLabel = $ResistanceAttrHolder/VBoxContainer2/PoisonResLabel
@onready var death_res_label: RichTextLabel = $ResistanceAttrHolder/VBoxContainer2/DeathResLabel
@onready var holy_res_label: RichTextLabel = $ResistanceAttrHolder/VBoxContainer2/HolyResLabel2


func _ready() -> void:
	AccountManager.signal_AccountDataReceived.connect(_update_character_data)
	_update_character_data()

	
func _update_character_data(result_of_call=true):
	print("==  UPDATE CHARACTER DATA: {result_of_call}")
	rich_text_label.text = "UID         : " + str(Account.user_uid) + "\n" + "UserID : " + str(Account.userid) + "\n" + "Name  :  " + str(Account.username)
	
	hp_progress_bar.max_value = Account.hp_max
	hp_progress_bar.value = Account.hp_current
	mp_progress_bar.max_value = Account.mp_max
	mp_progress_bar.value = Account.mp_current
	shield_progress_bar.max_value = Account.shield_max
	shield_progress_bar.value = Account.shield_current
	
	str_label.text = str(int(Account.str))
	agi_label.text = str(int(Account.agi))
	vit_label.text = str(int(Account.vit))
	int_label.text = str(int(Account.int_stat))
	spi_label.text = str(int(Account.spi))
	
	total_steps_label.text =str(int(Account.total_steps))
	buffer_steps_label.text =str(int(Account.buffer_steps_current))
	
	atkpowermin_label.text = str(int(Account.atk_power_min))
	atkpowermax_label.text = str(int(Account.atk_power_max))
	spellpowermin_label.text = str(int(Account.spell_power_min))
	spellpowermax_label.text = str(int(Account.spell_power_max))
	hitrating_label.text = str(int(Account.hit_rating))
	critchange_label.text = str(Account.crit_chance)
	critdamage_label.text = str(Account.crit_damage)
	haste_label.text = str(Account.haste)
	armor_pen_label.text = str(int(Account.armor_pen))
	mag_pen_label.text = str(int(Account.magic_pen))
	
	armor_label.text = str(int(Account.physical_def))
	mag_armor_label.text = str(int(Account.magic_def))
	block_chance_label.text = str(Account.block_chance)
	evasion_label.text = str(Account.evasion)
	dmg_reduction_label.text = str(Account.dmg_reduction)
	fire_res_label.text = str(int(Account.resistance_fire))
	frost_res_label.text = str(int(Account.resistance_frost))
	lightning_res_label.text = str(int(Account.resistance_lightning))
	poison_res_label.text = str(int(Account.resistance_poison))
	death_res_label.text = str(int(Account.resistance_death))
	holy_res_label.text = str(int(Account.resistance_holy))
