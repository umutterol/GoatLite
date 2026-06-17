











class_name EquipmentScreen
extends Panel

const CurrencyFlyPipScene: = preload("res://gameUI/smallComponents/CurrencyFlyPip.tscn")
const ChaosTexture: = preload("res://assets/sprites/itemSprites/currencySprites/ChaosShardPhysical.png")
const ScrapTexture: = preload("res://assets/sprites/itemSprites/currencySprites/ScrapPhysical.png")
const CraftingModalScene: = preload("res://gameUI/inventory/crafting/CraftingModal.tscn")


const PIP_SPAWN_STAGGER: float = 0.04

@onready var title_label: Label = $MarginContainer / VBoxContainer / Header / Title
@onready var close_button: Button = $MarginContainer / VBoxContainer / Header / CloseButton
@onready var slots_container: Control = %SlotsContainer
@onready var inventory_grid: InventoryGrid = $MarginContainer / VBoxContainer / InventoryGrid
@onready var salvage_panel: VBoxContainer = %SalvagePanel
@onready var salvage_grid: SalvageGrid = %SalvageGrid
@onready var scrap_button: Button = %Scrapbtn
@onready var salvage_confirm: Button = %SalvageConfirmButton
@onready var close_salvage_btn: Button = %CloseSalvageButton




@onready var craft_button: Button = %Craftbtn
@onready var sort_button: TextureButton = %SortButton

var exile: ExileData = null
var _slots: Dictionary = {}
var _salvage_open: bool = false



var _crafting_modal: CraftingModal = null

func _ready() -> void :
    close_button.pressed.connect(_close)
    _wire_slots()
    inventory_grid.equipped_item_dropped.connect(_on_equipped_item_dropped)
    inventory_grid.item_right_clicked.connect(_on_stash_item_right_clicked)


    EquipmentManager.equip_rejected_no_space.connect(_on_equip_rejected_no_space)


    scrap_button.pressed.connect(_open_salvage_panel)
    salvage_confirm.pressed.connect(_on_salvage_confirm_pressed)
    close_salvage_btn.pressed.connect(_on_close_salvage_pressed)
    salvage_grid.item_right_clicked.connect(_on_salvage_item_right_clicked)




    craft_button.pressed.connect(_toggle_crafting_modal)

    sort_button.pressed.connect(inventory_grid.sort_active_tab)


    salvage_grid.items_changed.connect(_refresh_salvage_confirm_state)
    _refresh_salvage_confirm_state()



    SaveManager.save_started.connect(_on_save_started)
    hide()



func _wire_slots() -> void :
    for child in slots_container.get_children():
        if child is EquipmentSlot:
            var slot: EquipmentSlot = child
            slot.item_equip_requested.connect(_on_item_equip_requested)
            slot.item_unequip_requested.connect(_on_item_unequip_requested)
            _slots[slot.slot_type] = slot



func open(p_exile: ExileData) -> void :
    exile = p_exile
    title_label.text = "%s — Equipment" % exile.name
    _refresh_slots()


    ItemTooltip.set_comparison_context(exile)
    show()

func _close() -> void :


    if _salvage_open:
        _close_salvage_panel()
    if _is_modal_open():
        _close_crafting_modal()


    ItemTooltip.clear_comparison_context()
    hide()
    exile = null



func is_salvage_open() -> bool:
    return _salvage_open



func is_crafting_open() -> bool:
    return _is_modal_open()



func close_salvage() -> void :
    if _salvage_open:
        _close_salvage_panel()


func close_crafting() -> void :
    if _is_modal_open():
        _close_crafting_modal()

func _refresh_slots() -> void :
    for slot_type in _slots:
        (_slots[slot_type] as EquipmentSlot).set_exile(exile)




func _on_item_equip_requested(item: Item, slot: ItemEnums.EquipSlot) -> void :
    if exile == null:
        return




    var from_bench: bool = _crafting_modal != null and _crafting_modal.has_item(item)
    if from_bench:
        var slot_info: Dictionary = GameState.find_free_stash_slot(item)
        if slot_info.is_empty():
            push_warning("EquipmentScreen: stash full — can't lift bench item '%s' for equip" % item.get_display_name())
            return
        item.stash_tab = int(slot_info.get("tab", 0))
        item.stash_position = slot_info.get("position", Vector2i(-1, -1))
        GameState.add_item_to_stash(item)
        _crafting_modal.release_held_item()
    EquipmentManager.equip_item_to_slot(exile, item, slot)
    _refresh_slots()

