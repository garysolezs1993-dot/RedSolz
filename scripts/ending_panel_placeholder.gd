extends "res://scripts/boss_intro_placeholder.gd"

# Runtime storyboard sketches only. Final ending textures replace these panels.
var ending_shot := 5:
	set(value):
		ending_shot = value
		if value in [2,3,4]:
			shot = value - 2
		queue_redraw()

func _wolf(center: Vector2, spirit: bool) -> void:
	var fur := Color("bccad9") if spirit else Color("464554")
	var eye := Color("eff7ff") if spirit else Color("c3b3ca")
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-125,45), center + Vector2(-100,-35),
		center + Vector2(-20,-50), center + Vector2(20,-105),
		center + Vector2(35,-55), center + Vector2(82,-40),
		center + Vector2(112,-10), center + Vector2(70,15),
		center + Vector2(60,70), center + Vector2(40,70),
		center + Vector2(20,25), center + Vector2(-60,25),
		center + Vector2(-90,70), center + Vector2(-112,70)
	]),fur)
	draw_line(center+Vector2(-100,-20),center+Vector2(-175,-55),fur,22)
	draw_circle(center+Vector2(63,-24),4,eye)
	draw_line(center+Vector2(12,-30),center+Vector2(48,0),Color("7b3b51") if not spirit else Color("929eb5"),14)
	_flower(center+Vector2(32,-8),.45)
	if spirit:
		for index in range(9):
			draw_circle(center+Vector2(-170+index*35,-130+sin(index*2.4)*20),2,Color(.8,.88,1,.3))

func _draw() -> void:
	if ending_shot in [2,3,4]:
		super._draw()
		return
	# Fixed aspect design keeps sketches legible without stretching silhouettes.
	var factor := minf(size.x / 960.0, size.y / 540.0)
	draw_rect(Rect2(Vector2.ZERO,size),Color("0b0911"))
	draw_set_transform((size-Vector2(960,540)*factor)*.5,0,Vector2.ONE*factor)
	draw_rect(Rect2(0,0,960,540),Color("151420"))
	draw_circle(Vector2(725,145),72,Color("6f3347") if ending_shot < 9 else Color("45566d"))
	for index in range(7):
		draw_line(Vector2(index*170-30,540),Vector2(index*170+15,0),Color("0c0d15"),32)
	if ending_shot == 5:
		_wolf(Vector2(500,290),false)
	elif ending_shot == 6:
		# Red is behind the brother; the crimson strike lands on him, not her.
		_person(Vector2(730,240),true,false)
		_wolf(Vector2(485,325),false)
		draw_polyline(PackedVector2Array([Vector2(70,90),Vector2(205,170),Vector2(300,180),Vector2(425,300)]),Color("a82342"),30)
		draw_polyline(PackedVector2Array([Vector2(70,90),Vector2(205,170),Vector2(300,180),Vector2(425,300)]),Color("ef92a6"),5)
		for index in range(12):
			var direction := Vector2.from_angle(index * TAU / 12)
			draw_line(Vector2(425,300)+direction*25,Vector2(425,300)+direction*85,Color("e85979"),5)
	elif ending_shot in [7,8]:
		_person(Vector2(390,250),true,false)
		# Flattened drawing is a still fallen pose, not a new character animation.
		draw_set_transform((size-Vector2(960,540)*factor)*.5+Vector2(0,155)*factor,0,Vector2(factor,factor*.55))
		_wolf(Vector2(610,330),false)
	elif ending_shot == 10:
		for radius in [130,110,90]:
			draw_circle(Vector2(500,295),radius,Color(.65,.78,1,.035))
		_wolf(Vector2(500,290),true)
	else:
		_person(Vector2(360,245),true,false)
		_wolf(Vector2(630,320),true)
		draw_line(Vector2(400,330),Vector2(526,319),Color("afa3ad"),9)
	draw_set_transform(Vector2.ZERO)
