class_name CardUpgradeLibraryData
extends Resource


@export var upgrades: Array[CardUpgradeData] = []


func find_upgrade(upgrade_id_value: StringName) -> CardUpgradeData:
	var normalized_id: StringName = StringName(
		String(upgrade_id_value).to_lower()
	)

	for upgrade in upgrades:
		if upgrade == null:
			continue

		if (
			StringName(String(upgrade.upgrade_id).to_lower())
			== normalized_id
		):
			return upgrade

	return null


func get_upgrade_ids() -> Array[StringName]:
	var upgrade_ids: Array[StringName] = []

	for upgrade in upgrades:
		if upgrade != null and upgrade.upgrade_id != &"":
			upgrade_ids.append(upgrade.upgrade_id)

	return upgrade_ids
