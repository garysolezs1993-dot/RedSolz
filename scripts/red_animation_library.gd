extends RefCounted

# Legacy drafts and reviewed replacements are both imported unchanged.
const ROOT := "res://assets/game_assets/red_gothic/"
const REPLACEMENT_ROOT := "res://assets/game_assets/red_gothic_replacements/"
const FOOT_LINE := 46.0
const LANTERN_ROOT := "res://assets/game_assets/moon_lantern/"
# Boot contacts, excluding the faint low-alpha canvas residue in the exports.
const LANTERN_FOOT_LINES := [1282.0, 1264.0, 1305.0, 1325.0, 1292.0, 1323.0, 1268.0, 1284.0]

# One authored transform per entire clip: scale, canvas width/height, ground pivot.
# These values never depend on the current frame's alpha bounding box.
const VISUAL_PROFILES := {
	"idle": Vector4(.105, 512, 512, 470),
	"walk": Vector4(.105, 512, 512, 466),
	"run": Vector4(.105, 512, 512, 466),
	"jump": Vector4(.105, 512, 512, 465),
	"double_jump": Vector4(.105, 512, 512, 465),
	"fall": Vector4(.1, 512, 512, 465),
	"land": Vector4(.1, 512, 512, 470),
	"recover": Vector4(.1, 512, 512, 470),
	"dash": Vector4(.105, 512, 512, 460),
	# The supplied air poses draw a larger hood/head than the movement set.
	# Fixed clip scales correct that difference without resizing any PNG/frame.
	"air_attack_1": Vector4(.10, 512, 512, 450),
	"air_attack_2": Vector4(.09, 512, 512, 450),
	"air_attack_3": Vector4(.09, 512, 512, 450),
	"downward_slash": Vector4(.035, 1536, 1536, 1280),
	"downward_impact": Vector4(.035, 1536, 1536, 1143),
	"hurt": Vector4(.088, 512, 512, 460),
	"knockback": Vector4(.088, 512, 512, 460),
	"death": Vector4(.095, 512, 512, 473),
	"crouch_enter": Vector4(.078, 512, 512, 490),
	"crouch_hold": Vector4(.078, 512, 512, 490),
	"crouch_exit": Vector4(.078, 512, 512, 490),
	"crouch_move": Vector4(.078, 512, 512, 466),
	"rising_slash": Vector4(.09, 362, 543, 543),
	"attack_slash": Vector4(.105, 512, 512, 450),
	"attack_spin": Vector4(.105, 512, 512, 439),
	"attack_thrust": Vector4(.105, 512, 512, 433),
	"crescent_cast": Vector4(.105, 443, 443, 443),
}

# Reviewed sole anchors for the idle export: later poses were placed higher
# inside the unchanged 512px canvas. Only vertical placement is corrected;
# scale, horizontal placement and the artwork remain unchanged.
const IDLE_FOOT_LINES := [470.0, 470.0, 470.0, 469.0, 442.0, 442.0, 456.0, 466.0]
# Authored ground contacts for the new collapse sequence (boots, then cape/body).
# The final three files intentionally repeat the resting pose.
const DEATH_FOOT_LINES := [473.0, 474.0, 449.0, 426.0, 413.0, 459.0, 459.0, 459.0]
# Manually reviewed boot contacts in the master canvases. Correct only vertical
# ground placement; never crop, auto-center, or resize an individual pose.
const COMBO_FOOT_LINES := {
	"attack_slash": [450.0, 456.0, 437.0, 451.0, 439.0, 438.0, 454.0, 470.0],
	"attack_spin": [439.0, 456.0, 451.0, 453.0, 451.0, 455.0, 454.0, 453.0],
	"attack_thrust": [433.0, 458.0, 466.0, 431.0, 413.0, 435.0, 458.0, 457.0],
}
# Fixed scale/anchor for each entire VFX sequence, independent of pose pivots.
const COMBO_VFX_PROFILES := [Vector3(22, -5, .105), Vector3(22, -5, .105), Vector3(20, -8, .12)]
# All replacement effects have 1536px canvases; 1/3 scale retains display size.
const AIR_VFX_CANVASES := [1536, 1536, 1536]
const AIR_VFX_PROFILES := [Vector3(20, -5, .035), Vector3(20, -8, .035), Vector3(14, 12, .04)]
const DOWNWARD_VFX_PROFILE := Vector3(6, -5, .04)
# Reviewed boot contacts for the four landing poses; exclude the sword tip.
const DOWNWARD_IMPACT_FOOT_LINES := [1143.0, 1050.0, 1144.0, 1165.0]
const CRESCENT_FOOT_LINES := [443.0, 443.0, 443.0, 443.0, 411.0, 412.0, 412.0, 411.0]
# Travel origin for the full projectile canvases; later source rows shift up.
const CRESCENT_PROJECTILE_Y := [287.0, 254.0, 260.0, 260.0, 222.0, 235.0, 227.0, 223.0]

