























extends Control

const ExileGuildCardScene = preload("res://gameUI/guild/exileGuildCard/ExileGuildCard.tscn")
const EndOfDayReportScene = preload("res://gameUI/guild/EndOfDayReport.tscn")
const DeathReportScene = preload("res://gameUI/missions/DeathReport.tscn")
const GuildMenuModalScene = preload("res://gameUI/guild/GuildMenuModal.tscn")
const MessageModalScene: = preload("res://gameUI/smallComponents/MessageModal.tscn")





@onready var center_core: VBoxContainer = $TopButtonsV / CenterCore
@onready var left_bench: VBoxContainer = $LeftBench
@onready var right_bench: VBoxContainer = $RightBench
@onready var character_sheet = $CharacterSheet
@onready var equipment_screen = $EquipmentScreen
@onready var quartermaster_window: QuartermasterWindow = $TopButtonsV / QuartermasterWindow
@onready var tactics_window: TacticsWindow = $TopButtonsV / TacticsWindow
@onready var dismiss_layer = $DismissLayer
@onready var missions_button: Button = %MissionsButton
@onready var end_day_button: Button = %EndDayButton
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var settings_button: Button = %SettingsButton
@onready var menu_button: Button = %MenuButton
@onready var autosave_toast: AutosaveToast = %AutosaveToast
@onready var fade_in_overlay: ColorRect = $FadeInOverlay





const FADE_IN_SECONDS: float = 1.2

var _focused_exile: ExileData = null
var _cards: Array[ExileGuildCard] = []


var _menu_modal: GuildMenuModal = null


