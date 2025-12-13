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

# Inventory and equipment signals
@warning_ignore("unused_signal")
signal signal_RequestInventory(action)
@warning_ignore("unused_signal")
signal signal_EquipItem(slot_name: String, item_id: String)
@warning_ignore("unused_signal")
signal signal_UnequipItem(slot_name: String, item_id: String)
@warning_ignore("unused_signal")
signal signal_UseItem(definition: Dictionary)