static func character_transform(animation: String, frame: int = 0) -> Transform2D:
	if animation == "lantern_interact":
		var scale := .04
		var feet: float = LANTERN_FOOT_LINES[clampi(frame, 0, 7)]
		return Transform2D(Vector2(scale, 0), Vector2(0, scale), Vector2(0, 15.0 - (feet - 768.0) * scale))
	var profile: Vector4 = VISUAL_PROFILES.get(animation, Vector4(1, 48, 48, FOOT_LINE))
	var scale := profile.x
	var foot_line := profile.w
	if animation == "idle":
		foot_line = IDLE_FOOT_LINES[clampi(frame, 0, IDLE_FOOT_LINES.size() - 1)]
	elif animation == "death":
		foot_line = DEATH_FOOT_LINES[clampi(frame, 0, DEATH_FOOT_LINES.size() - 1)]
	elif animation == "downward_impact":
		foot_line = DOWNWARD_IMPACT_FOOT_LINES[clampi(frame, 0, 3)]
	elif COMBO_FOOT_LINES.has(animation):
		foot_line = COMBO_FOOT_LINES[animation][clampi(frame, 0, 7)]
	elif animation == "crescent_cast":
		foot_line = CRESCENT_FOOT_LINES[clampi(frame, 0, 7)]
		profile.z = 443.0 if frame < 4 else 444.0
	var position := Vector2(0, 15.0 - (foot_line - profile.z * .5) * scale)
	return Transform2D(Vector2(scale, 0), Vector2(0, scale), position)

static func add_replacement_clip(frames: SpriteFrames, name: String, folder: String, prefix: String, count: int, fps: float, looping: bool = false, first: int = 0) -> void:
	if frames.has_animation(name):
		frames.remove_animation(name)
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, looping)
	for index in range(first, first + count):
		var path := REPLACEMENT_ROOT + folder + "/" + prefix + "_%02d.png" % index
		frames.add_frame(name, load(path) as Texture2D)

static func add_clip(frames: SpriteFrames, name: String, folder: String, count: int, fps: float, looping: bool = false, first: int = 0, canvas: int = 48) -> void:
	if frames.has_animation(name):
		frames.remove_animation(name)
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, looping)
	for index in range(first, first + count):
		var path := ROOT + folder + "/game_%dx%d_draft/frame_%02d.png" % [canvas, canvas, index]
		frames.add_frame(name, load(path) as Texture2D)

static func add_movement(frames: SpriteFrames) -> void:
	add_replacement_clip(frames, "idle", "idle", "idle", 8, 5.0, true)
	# The new dedicated walk export still shifts between rows. Keep the slower
	# run-cycle fallback using the clean replacement run artwork.
	add_replacement_clip(frames, "walk", "run", "run", 8, 10.0, true)
	add_replacement_clip(frames, "run", "run", "run", 8, 14.0, true)
	add_replacement_clip(frames, "jump", "jump", "jump", 8, 18.0)
	add_replacement_clip(frames, "double_jump", "jump", "jump", 8, 18.0)
	add_replacement_clip(frames, "fall", "fall", "fall", 4, 8.0, true)
	# Four replacement frames split between the existing two states. Retain
	# each state's original 1/6 second duration (formerly three frames at 18fps).
	add_replacement_clip(frames, "land", "landing", "landing_recovery", 2, 12.0)
	add_replacement_clip(frames, "recover", "landing", "landing_recovery", 2, 12.0, false, 2)
	# Retain the original 0.15s dash and travel distance, with all eight poses.
	add_replacement_clip(frames, "dash", "dash", "dash", 8, 8.0 / 0.15)

