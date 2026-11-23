extends RefCounted
## Adendo tático do Ato I (Spec_Pendencias §4, aprovado): Cike, Catafractário, Conselheiro
## Yuefu -> Junshi; Daoshi como promoção do Fangshi; Xian exige o Elixir de Pengming.
## Emite ACT1_ADENDO_PASS.

const C := "res://eras/act_01_tianxu/classes/%s.tres"
const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"


func _cls(id: String) -> UnitClassData:
	return load(C % id) as UnitClassData


func run(t: Node) -> void:
	var failed_before: int = t.failed
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	var era: EraConfig = WorldState.era_config
	var ids: Array = era.unit_classes.map(func(c: UnitClassData) -> String: return c.class_id)
	t.check("adendo_classes_registered", ["cike", "catafractario", "conselheiro_yuefu", "junshi"].all(
		func(id: String) -> bool: return id in ids) and era.item_catalog.any(func(i: ItemData) -> bool: return i.item_id == "elixir_pengming"))

	# Parte 1: novas promoções.
	var cike := _cls("cike")
	var cata := _cls("catafractario")
	var junshi := _cls("junshi")
	t.check("adendo_tree_part1", _cls("nubing_crossbow").promotion_evil == cike and _cls("ji_halberdier").promotion_good == cata
		and _cls("conselheiro_yuefu").promotion_good == junshi and _cls("conselheiro_yuefu").tier == 1
		and cike.tier == 2 and cata.tier == 2 and junshi.tier == 2
		and cike.archetype == UnitClassData.Archetype.RANGED_STEALTH and cata.archetype == UnitClassData.Archetype.SHOCK
		and junshi.archetype == UnitClassData.Archetype.BARD_INFLUENCE)
	t.check("adendo_requirements", cike.min_level == 9 and cike.max_alignment == 35 and cata.min_level == 10
		and cata.min_alignment == 60 and junshi.min_level == 11 and junshi.min_alignment == 60)
	var archer := UnitInstance.create(_cls("nubing_crossbow"), "Besteiro", 9, 3, false, 20)
	var halberd := UnitInstance.create(_cls("ji_halberdier"), "Alabardeiro", 10, 0, false, 70)
	var advisor := UnitInstance.create(_cls("conselheiro_yuefu"), "Conselheiro", 11, 4, false, 75)
	t.check("adendo_promotions_reachable", PromotionRules.promote(archer, cike) and PromotionRules.promote(halberd, cata)
		and PromotionRules.promote(advisor, junshi))
	t.check("adendo_combat_identity", cike.back_action.inflicts_status == "POISON"
		and cike.back_action.targeting == ActionSkillData.Targeting.LEADER and cata.movement == "cavalry"
		and cata.back_action.ally_guard_pct > 0 and junshi.back_action.grants_extra_action)
	var band := SquadData.new()
	band.units.append_array([UnitInstance.create(_cls("fubing"), "Soldado", 6, 0, true), advisor])
	var foe := SquadData.new()
	foe.units.append(UnitInstance.create(_cls("fubing"), "Alvo", 6, 0, true))
	t.check("adendo_junshi_extra_action", CombatResolver.resolve(band, foe).any(func(e: Dictionary) -> bool: return e["type"] == "extra_action"))

	# Conflito A: Daoshi é promoção (tier 2) do Fangshi.
	var daoshi := _cls("daoshi_healer")
	var fangshi := _cls("fangshi")
	var adept := UnitInstance.create(fangshi, "Adepto", 9, 3, false, 70)
	var not_yet: bool = adept.get_eligible_promotions().all(func(c: UnitClassData) -> bool: return c != daoshi)
	adept.level = 10
	t.check("adendo_daoshi_is_fangshi_promotion", fangshi.promotion_good == daoshi and daoshi.tier == 2
		and daoshi.min_level == 10 and daoshi.min_alignment == 60 and not_yet and PromotionRules.promote(adept, daoshi))

	# Conflito B: Xian exige o Elixir de Pengming (e não mais o talismã).
	var xian := _cls("xian")
	var seeker := UnitInstance.create(fangshi, "Buscador", 6, 3, false, 90)
	var blocked: bool = not PromotionRules.promote(seeker, xian)
	WorldState.add_item(load("res://eras/act_01_tianxu/items/talisma_cinabrio.tres"))
	var still_blocked: bool = not PromotionRules.promote(seeker, xian)
	WorldState.add_item(load("res://eras/act_01_tianxu/items/elixir_pengming.tres"))
	t.check("adendo_xian_needs_elixir", xian.required_item_id == &"elixir_pengming" and blocked and still_blocked
		and PromotionRules.promote(seeker, xian) and WorldState.count_item("elixir_pengming") == 0
		and WorldState.count_item("talisma_cinabrio") == 1)

	_test_ledger_tree(t)
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	await t.get_tree().process_frame
	if t.failed == failed_before:
		print("ACT1_ADENDO_PASS")


## Árvores do Ato I alinhadas ao STATE_LEDGER de lore v2:
## Fubing -> Youxia/Buqu · Alabardeiro -> Catafractário/Saqueador · Nubing -> Arqueiro Montado/Cike ·
## Fangshi -> Daoshi/Alquimista Sombrio · Médico -> Monge/Xamã Wu · Conselheiro -> Junshi/Legalista.
const LEDGER_TREE: Dictionary = {
	"fubing": ["youxia", "buqu"], "ji_halberdier": ["catafractario", "saqueador_estepes"],
	"nubing_crossbow": ["arqueiro_montado", "cike"], "fangshi": ["daoshi_healer", "alquimista_sombrio"],
	"medico_imperial": ["monge_taoista", "wu_sombrio"], "conselheiro_yuefu": ["junshi", "intrigante_legalista"],
}


func _test_ledger_tree(t: Node) -> void:
	var ok: bool = true
	var detail: Array[String] = []
	for base: String in LEDGER_TREE:
		var cls := _cls(base)
		var pair: Array = [cls.promotion_good.class_id if cls.promotion_good else "", cls.promotion_evil.class_id if cls.promotion_evil else ""]
		if pair != LEDGER_TREE[base]:
			ok = false
			detail.append("%s=%s" % [base, pair])
	t.check("ledger_tree_act1", ok, str(detail))
	var wu := _cls("wu_sombrio")
	var alchemist := _cls("alquimista_sombrio")
	t.check("ledger_items_moved", alchemist.required_item_id == &"talisma_cinabrio" and wu.required_item_id == &""
		and wu.min_level == 9 and wu.max_alignment == 40 and _cls("xian").required_item_id == &"elixir_pengming")
	var era := load(ACT01) as EraConfig
	var ids: Array = era.unit_classes.map(func(c: UnitClassData) -> String: return c.class_id)
	var all_registered: bool = true
	for base: String in LEDGER_TREE:
		all_registered = all_registered and base in ids and LEDGER_TREE[base].all(func(id: String) -> bool: return id in ids)
	t.check("ledger_tree_registered", all_registered)
	var a2_tarasca := load("res://eras/act_02_occitania/classes/tarasca.tres") as UnitClassData
	var a2_erudito := load("res://eras/act_02_occitania/classes/erudito_boticario.tres") as UnitClassData
	t.check("ledger_tree_act2", a2_erudito.promotion_evil.class_id == "ocultista" and a2_tarasca.display_name == "Domador da Tarasca"
		and a2_tarasca.grid_slots == 2)
