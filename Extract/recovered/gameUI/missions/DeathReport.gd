extends CanvasLayer







signal closed

const DeathExileCardScene: = preload("res://gameUI/missions/DeathExileCard.tscn")

@onready var header: Label = %Header
@onready var card_list: VBoxContainer = %CardList
@onready var close_button: Button = %CloseButton
@onready var tooltip: NonKeywordTooltipPanel = %NonKeywordTooltipPanel


func _ready() -> void :
    close_button.pressed.connect(_on_close_pressed)





func populate(exiles: Array[ExileData], encounter_outcomes: Array) -> void :


    for child in card_list.get_children():
        child.queue_free()

    if exiles.size() == 1:
        header.text = "Fallen - %s" % exiles[0].name
    else:
        header.text = "Fallen (%d)" % exiles.size()

    for exile in exiles:
        var card: DeathExileCard = DeathExileCardScene.instantiate()
        card_list.add_child(card)
        var found: = _find_combat_for_exile(exile, encounter_outcomes)
        if found.is_empty():


            card.populate(exile, null, -1, tooltip)
        else:
            card.populate(exile, found["combat_result"], found["combatant_id"], tooltip)









func _find_combat_for_exile(exile: ExileData, encounter_outcomes: Array) -> Dictionary:

    for i in range(encounter_outcomes.size() - 1, -1, -1):
        var outcome: Dictionary = encounter_outcomes[i]
        var cr: CombatResultData = outcome.get("combat_result")
        if cr == null:
            continue
        for idx in cr.combatants.size():
            var combatant: CombatantData = cr.combatants[idx]
            if combatant.source_exile == exile and combatant.was_downed:
                return {"combat_result": cr, "combatant_id": idx}
    return {}


func _on_close_pressed() -> void :
    closed.emit()
    queue_free()