static func add_ground_combat(frames: SpriteFrames) -> void:
	add_replacement_clip(frames, "attack_slash", "combo_master/attack_1/character", "attack1", 8, 12.0)
	add_replacement_clip(frames, "attack_spin", "combo_master/attack_2/character", "attack2", 8, 12.0)
	add_replacement_clip(frames, "attack_thrust", "combo_master/attack_3/character", "attack3", 8, 10.0)
	add_replacement_clip(frames, "hurt", "hurt", "hurt", 4, 16.0)
	add_replacement_clip(frames, "knockback", "hurt", "hurt", 8, 18.0)
	add_replacement_clip(frames, "death", "death", "death", 8, 8.0)

static func add_directional_combat(frames: SpriteFrames) -> void:
	for step in range(1, 4):
		add_replacement_clip(frames, "air_attack_%d" % step, "air_combo_master/air_attack_%d/character" % step, "air_attack%d_character" % step, 8, 10.0 if step == 3 else 12.0)
	# Actual Red poses were mislabeled as VFX in the supplied archive.
	add_replacement_clip(frames, "rising_slash", "rising_slash", "red_rising_slash_vfx", 8, 16.0, false, 1)
	add_replacement_clip(frames, "downward_slash", "downward_master/character", "downward_slash", 8, 16.0)
	add_replacement_clip(frames, "downward_impact", "downward_master/character", "downward_slash", 4, 12.5, false, 4)

static func add_skills(frames: SpriteFrames) -> void:
	add_replacement_clip(frames, "crescent_cast", "crescent_character", "crescent_slash_character_fixed", 8, 16.0, false, 1)
	# Exclude only the disconnected neighboring-image scraps above later poses.
	# Atlas margins preserve each original canvas and its ground anchor.
	for index in range(4, 8):
		_hide_top_scraps(frames, "crescent_cast", index, 24.0)
	# Existing skills retain their gameplay; the new pack supplies a common cast
	# performance rather than dedicated summon/blossom/execution character art.
	for name in ["skill_blood_blossom", "skill_wolf_summon", "skill_execution"]:
		add_clip(frames, name, "skills/crescent_slash/cast", 8, 16.0)

static func add_crouch(frames: SpriteFrames) -> void:
	add_replacement_clip(frames, "crouch_enter", "crouch", "crouch", 3, 16.0)
	add_replacement_clip(frames, "crouch_hold", "crouch", "crouch", 2, 5.0, true, 3)
	add_replacement_clip(frames, "crouch_move", "crouch_walk", "crouch_walk", 8, 10.0, true)
	add_replacement_clip(frames, "crouch_exit", "crouch", "crouch", 2, 12.0, false, 4)

static func add_presentation(frames: SpriteFrames) -> void:
	frames.add_animation("lantern_interact")
	frames.set_animation_speed("lantern_interact", 7.0)
	frames.set_animation_loop("lantern_interact", false)
	for index in range(8):
		frames.add_frame("lantern_interact", load(LANTERN_ROOT + "red/lantern_interact_%02d.png" % index))
	var interactions := {"look_around": 3, "pickup": 3, "open_chest": 3, "push_pull": 2, "sit_rest": 2, "cheer": 2, "point": 2, "look_up": 2, "talk": 2, "rest_sleep": 8}
	for name: String in interactions:
		add_clip(frames, "interact_" + name, "interact/" + name, interactions[name], 8.0)
	for style in ["stage1_bittersweet", "normal_stage_clear", "cheerful"]:
		add_clip(frames, "victory_" + style, "victory/" + style, 8, 8.0)

