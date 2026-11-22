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

	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	await t.get_tree().process_frame
	if t.failed == failed_before:
		print("ACT1_ADENDO_PASS")
