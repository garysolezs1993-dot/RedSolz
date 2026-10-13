class_name EndingStoryPanel
extends Resource

# Optional per-shot overrides; array order follows the thirteen story beats.
@export var artwork: Texture2D
@export var speaker := ""
@export_multiline var caption := ""
@export_range(.5, 15, .1) var hold_seconds := 2.2
@export_range(0, .04, .005) var zoom := .03
@export var pan := Vector2.ZERO
@export var impact := false
