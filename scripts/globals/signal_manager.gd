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
signal signal_StepsSimulateOffline(amount)
@warning_ignore("unused_signal")
signal signal_StepsReceivedFromServer(amount)
@warning_ignore("unused_signal")
signal signal_StepToastUpdate(steps: int, loot: Dictionary, mapping: Dictionary, new_items: Array)
@warning_ignore("unused_signal")
signal signal_GameNotification(message: String, color: Color)

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
@warning_ignore("unused_signal")
signal signal_TravelCostRequest(location_id: int)
@warning_ignore("unused_signal")
signal signal_TravelCostReceived(location_id: int, steps: int)
@warning_ignore("unused_signal")
signal signal_TravelPassingThrough(location_name: String)

# Avatar signals
@warning_ignore("unused_signal")
signal signal_ShowAvatars
@warning_ignore("unused_signal")
signal signal_AvatarChanged(avatar_id: int)

# Disenchant signals
@warning_ignore("unused_signal")
signal signal_DisenchantItem(item_uid: String)
@warning_ignore("unused_signal")
signal signal_DisenchantResultReceived(data: Dictionary)

# Rift signals
@warning_ignore("unused_signal")
signal signal_ShowRift(location_id: int)
@warning_ignore("unused_signal")
signal signal_RequestRiftFights(rift_instance_id: String)
@warning_ignore("unused_signal")
signal signal_RequestRiftFightLog(rift_instance_id: String, fight_uid: String)
@warning_ignore("unused_signal")
signal signal_RequestRiftHistory

# Profession signals
@warning_ignore("unused_signal")
signal signal_ShowProfession(profession_name: String)
@warning_ignore("unused_signal")
signal signal_RequestProfessionInfo(profession: String)
@warning_ignore("unused_signal")
signal signal_ProfessionInfoReceived(data: Dictionary)
@warning_ignore("unused_signal")
signal signal_StartCraftActivity(activity: int, activity_site: int, recipe_id: String, target_qty: int)

# ── Achievements ──────────────────────────────────────────────────────────────
@warning_ignore("unused_signal")
signal signal_RequestAchievements
@warning_ignore("unused_signal")
signal signal_ClaimAchievement(achievement_id: int, chosen_attr)
@warning_ignore("unused_signal")
signal signal_SetActiveTitle(title_id)   # null/0 clears
@warning_ignore("unused_signal")
signal signal_AchievementsReceived(data: Dictionary)
@warning_ignore("unused_signal")
signal signal_AchievementClaimed(data: Dictionary)
@warning_ignore("unused_signal")
signal signal_AchievementReady(ready_ids: Array)
@warning_ignore("unused_signal")
signal signal_ActiveTitleSet(active_title)
@warning_ignore("unused_signal")
signal signal_RequestStepStats(period: String)
@warning_ignore("unused_signal")
signal signal_StepStatsReceived(data: Dictionary)
@warning_ignore("unused_signal")
signal signal_TalentAllocate(talent_id: String)
@warning_ignore("unused_signal")
signal signal_TalentRespec()
@warning_ignore("unused_signal")
signal signal_TalentCheatPoints(points: int)
