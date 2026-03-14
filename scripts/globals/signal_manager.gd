extends Node

# Account signals
@warning_ignore("unused_signal")
signal signal_CreateUser(user, password)
@warning_ignore("unused_signal")
signal signal_LoginUser(user, password)

# Client signals
@warning_ignore("unused_signal")
signal signal_PageChanged(index)

# Activity signals
@warning_ignore("unused_signal")
signal signal_UserActivity(activity, activity_site, action)

# Steps signals
@warning_ignore("unused_signal")
signal signal_StepsUpdatesAndroid(data)
@warning_ignore("unused_signal")
signal signal_StepsRequestLastTimestamp(is_requested)
@warning_ignore("unused_signal")
signal signal_StepsUpdatesCheats(amount)
@warning_ignore("unused_signal")
signal signal_StepsReceivedFromServer(amount)

# Inventory and equipment signals
@warning_ignore("unused_signal")
signal signal_RequestInventory(action)
@warning_ignore("unused_signal")
signal signal_EquipItem(item_uid: String, slot_name: String)
@warning_ignore("unused_signal")
signal signal_UnequipItem(slot_name: String)
@warning_ignore("unused_signal")
signal signal_UseItem(item_uid: String, qty: int)
@warning_ignore("unused_signal")
signal signal_SellItem(item_uid: String)
@warning_ignore("unused_signal")
signal signal_SellItems(item_uids: Array)

# Skills control
@warning_ignore("unused_signal")
signal signal_EquipSkill(slot: int, skill_id: String)
@warning_ignore("unused_signal")
signal signal_UnEquipSkill(slot: int)

# Travel signals
@warning_ignore("unused_signal")
signal signal_TravelRequest(location_id: int)

# Rift signals
@warning_ignore("unused_signal")
signal signal_ShowRift
@warning_ignore("unused_signal")
signal signal_RequestRiftFights(rift_instance_id: String)
@warning_ignore("unused_signal")
signal signal_RequestRiftFightLog(rift_instance_id: String, fight_uid: String)