static func motion_effects() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for kind in ["dust", "petals", "speed_streak"]:
		add_clip(frames, kind, "effects/dash_" + kind, 8, 24.0, false, 0, 64)
		for index in range(8):
			var region := AtlasTexture.new()
			region.atlas = frames.get_frame_texture(kind, index)
			if kind == "dust":
				region.region = Rect2(19, 23, 43, 34) if index == 0 else Rect2(6, 23, 56, 34)
			elif kind == "petals":
				region.region = Rect2(21, 24, 41, 33) if index == 0 else Rect2(8, 24, 54, 33)
			else:
				region.region = Rect2(27, 24, 35, 33) if index == 0 else Rect2(10, 24, 52, 33)
			frames.set_frame(kind, index, region)
	return frames

static func projectile_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_replacement_clip(frames, "flight", "crescent_projectile", "crescent_slash_projectile_fixed", 8, 18.0, true, 1)
	add_clip(frames, "impact", "skills/crescent_slash/impact", 6, 18.0, false, 0, 96)
	# The retained impact drafts include numbered labels below the burst and
	# sheet guides at some edges. Hide those areas only in the display texture.
	# Atlas margins preserve the original 96px canvas and impact alignment.
	var impact_regions := [
		Rect2(24, 18, 72, 41),
		Rect2(0, 18, 96, 41),
		Rect2(0, 18, 96, 41),
		Rect2(27, 18, 69, 41),
		Rect2(0, 18, 96, 41),
		Rect2(0, 18, 79, 41),
	]
	for index in range(6):
		var region := AtlasTexture.new()
		region.atlas = frames.get_frame_texture("impact", index)
		region.region = impact_regions[index]
		region.margin = Rect2(region.region.position, Vector2(96, 96) - region.region.size)
		frames.set_frame("impact", index, region)
	return frames

static func projectile_transform(animation: String, frame: int) -> Transform2D:
	if animation != "flight":
		return Transform2D.IDENTITY
	var index := clampi(frame, 0, 7)
	var canvas_height := 443.0 if index < 4 else 444.0
	var scale := .16
	return Transform2D(Vector2(scale, 0), Vector2(0, scale), Vector2(0, (canvas_height * .5 - CRESCENT_PROJECTILE_Y[index]) * scale))

static func _hide_top_scraps(frames: SpriteFrames, clip: String, index: int, top: float) -> void:
	var texture := frames.get_frame_texture(clip, index)
	var region := AtlasTexture.new()
	region.atlas = texture
	region.region = Rect2(0, top, texture.get_width(), texture.get_height() - top)
	region.margin = Rect2(0, top, 0, top)
	frames.set_frame(clip, index, region)

static func air_combo_effects() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for step in range(1, 4):
		add_replacement_clip(frames, "air_attack_%d_vfx" % step, "air_combo_master/air_attack_%d/vfx" % step, "air_attack%d_vfx" % step, 8, 10.0 if step == 3 else 12.0)
	return frames

static func downward_effects() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_replacement_clip(frames, "downward_slash", "downward_master/vfx", "downward_slash_vfx", 8, 16.0)
	return frames

static func combo_effects() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for step in range(1, 4):
		add_replacement_clip(frames, "attack_%d_vfx" % step, "combo_master/attack_%d/vfx" % step, "attack%d_vfx" % step, 8, 10.0 if step == 3 else 12.0)
	return frames

static func attack_effects() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	add_replacement_clip(frames, "crescent", "crescent_vfx", "crescent_slash_vfx_fixed", 8, 16.0, false, 1)
	_hide_top_scraps(frames, "crescent", 7, 24.0)
	add_clip(frames, "rising", "effects/rising_arc", 3, 16.0, false, 0, 96)
	add_clip(frames, "rising_fade", "effects/rising_petals_fade", 3, 16.0, false, 0, 96)
	# Some effect drafts retain concept-sheet guides/numbers. Hide those margins
	# in the display texture only; the supplied PNGs remain byte-for-byte intact.
	for clip in ["rising", "rising_fade"]:
		for index in range(frames.get_frame_count(clip)):
			var region := AtlasTexture.new()
			region.atlas = frames.get_frame_texture(clip, index)
			match clip:
				"rising":
					region.region = Rect2(21, 16, 53, 37)
				"rising_fade":
					region.region = Rect2(21, 16, 53, 41)
			frames.set_frame(clip, index, region)
	return frames