func _on_item_unequip_requested(slot: ItemEnums.EquipSlot) -> void :
    if exile == null:
        return




    if Input.is_key_pressed(KEY_CTRL):
        var slot_key: String = ItemEnums.EquipSlot.keys()[slot]
        var item: Item = exile.equipped_items.get(slot_key, null)
        if item != null:
            _send_to_crafting_modal_from_equipment(item, slot)
            return
    EquipmentManager.unequip_item(exile, slot)
    _refresh_slots()





func _on_equipped_item_dropped(item: Item) -> void :



    if _salvage_open and salvage_grid.has_item(item):
        salvage_grid.remove_item(item)
        GameState.add_item_to_stash(item)
        return




    if _crafting_modal != null and _crafting_modal.has_item(item):
        _crafting_modal.release_held_item()
        GameState.add_item_to_stash(item)
        return

    if exile == null:
        return


    for slot_key in exile.equipped_items:
        if exile.equipped_items[slot_key] == item:
            var slot = ItemEnums.EquipSlot[slot_key]
            EquipmentManager.unequip_item(exile, slot)
            _refresh_slots()
            return






func _on_stash_item_right_clicked(item: Item) -> void :
    if _salvage_open:
        var moved: bool = salvage_grid.receive_from_stash(item)
        if not moved:
            push_warning("EquipmentScreen: salvage bin full — couldn't accept '%s'" % item.get_display_name())
        return



    if Input.is_key_pressed(KEY_CTRL):
        _send_to_crafting_modal_from_stash(item)
        return
    if exile == null:
        return




    if Input.is_key_pressed(KEY_ALT)\
and item.base_item != null\
and item.base_item.category == ItemEnums.ItemCategory.JEWELLERY\
and item.base_item.jewellery_type == ItemEnums.JewelleryType.RING:
        EquipmentManager.equip_item_to_slot(exile, item, ItemEnums.EquipSlot.RING_RIGHT)
        _refresh_slots()
        return
    EquipmentManager.equip_item(exile, item)
    _refresh_slots()



func _on_salvage_item_right_clicked(item: Item) -> void :
    _return_item_to_stash(item)





func _on_equip_rejected_no_space(p_exile: ExileData, slot: ItemEnums.EquipSlot) -> void :
    if exile == null or p_exile != exile:
        return
    var slot_node: EquipmentSlot = _slots.get(slot, null)
    if slot_node != null:
        slot_node.flash_reject()




func _open_salvage_panel() -> void :



    if _salvage_open:
        _close_salvage_panel()
        return


    if _is_modal_open():
        _close_crafting_modal()
    _salvage_open = true



    title_label.visible = false
    slots_container.visible = false
    salvage_panel.visible = true
    _refresh_salvage_confirm_state()






func _close_salvage_panel() -> void :
    if not _salvage_open:
        return

    var pending: Array[Item] = salvage_grid.get_items()
    for item in pending:
        _return_item_to_stash(item)


    for orphan in salvage_grid.get_items():
        salvage_grid.remove_item(orphan)
    _salvage_open = false
    salvage_panel.visible = false
    slots_container.visible = true
    title_label.visible = true
    _refresh_salvage_confirm_state()


func _on_close_salvage_pressed() -> void :
    _close_salvage_panel()








func _ensure_crafting_modal() -> void :
    if _crafting_modal != null:
        return
    _crafting_modal = CraftingModalScene.instantiate()


    var host: Node = get_parent()
    if host == null:
        host = self
    host.add_child(_crafting_modal)
    _crafting_modal.close_requested.connect(_on_modal_close_requested)


func _is_modal_open() -> bool:
    return _crafting_modal != null and _crafting_modal.visible




func _toggle_crafting_modal() -> void :
    _ensure_crafting_modal()
    if _crafting_modal.visible:
        _close_crafting_modal()
        return


    if _salvage_open:
        _close_salvage_panel()
    _crafting_modal.set_current_exile(exile)
    _crafting_modal.show_modal()


func _close_crafting_modal() -> void :
    if _crafting_modal == null:
        return
    _crafting_modal.close_modal()

    _refresh_slots()



func _on_modal_close_requested() -> void :
    _close_crafting_modal()




func _send_to_crafting_modal_from_stash(item: Item) -> void :
    _ensure_crafting_modal()
    if _salvage_open:
        _close_salvage_panel()
    _crafting_modal.set_current_exile(exile)
    if not _crafting_modal.send_from_stash(item):
        push_warning("EquipmentScreen: bench rejected '%s' (slot full / corrupted / currency)" % item.get_display_name())




