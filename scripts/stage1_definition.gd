extends RefCounted

# Shared by the layout, save validation, and camera setup.
const LAYOUT_VERSION := 3
const WIDTH := 10000.0
const GATE_POSITION := Vector2(9840.0, 390.0)
const EXPLORATION_OFFSET := 0.0
const CHECKPOINT_X := [1100.0, 2800.0, 9100.0]
# Logical checkpoint IDs stay stable when their physical junction moves.
const CHECKPOINTS := [["forest_1100", 1100.0], ["forest_6500", 2800.0], ["forest_10600", 9100.0]]
const SEALS := [
	["camp_moon_seal", Vector2(3900, 164), "Broken Chapel — the upper ruin"],
	["oak_moon_seal", Vector2(4900, 740), "Root Cellar beneath Hollow Oak"],
	["heartwood_moon_seal", Vector2(8320, 126), "Upper Forest Ruins — above the bridge"],
]
# Activation follows the chapter order; exploring other branches remains free.
const SEAL_GUARDS := {
	"camp_moon_seal": [],
	"oak_moon_seal": ["HeartwoodA", "HeartwoodB"],
	"heartwood_moon_seal": ["ChapelWolf", "BurialWolf"],
}
# The first camera tour reveals the open cellar entrance, not the seal inside.
const FIRST_WISP_ROUTE := [Vector2(3780, 184), Vector2(3560, 280), Vector2(3400, 328), Vector2(3380, 510)]
const REWARDS := [
	["lower_forest_petal", Vector2(1800, 344)],
	["upper_forest_petal", Vector2(4180, 44)],
	["hollow_oak_petal", Vector2(5060, 226)],
	["root_cellar_petal", Vector2(4570, 674)],
	["forgotten_grave_petal", Vector2(7340, 656)],
	["heartwood_petal", Vector2(7240, -6)],
]

# [id, x, surface_y, optional, jumps, pack]. Large stretches have no enemies.
const ENCOUNTERS := [
	["LoneWolf", 1600, 500, false, false, ""],
	["CampWolf", 2350, 500, false, false, ""],
	["ChapelWolf", 8000, 126, false, false, "upper_sanctuary"],
	["CreekWolf", 5740, 424, false, false, ""],
	["CanopyWolf", 4740, 350, true, true, ""],
	["BurialWolf", 8260, 126, false, false, "upper_sanctuary"],
	["HeartwoodA", 4010, 740, false, false, "cellar_guardians"],
	["HeartwoodB", 4320, 740, false, false, "cellar_guardians"],
]

# Prompts are completed by successful controller events, never by crossing x.
# [mechanic, start_x, end_x, text, prerequisite]
const LESSONS := [
	["jump", 180, 600, "Space — Jump", ""],
	["dash", 640, 1000, "L — Dash through the waking roots", ""],
	["attack", 1280, 1900, "C — Attack · press again to continue the combo", ""],
	["rising_slash", 3560, 4360, "↑ + C — Rising Slash", ""],
	["air_attack", 3560, 4700, "C while airborne — Continue into an air combo", "rising_slash"],
	["crescent", 5400, 6100, "R — Crescent Slash", ""],
	["downward_slash", 6400, 7900, "Optional: ↓ + C in the air — Downward Slash\nTry Rising Slash → Air Combo → Downward Slash", "air_attack"],
	["drop_through", 3500, 5200, "S + Space — Drop beneath the root bridge\nOr descend through the open hollow to the left", ""],
]

# Wisp routing goes to visible branch entrances, never through solid scenery
# or directly to an objective. World waypoints are grouped by required seal.
const GUIDANCE_ROUTES := {
	"camp_moon_seal": [Vector2(3080, 452), Vector2(3400, 356), Vector2(3720, 260), Vector2(4080, 212)],
	"oak_moon_seal": [Vector2(3380, 550), Vector2(3540, 610), Vector2(3820, 740), Vector2(4800, 740)],
	"heartwood_moon_seal": [Vector2(6080, 450), Vector2(6400, 342), Vector2(6800, 288), Vector2(7480, 234)],
}
