extends Node

# Account signals
@warning_ignore("unused_signal")
signal signal_CreateUser(user, password)
@warning_ignore("unused_signal")
signal signal_LoginUser(user, password)
@warning_ignore("unused_signal")
signal signal_LoginToken(token)
@warning_ignore("unused_signal")
signal signal_LoginGoogle(id_token)

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

# Recipe-scroll learn flow.
# Emit signal_UseRecipeScroll(recipe_id, item_uid) from the inventory action
# (long-press on a scroll item -> "Learn Recipe" -> confirm). ServerConnector
# forwards to the WS handler; signal_RecipeScrollResult fires when the server
# returns {status: "learned"|"already_known"} or rejects with an error.
@warning_ignore("unused_signal")
signal signal_UseRecipeScroll(recipe_id: String, item_uid: String)
@warning_ignore("unused_signal")
signal signal_RecipeScrollResult(data: Dictionary)

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

# ── Quests ──────────────────────────────────────────────────────────────────
# Request to open an NPC's dialogue (carries npc_uid); QuestManager sends the
# resolve_npc_dialogue RPC. signal_NpcDialogueReceived fires with the resolved
# line. signal_QuestTurnedIn / signal_QuestCompletedToast drive the reward modal.
@warning_ignore("unused_signal")
signal signal_RequestNpcDialogue(npc_uid: String)
@warning_ignore("unused_signal")
signal signal_NpcDialogueReceived(data: Dictionary)
@warning_ignore("unused_signal")
signal signal_AcceptQuest(quest_uid: String)
@warning_ignore("unused_signal")
signal signal_QuestTurnedIn(data: Dictionary)
@warning_ignore("unused_signal")
signal signal_QuestCompletedToast(data: Dictionary)
@warning_ignore("unused_signal")
signal signal_LocationNpcsReceived(data: Dictionary)