func _send_to_crafting_modal_from_equipment(item: Item, slot: ItemEnums.EquipSlot) -> void :
    if exile == null:
        return
    _ensure_crafting_modal()
    if _salvage_open:
        _close_salvage_panel()
    _crafting_modal.set_current_exile(exile)
    if not _crafting_modal.send_from_equipment(item, exile, slot):
        push_warning("EquipmentScreen: bench rejected equipped '%s'" % item.get_display_name())
    _refresh_slots()






func _on_save_started(_slot: int) -> void :
    if _salvage_open:
        _close_salvage_panel()
    if _is_modal_open():
        _close_crafting_modal()






func _on_salvage_confirm_pressed() -> void :
    var items: Array[Item] = salvage_grid.get_items()
    if items.is_empty():
        return

    var vfx_host: Node = _vfx_host()


    var delay: float = 0.0

    for item in items:
        var item_origin: Vector2 = _item_global_centroid(item)
        var yields: Dictionary = SalvageCalculator.salvage_yield(item)
        var scrap_count: int = int(yields.get("scrap", 0))
        var chaos_count: int = int(yields.get("chaos", 0))

        for i in scrap_count:
            _spawn_fly_pip(vfx_host, item_origin, 
                _scrap_target_global(), ScrapTexture, 
                func() -> void : GameState.add_scrap(1), 
                delay)
            delay += PIP_SPAWN_STAGGER

        for i in chaos_count:
            _spawn_fly_pip(vfx_host, item_origin, 
                _chaos_target_global(), ChaosTexture, 
                func() -> void : GameState.add_chaos(1), 
                delay)
            delay += PIP_SPAWN_STAGGER

        salvage_grid.remove_item(item)

    salvage_grid.items_changed.emit()
    _refresh_salvage_confirm_state()




func _refresh_salvage_confirm_state() -> void :
    if salvage_confirm == null:
        return
    salvage_confirm.disabled = salvage_grid.get_items().is_empty()







func _return_item_to_stash(item: Item) -> bool:
    var slot: Dictionary = GameState.find_free_stash_slot(item)
    if slot.is_empty():
        push_warning("EquipmentScreen: stash full, can't return '%s'" % item.get_display_name())
        return false
    salvage_grid.remove_item(item)
    item.stash_tab = int(slot.get("tab", 0))
    item.stash_position = slot.get("position", Vector2i(-1, -1))
    GameState.add_item_to_stash(item)


    salvage_grid.items_changed.emit()
    return true





func _spawn_fly_pip(
    host: Node, 
    start_global: Vector2, 
    end_global: Vector2, 
    texture: Texture2D, 
    on_arrive: Callable, 
    delay: float, 
) -> void :
    if host == null:

        on_arrive.call()
        return
    if delay <= 0.0:
        var pip: CurrencyFlyPip = CurrencyFlyPipScene.instantiate()
        host.add_child(pip)
        pip.spawn(start_global, end_global, texture, on_arrive)
        return

    get_tree().create_timer(delay).timeout.connect( func() -> void :
        var pip: CurrencyFlyPip = CurrencyFlyPipScene.instantiate()
        host.add_child(pip)
        pip.spawn(start_global, end_global, texture, on_arrive)
    )







func _vfx_host() -> Node:
    var parent: Node = get_parent()
    return parent if parent != null else self





func _item_global_centroid(item: Item) -> Vector2:
    if item == null or item.base_item == null:
        return salvage_grid.global_position
    var grid_origin: Vector2 = salvage_grid.global_position
    var cell: int = salvage_grid.cell_size
    var pos: Vector2i = item.stash_position


    if pos == Vector2i(-1, -1):
        return grid_origin + Vector2(
            salvage_grid.columns * cell * 0.5, 
            salvage_grid.rows * cell * 0.5, 
        )
    return grid_origin + Vector2(
        (pos.x + item.base_item.grid_width * 0.5) * cell, 
        (pos.y + item.base_item.grid_height * 0.5) * cell, 
    )






func _scrap_target_global() -> Vector2:
    return _resource_counter_global("ScrapPanel")


func _chaos_target_global() -> Vector2:
    return _resource_counter_global("ChaosPanel")


func _resource_counter_global(panel_name: String) -> Vector2:
    var bar: Node = get_tree().current_scene.find_child("ResourceBar", true, false)
    if bar == null:
        return get_viewport_rect().size * Vector2(0.5, 0.05)
    var panel: Control = bar.get_node_or_null(panel_name) as Control
    if panel == null:
        return bar.global_position
    return panel.global_position + panel.size * 0.5
