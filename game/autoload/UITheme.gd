extends Node
## Central UI styles for Zaman Postası.
## Loads textures from res://art/ui/<name>.png when present;
## otherwise falls back to flat StyleBoxFlat so the game runs without art.

const SLICE := 48
const TAP := 88
const FONT_BODY := 28
const FONT_SMALL := 24
const FONT_BTN := 26
const FONT_CAPTION := 22
const FONT_SUB := 30
const FONT_HEAD := 34
const FONT_TITLE := 48
const PORTRAIT_LETTER := 200
const PORTRAIT_END := 140
const PORTRAIT_LINK := 80

const PAPER := Color("EADBC0")
const PAPER_DARK := Color("D9C49E")
const INK := Color("3B2A1E")
const WOOD := Color("5A3E2B")
const BRASS := Color("B08A4A")
const FIRE := Color("C8602F")
const GOOD := Color("6E8B4E")
const BAD := Color("9E3B2E")
const MUTED := Color("8A6E52")
const CREAM := Color("EADBC0")

const UI_DIR := "res://art/ui/"


func path_for(name: String) -> String:
	return UI_DIR + name + ".png"


func has(name: String) -> bool:
	return ResourceLoader.exists(path_for(name))


func tex(name: String) -> Texture2D:
	if has(name):
		return load(path_for(name)) as Texture2D
	return null


func opening_tex(index: int) -> Texture2D:
	# Brief files live under art/ui/; current placeholders stay at art/open_N.png.
	var n := index + 1
	var ui_name := "open_%d" % n
	if has(ui_name):
		return tex(ui_name)
	var legacy := "res://art/open_%d.png" % n
	if ResourceLoader.exists(legacy):
		return load(legacy) as Texture2D
	return null


func _flat(bg: Color, radius: int = 12, pad: int = 14, border: int = 0, border_color: Color = INK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = int(pad * 0.7)
	sb.content_margin_bottom = int(pad * 0.7)
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_color
	return sb


func style_texture(name: String, fallback: StyleBox, content_pad: int = 16) -> StyleBox:
	var t := tex(name)
	if t == null:
		return fallback
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.texture_margin_left = SLICE
	sb.texture_margin_right = SLICE
	sb.texture_margin_top = SLICE
	sb.texture_margin_bottom = SLICE
	sb.content_margin_left = content_pad
	sb.content_margin_right = content_pad
	sb.content_margin_top = content_pad
	sb.content_margin_bottom = content_pad
	return sb


func panel_paper() -> StyleBox:
	return style_texture("panel_paper", _flat(PAPER, 16, 20), 20)


func panel_letter() -> StyleBox:
	return style_texture("panel_letter", _flat(PAPER, 16, 22, 2, Color(INK, 0.25)), 22)


func frame_portrait() -> StyleBox:
	return style_texture("frame_portrait", _flat(Color(0, 0, 0, 0), 8, 8, 3, BRASS), 10)


func topbar_style() -> StyleBox:
	return style_texture("topbar", _flat(WOOD, 0, 12), 10)


func bottombar_style() -> StyleBox:
	return style_texture("bottombar", _flat(WOOD, 0, 12), 10)


func banner_style() -> StyleBox:
	return style_texture("chapter_banner", _flat(WOOD, 8, 16), 16)


func btn_style(kind: String, state: String = "normal") -> StyleBox:
	# kind: primary | secondary | option
	# state: normal | pressed | disabled | selected
	var file := ""
	var fallback: StyleBox
	match kind:
		"primary":
			if state == "pressed":
				file = "btn_primary_pressed"
				fallback = _flat(FIRE, 12, 16)
			elif state == "disabled":
				file = "btn_primary"
				fallback = _flat(Color(WOOD, 0.55), 12, 16)
			else:
				file = "btn_primary"
				fallback = _flat(WOOD, 12, 16)
		"option":
			if state == "selected":
				file = "btn_option_selected"
				fallback = _flat(FIRE, 12, 16)
			elif state == "disabled":
				file = "btn_option_disabled"
				fallback = _flat(Color(PAPER_DARK, 0.7), 12, 16)
			else:
				file = "btn_option"
				fallback = _flat(PAPER_DARK, 12, 16, 2, Color(INK, 0.35))
		_:
			if state == "pressed":
				file = "btn_secondary_pressed"
				fallback = _flat(FIRE, 12, 16)
			elif state == "disabled":
				file = "btn_secondary"
				fallback = _flat(Color(WOOD, 0.55), 12, 16)
			else:
				file = "btn_secondary"
				fallback = _flat(WOOD, 12, 16)
	var sb := style_texture(file, fallback, 16)
	if state == "disabled" and sb is StyleBoxTexture:
		(sb as StyleBoxTexture).modulate_color = Color(1, 1, 1, 0.55)
	return sb


func apply_button(b: Button, kind: String = "secondary", min_h: int = TAP, font_size: int = FONT_BTN) -> void:
	if min_h > 0:
		b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, min_h)
	b.add_theme_stylebox_override("normal", btn_style(kind, "normal"))
	b.add_theme_stylebox_override("hover", btn_style(kind, "pressed"))
	b.add_theme_stylebox_override("pressed", btn_style(kind, "pressed"))
	b.add_theme_stylebox_override("disabled", btn_style(kind, "disabled"))
	var light := kind == "primary" or kind == "secondary"
	var color: Color = CREAM if light else INK
	_font_on(b, font_size, color)
	b.add_theme_color_override("font_hover_color", CREAM)
	b.add_theme_color_override("font_pressed_color", CREAM)
	b.add_theme_color_override("font_disabled_color", MUTED)


