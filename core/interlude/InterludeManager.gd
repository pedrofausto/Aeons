class_name InterludeManager
extends RefCounted
## Lê WorldState + EssenceState para decidir quais interlúdios ainda são elegíveis.
## - Atos I–IV: cada timeline toca uma vez por ato (WorldState.completed_interludes).
## - Estilo "ephemeral_metaphysical" (Ato V): encontros únicos que nunca se repetem,
##   nem entre atos (EssenceState.ephemeral_meetings_seen).
## As timelines do Dialogic podem ramificar lendo autoloads direto, ex.: {WorldState.alignment}.

const EPHEMERAL_STYLE: String = "ephemeral_metaphysical"


static func meeting_id(timeline_path: String) -> String:
	return timeline_path.get_file().get_basename()


static func is_ephemeral(era: EraConfig) -> bool:
	return era != null and era.interlude_style == EPHEMERAL_STYLE


static func is_eligible(timeline_path: String, era: EraConfig) -> bool:
	if timeline_path.is_empty() or timeline_path in WorldState.completed_interludes:
		return false
	if is_ephemeral(era) and meeting_id(timeline_path) in EssenceState.ephemeral_meetings_seen:
		return false
	return true


static func mark_played(timeline_path: String, era: EraConfig) -> void:
	if timeline_path not in WorldState.completed_interludes:
		WorldState.completed_interludes.append(timeline_path)
	if is_ephemeral(era):
		EssenceState.mark_ephemeral_meeting(meeting_id(timeline_path))


## Material de dissolução para encontros efêmeros (nulo nos demais estilos).
static func overlay_material(era: EraConfig) -> ShaderMaterial:
	if not is_ephemeral(era) or era.dissolve_interlude_shader == null:
		return null
	var material := ShaderMaterial.new()
	material.shader = era.dissolve_interlude_shader
	return material
