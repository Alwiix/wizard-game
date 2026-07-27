class_name ContentCatalog
extends RefCounted


const FIRE_CARD_DATA: ElementCardData = preload(
	"res://Data/elements/fire_card.tres"
)
const AIR_CARD_DATA: ElementCardData = preload(
	"res://Data/elements/air_card.tres"
)
const WATER_CARD_DATA: ElementCardData = preload(
	"res://Data/elements/water_card.tres"
)
const EARTH_CARD_DATA: ElementCardData = preload(
	"res://Data/elements/earth_card.tres"
)
const LIGHTNING_CARD_DATA: ElementCardData = preload(
	"res://Data/elements/lightning_card.tres"
)
const NATURE_CARD_DATA: ElementCardData = preload(
	"res://Data/elements/nature_card.tres"
)

const SPELL_LIBRARY: SpellLibraryData = preload(
	"res://Data/Spells/spell_library.tres"
)
const UPGRADE_LIBRARY: CardUpgradeLibraryData = preload(
	"res://Data/CardUpgrades/card_upgrade_library.tres"
)

const SKELETON_DATA: EnemyData = preload(
	"res://Data/enemy_types/skeleton.tres"
)
const ZOMBIE_DATA: EnemyData = preload(
	"res://Data/enemy_types/zombie.tres"
)
const FIRST_LEVEL: LevelData = preload(
	"res://Data/levels/first_level.tres"
)


static func get_all_elements() -> Array[ElementCardData]:
	return [
		WATER_CARD_DATA,
		FIRE_CARD_DATA,
		EARTH_CARD_DATA,
		LIGHTNING_CARD_DATA,
		AIR_CARD_DATA,
		NATURE_CARD_DATA
	]


static func get_reward_elements() -> Array[ElementCardData]:
	return [
		WATER_CARD_DATA,
		AIR_CARD_DATA,
		LIGHTNING_CARD_DATA
	]


static func get_all_enemies() -> Array[EnemyData]:
	return [SKELETON_DATA, ZOMBIE_DATA]


static func get_all_levels() -> Array[LevelData]:
	return [FIRST_LEVEL]
