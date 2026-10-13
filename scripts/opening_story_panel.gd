class_name OpeningStoryPanel
extends Resource

enum Placeholder { KEEP, FOREST_ENTRY, BROTHER_TRAIL, WATCHING_WOLF, BROTHER_LEAVING, RED_FOLLOWS, LILY_PROMISE, FAREWELL, WAITING, DECISION }
@export var placeholder: Placeholder = Placeholder.KEEP
@export var artwork: Texture2D
@export var shot_label := ""
@export var lines: Array[Resource] = []
@export_range(0, .04, .005) var still_zoom := .03
@export var still_pan := Vector2.ZERO
@export var music_level_db := -24.0
@export_multiline var caption := ""
@export_range(1.0, 15.0, .25) var hold_seconds := 6.0
