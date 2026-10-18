class_name SkillData
extends Resource
## Definition of one skill: the single source of its balance numbers and look.
## Saved as .tres files (see src/data/skills/). Read by SkillController.
##
## Future systems change a skill by producing a modified copy of this data
## (modifiers, evolutions, elemental variants, equipment) before it is cast,
## so execution code never needs to know where the numbers came from.

## Stable identifier for saves, lookups and future skill trees. Never rename.
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Damage")
@export var base_damage: float = 10.0
@export var damage_type: DamageInfo.Type = DamageInfo.Type.MAGIC

@export_group("Timing")
## Seconds between casts.
@export var cooldown: float = 0.3

@export_group("Projectile")
## Scene whose root is a Projectile.
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 16.0
@export var projectile_lifetime: float = 1.2

@export_group("Visual")
## Tint of the projectile and its impact (also used by the HUD slot).
@export var color: Color = Color(0.66, 0.95, 1.0)

# Runtime cache: one shared material per skill, never saved.
var _projectile_material: StandardMaterial3D


## Approximate travel distance of the projectile, in metres.
func get_range() -> float:
	return projectile_speed * projectile_lifetime


## Shared unshaded material in this skill's colour (created once, reused by every projectile).
func get_projectile_material() -> Material:
	if _projectile_material == null:
		_projectile_material = StandardMaterial3D.new()
		_projectile_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_projectile_material.albedo_color = color
	return _projectile_material