func _ready() -> void :
    dismiss_layer.gui_input.connect(_on_dismiss_input)
    missions_button.pressed.connect(_on_missions_pressed)
    end_day_button.pressed.connect(_on_end_day_pressed)
    save_button.pressed.connect(_on_save_pressed)
    load_button.pressed.connect(_on_load_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    menu_button.pressed.connect(_on_menu_pressed)



    SaveManager.save_completed.connect(_on_save_completed)
    SaveManager.save_failed.connect(_on_save_failed)
    SaveManager.load_completed.connect(_on_load_completed)
    SaveManager.load_failed.connect(_on_load_failed)




    character_sheet.visibility_changed.connect(_refresh_card_highlights)
    equipment_screen.visibility_changed.connect(_refresh_card_highlights)
    quartermaster_window.visibility_changed.connect(_refresh_card_highlights)
    tactics_window.visibility_changed.connect(_refresh_card_highlights)



    GameState.day_changed.connect(_on_day_changed)


    GameState.game_loaded.connect(_refresh_seats)



    GameState.exile_added.connect(_on_exile_added)


    GameState.seats_changed.connect(_refresh_seats)


    GameState.exile_died.connect(_on_exile_died)




    GameState.exile_dismissed.connect(_on_exile_dismissed)
    _refresh_seats()
    $Campfire.play("CampfireBurning")
    _play_fade_in()


    ToastManager.resume()



    EventRecruitController.resume()


func _play_fade_in() -> void :



    if fade_in_overlay == null:
        return
    if not GameState.pending_intro_fade:
        fade_in_overlay.visible = false
        return

    GameState.pending_intro_fade = false
    fade_in_overlay.visible = true
    fade_in_overlay.color = Color(0, 0, 0, 1)
    var tween: = create_tween()
    tween.tween_property(fade_in_overlay, "color:a", 0.0, FADE_IN_SECONDS)
    tween.tween_callback( func(): fade_in_overlay.visible = false)


func _on_missions_pressed() -> void :
    SceneRouter.to_mission_board()


func _on_end_day_pressed() -> void :



    var report: = EndOfDayReportScene.instantiate()
    add_child(report)


func _on_day_changed(_new_day: int) -> void :
    _refresh_seats()


func _on_exile_added(_exile: ExileData) -> void :





    _refresh_seats()


func _on_exile_dismissed(_exile: ExileData) -> void :





    _refresh_seats.call_deferred()


func _on_exile_died(exile_id: int) -> void :
    var exile: = GameState.get_exile_by_id(exile_id)
    if not exile:
        return
    var report: = DeathReportScene.instantiate()
    add_child(report)



    var runner: MissionRunner = MissionManager.last_resolved_runner
    var outcomes: Array = runner.encounter_outcomes if runner else []
    report.populate([exile], outcomes)







func _refresh_seats() -> void :
    _clear_focus()
    _cards.clear()
    for slot in _all_slots():
        var exile_id: int = _seat_id_for(slot.zone, slot.slot_index)
        if exile_id == -1:
            slot.clear_card()
            continue
        var exile: ExileData = GameState.get_exile_by_id(exile_id)







        if exile == null or exile.status in ["dead", "dismissed", "captured", "lost", "long_lost"]:
            slot.clear_card()
            continue
        var card: ExileGuildCard = ExileGuildCardScene.instantiate()
        slot.host_card(card)
        card.setup(exile)
        card.set_backbench_mode(slot.zone == "backbench")
        card.card_clicked.connect(_on_card_clicked)
        card.card_double_clicked.connect(_on_card_double_clicked)
        card.button_pressed.connect(_on_card_button_pressed)
        _cards.append(card)







func _all_slots() -> Array[SeatSlot]:
    var result: Array[SeatSlot] = []
    for parent: Node in [center_core, left_bench, right_bench]:
        _collect_slots_recursive(parent, result)
    return result


func _collect_slots_recursive(node: Node, out: Array[SeatSlot]) -> void :
    for child in node.get_children():
        if child is SeatSlot:
            out.append(child)
        else:
            _collect_slots_recursive(child, out)





func _seat_id_for(zone: String, index: int) -> int:
    var ids: Array[int]
    if zone == "core":
        ids = GameState.core_exile_ids
    elif zone == "backbench":
        ids = GameState.backbench_exile_ids
    else:
        return -1
    if index < 0 or index >= ids.size():
        return -1
    return ids[index]






func _on_dismiss_input(event: InputEvent):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _clear_focus()


















func _unhandled_input(event: InputEvent) -> void :
    if not (event is InputEventKey and event.pressed and not event.echo):
        return
    if event.physical_keycode != KEY_ESCAPE:
        return




    if _menu_modal != null and is_instance_valid(_menu_modal):
        _menu_modal.handle_escape()
        get_viewport().set_input_as_handled()
        return

    if tactics_window.visible:
        tactics_window._close()
        get_viewport().set_input_as_handled()
        return
    if quartermaster_window.visible:
        quartermaster_window._close()
        get_viewport().set_input_as_handled()
        return


    if equipment_screen.visible and equipment_screen.is_salvage_open():
        equipment_screen.close_salvage()
        get_viewport().set_input_as_handled()
        return
    if equipment_screen.visible and equipment_screen.is_crafting_open():
        equipment_screen.close_crafting()
        get_viewport().set_input_as_handled()
        return
    if character_sheet.visible or equipment_screen.visible:
        if character_sheet.visible:
            character_sheet._close()
        if equipment_screen.visible:
            equipment_screen._close()
        get_viewport().set_input_as_handled()
        return
    if _focused_exile != null:
        _clear_focus()
        get_viewport().set_input_as_handled()
        return



    _open_menu_modal()
    get_viewport().set_input_as_handled()


func _on_card_clicked(data: ExileData, _card: ExileGuildCard) -> void :
    _set_focus(data)




    if equipment_screen.visible and equipment_screen.is_salvage_open():
        equipment_screen.close_salvage()
    if equipment_screen.visible and equipment_screen.is_crafting_open():
        equipment_screen.close_crafting()

    if character_sheet.visible:
        character_sheet.populate(data)
    if equipment_screen.visible:
        equipment_screen.open(data)
    if quartermaster_window.visible:
        quartermaster_window.populate(data)
    if tactics_window.visible:
        tactics_window.populate(data)




func _on_card_double_clicked(data: ExileData, _card: ExileGuildCard) -> void :
    _set_focus(data)
    character_sheet.populate(data)
    equipment_screen.open(data)





func _on_card_button_pressed(window_id: String, data: ExileData, _card: ExileGuildCard) -> void :
    var was_focused: bool = _focused_exile != null and _focused_exile.id == data.id
    if not was_focused:



        if equipment_screen.visible and equipment_screen.is_salvage_open():
            equipment_screen.close_salvage()
        if equipment_screen.visible and equipment_screen.is_crafting_open():
            equipment_screen.close_crafting()


        _set_focus(data)
        if character_sheet.visible:
            character_sheet.populate(data)
        if equipment_screen.visible:
            equipment_screen.open(data)
        if quartermaster_window.visible:
            quartermaster_window.populate(data)
        if tactics_window.visible:
            tactics_window.populate(data)


    match window_id:
        "sheet":
            if was_focused and character_sheet.visible:
                character_sheet._close()
            else:
                character_sheet.populate(data)
        "stash":
            if was_focused and equipment_screen.visible:
                equipment_screen._close()
            else:
                equipment_screen.open(data)
        "quartermaster":
            if was_focused and quartermaster_window.visible:
                quartermaster_window._close()
            else:



                if tactics_window.visible:
                    tactics_window._close()
                quartermaster_window.populate(data)
        "tactics":
            if was_focused and tactics_window.visible:
                tactics_window._close()
            else:
                if quartermaster_window.visible:
                    quartermaster_window._close()
                tactics_window.populate(data)
        "passives":


            LevelUpModalLauncher.launch_for(data)


func _set_focus(data: ExileData) -> void :
    _focused_exile = data
    _refresh_card_highlights()


func _clear_focus() -> void :
    _focused_exile = null
    _refresh_card_highlights()




func _refresh_card_highlights() -> void :
    var sheet_open: bool = character_sheet.visible
    var stash_open: bool = equipment_screen.visible
    var qm_open: bool = quartermaster_window.visible
    var tactics_open: bool = tactics_window.visible
    for card in _cards:
        var is_focus: bool = (
            _focused_exile != null
            and card.exile_data != null
            and card.exile_data.id == _focused_exile.id
        )
        card.set_selected(is_focus)
        card.set_window_active("sheet", is_focus and sheet_open)
        card.set_window_active("stash", is_focus and stash_open)
        card.set_window_active("quartermaster", is_focus and qm_open)
        card.set_window_active("tactics", is_focus and tactics_open)



    dismiss_layer.visible = _focused_exile != null and not (sheet_open or stash_open or qm_open or tactics_open)






func _on_save_pressed() -> void :



    SaveManager.save_to_slot(SaveManager.MANUAL_SLOT_DEFAULT, "Manual save")


func _on_load_pressed() -> void :



    var target_slot: int = SaveManager.most_recent_slot()
    if target_slot < 0:
        _flash_button(load_button, "No save")
        return






    var modal: MessageModal = MessageModalScene.instantiate()
    modal.setup(
        "Load Game", 
        "Replace current game with the most recent saved game?", 
        "Load", 
        "Cancel", 
    )
    add_child(modal)
    modal.confirmed.connect( func(): SaveManager.load_from_slot(target_slot))


func _on_settings_pressed() -> void :


    print("[Settings] TODO: settings panel not yet implemented")
    _flash_button(settings_button, "TODO")


func _on_menu_pressed() -> void :
    _open_menu_modal()




func _open_menu_modal() -> void :
    if _menu_modal != null and is_instance_valid(_menu_modal):
        return
    _menu_modal = GuildMenuModalScene.instantiate()
    _menu_modal.tree_exited.connect( func(): _menu_modal = null)
    add_child(_menu_modal)




func _flash_button(button: Button, message: String, duration: float = 1.2) -> void :
    if button == null:
        return
    var original_text: String = button.text
    button.text = message
    button.disabled = true
    var tween: = create_tween()
    tween.tween_interval(duration)
    tween.tween_callback( func():
        button.text = original_text
        button.disabled = false
    )


func _on_save_completed(slot: int) -> void :



    if slot == SaveManager.MANUAL_SLOT_DEFAULT:
        _flash_button(save_button, "Saved!")
    elif slot == SaveManager.AUTOSAVE_SLOT:
        if autosave_toast != null:
            autosave_toast.show_notification("Game Saved")


func _on_save_failed(slot: int, reason: String) -> void :
    push_warning("[SaveManager] save_failed (slot %d): %s" % [slot, reason])
    if slot == SaveManager.MANUAL_SLOT_DEFAULT:
        _flash_button(save_button, "Failed")


func _on_load_completed(_slot: int) -> void :


    _flash_button(load_button, "Loaded!")


func _on_load_failed(slot: int, reason: String) -> void :
    push_warning("[SaveManager] load_failed (slot %d): %s" % [slot, reason])
    _flash_button(load_button, "Failed")