func apply_option(b: Button, selected: bool, disabled: bool = false) -> void:
	var state := "normal"
	if disabled:
		state = "disabled"
	elif selected:
		state = "selected"
	b.add_theme_stylebox_override("normal", btn_style("option", state))
	b.add_theme_stylebox_override("hover", btn_style("option", "selected" if selected else "pressed"))
	b.add_theme_stylebox_override("pressed", btn_style("option", "selected"))
	b.add_theme_stylebox_override("disabled", btn_style("option", "disabled"))
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, TAP)
	var color: Color = CREAM if selected else INK
	_font_on(b, FONT_BTN, color)
	b.add_theme_color_override("font_hover_color", CREAM)
	b.add_theme_color_override("font_pressed_color", CREAM)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.disabled = disabled


func apply_panel(pc: PanelContainer, letter: bool = false) -> void:
	pc.add_theme_stylebox_override("panel", panel_letter() if letter else panel_paper())


func apply_bar(pc: PanelContainer, top: bool = true) -> void:
	pc.add_theme_stylebox_override("panel", topbar_style() if top else bottombar_style())


func apply_portrait_frame(pc: PanelContainer) -> void:
	pc.add_theme_stylebox_override("panel", frame_portrait())


func add_background(parent: Control, name: String, fallback: Color) -> TextureRect:
	# Full-rect backdrop. Uses the texture when present, otherwise a solid color.
	var tr := TextureRect.new()
	tr.name = "UIBackdrop_" + name
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var t := tex(name)
	if t != null:
		tr.texture = t
		if name == "bg_paper":
			tr.stretch_mode = TextureRect.STRETCH_TILE
		else:
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		tr.texture = null
		# Color fallback lives as a sibling ColorRect behind this node.
		var cr := ColorRect.new()
		cr.color = fallback
		cr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(cr)
	parent.add_child(tr)
	return tr


func building_texture(id: String, state: String) -> Texture2D:
	# state is the brief suffix, e.g. "ruined", "open", "off", "stressed", "blocked".
	var file := building_file(id, state)
	if file != "" and has(file):
		return tex(file)
	var base := building_file(id, "")
	if base != "" and has(base):
		return tex(base)
	return null


func building_file(id: String, state: String) -> String:
	match id:
		"bakery":
			return "bld_bakery_" + (state if state != "" else "open")
		"school":
			return "bld_school_" + (state if state != "" else "off")
		"bridge":
			return "bld_bridge_stressed" if state == "stressed" else "bld_bridge"
		"archive":
			return "bld_archive"
		"mill":
			return "bld_mill"
		"culvert":
			return "bld_culvert_blocked" if state == "blocked" else "bld_culvert"
		"cemetery":
			return "bld_cemetery"
		"post":
			return "bld_postbox"
		_:
			return ""


func bakery_state(label: String) -> String:
	match label:
		"yıkık":
			return "ruined"
		"kapalı":
			return "closed"
		"hasarlı":
			return "damaged"
		_:
			return "open"


func _font_on(c: Control, size: int, color: Color) -> void:
	var ui_font: Font = load("res://fonts/NotoSans-Regular.ttf")
	if ui_font != null:
		c.add_theme_font_override("font", ui_font)
	c.add_theme_font_size_override("font_size", size)
	if c is RichTextLabel:
		c.add_theme_color_override("default_color", color)
	else:
		c.add_theme_color_override("font_color", color)
