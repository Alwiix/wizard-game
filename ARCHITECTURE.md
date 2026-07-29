# Wizard Deckbuilder Architecture

## Content authoring

Game content remains Godot resources under `Data/`:

- `elements/` contains element cards.
- `Spells/` contains spell definitions.
- `Spell_recipes/` maps element combinations to spells.
- `CardUpgrades/` contains one resource per upgrade and its library.
- `enemy_types/`, `encounters/`, and `levels/` build the run.

`ContentCatalog` is the runtime entry point for these libraries.
`ContentValidator` checks IDs, recipes, references, statuses, properties,
enemies, encounters, and levels. Its test should be updated whenever a new
content library is introduced.

## Combat runtime

Authored `CombatEffectData` resources are immutable templates. At runtime:

1. A spell or enemy move creates a `CombatAction`.
2. `CombatContext` supplies the player, enemy roster, selected target, deck,
   and arena modifiers.
3. `CombatPropertyRegistry` expands the action into typed
   `ResolvedCombatEffect` instances.
4. `CombatEffectResolver` executes those effects.
5. `CombatResult` reports messages, healing, and damage per target.

Energy cost belongs to `SpellData`. Selected card upgrades contribute
spell-cost modifiers, so element cards act as ingredients rather than each
charging their full printed cost.

Upgrade placement is the selected ingredient order for the current cast.
`CardUpgradeData.active_cast_slots` is zero-based; an empty list works in
every slot. White Gem and Blue Gem are currently restricted to slot `0`.

New combat properties belong in `combat/properties/` as one handler per
property and must be registered in `CombatPropertyRegistry`.

New target patterns should be added to `CombatEffectData.TargetType` and
resolved in `CombatContext.resolve_targets()`.

## Combatants and statuses

`BattleCombatant` owns behavior shared by players and enemies: health,
healing, damage, status access, defeat events, and combat events.
Player- or enemy-specific scripts should only implement their unique
resources, UI, energy, persistence, and move behavior.

Statuses live one per file in `statuses/effects/` and are created through
`StatusRegistry`. Interactions between statuses live in
`statuses/interactions/`; they should not be added as special cases to
`StatusController`.

Wet/Electrified is an immediate discharge interaction. Applying either
status while the other is present deals Lightning damage equal to all
Electrified stacks, then removes Electrified. Frozen uses consumable stacks,
with each stack skipping one action.

Creeping Vines and Oil are permanent resource statuses. Applying Wet to a
target that already has Creeping Vines adds one Vine. Seeping Oil converts
up to three Vines on each affected enemy into the same number of Oil stacks.
Ignite consumes all Oil on damaged targets, applies an equal amount of Burn,
and deals 8 additional damage when at least 5 Oil was consumed. Gust adds
one additional Cold or Burn when damaging a target that already has that
status.

Muddy reduces all outgoing damage by 25 percent and loses one stack at the
end of its owner's turn. Applying Wet removes existing Muddy, but Wet does
not prevent a later Muddy application. Firebreathing is capped at one stack,
lasts three turns, and adds one to each outgoing Burn application. Statuses
modify outgoing actions through `StatusController`; property handlers
remain responsible for action-level transformations.

## Battle and run flow

`BattleController` owns encounter construction, enemy rosters, selected
targets, combat contexts, action resolution, and turn-side processing.
`scenes/battle/battle.gd` owns input and presentation.

An encounter can use the legacy `enemy_data` field for one enemy or the
`enemies` array for an ordered roster. Enemy move order remains local to each
enemy, and the roster determines enemy turn order.

`RunFlow` owns the high-level leyline map, battle, reward, transition,
completion, and defeat phases. Persistent run data belongs in `RunState`.

Runs begin with one card from each of the six elements. Turn draws refill
the hand to three cards rather than always drawing three additional cards,
so retained cards count toward the normal hand size. Reaching twelve deck
cards permanently increases that run's refill size to four, even if the
deck is subsequently thinned.

`LeylineMapData` contains the authored web of `LeylineLocationData`
resources. Locations declare their connections, elemental affinity, map
position, encounter, and behavior. `RunState` records the current location,
cleared locations, sealed rifts, and instability. Every travelled edge adds
instability, which currently increases enemy health by three percent.

Combat location affinities open the full element catalog for that reward
and guarantee a matching element among its three choices. Unaligned rewards
continue to use the wizard's normal reward pool. The final convergence
remains sealed until the configured number of rifts have been completed.

## Compatibility

Dictionary conversion methods remain for UI previews and older tests.
New gameplay code should use `CombatAction`, `CombatContext`, and
`CombatResult` rather than adding new dictionary-based combat paths.
