extends Control
## Zaman Postası — Bölüm 1 prototip arayüzü.

const COL_BG := Color("473324")
const COL_PAPER := Color("E8D5B5")
const COL_PAPER_DARK := Color("D4B896")
const COL_INK := Color("2B1B12")
const COL_ACCENT := Color("C45C26")
const COL_GOOD := Color("3E6B4F")
const COL_BAD := Color("8B3A2A")
const COL_MUTED := Color("8A7058")
const COL_PANEL := Color("5A3D28")

const OPENING := [
	{"art": "res://art/open_1.png", "title": "Sarı zarf", "body": "Büyükannemin sandığından sarı bir zarf çıktı. 1925 yangınında kaybettiği bir can... benim de köküm. Zarf yıllarca açılmamıştı."},
	{"art": "res://art/open_2.png", "title": "Adres", "body": "İçinde tek bir adres vardı: İğdeyaka tepesi, paslı posta kutusunun yanı. Haritada böyle bir kasaba artık yok. Yine de yola çıktım."},
	{"art": "res://art/open_3.png", "title": "Silinmiş kasaba", "body": "2026'dayım. Çalılık, yıkıntı, birkaç mezar taşı. Büyükannemin anlattığı fırın, okul ve değirmen burada bir zamanlar varmış."},
	{"art": "res://art/open_4.png", "title": "Yazılmamış olanı da taşıyoruz", "body": "Kutu duruyor. İçine atılan mektuplar 1925 Haziran'ına, yangın gecesinden önceye gidiyor. Uyarırsam bir hayat kurtulabilir; her kurtarışın bir bedeli de var."},
]

var ui_font: Font

var play_root: VBoxContainer
var header: HBoxContainer
var stamp_label: Label
var heat_label: Label
var content_host: Control
var map_panel: Control
var letter_panel: Control
var timeline_panel: Control
var journal_panel: Control
var result_panel: Control
var building_nodes: Dictionary = {}
var map_caption: Label
var map_hint: Label
var map_legend: HBoxContainer
var map_grid: GridContainer
var bottom_bar: HBoxContainer
var nav_buttons: Dictionary = {}

var title_screen: Control
var opening_screen: Control
var opening_art: TextureRect
var opening_title: Label
var opening_body: Label
var opening_index: int = 0

var overlay: ColorRect
var overlay_card: PanelContainer
var overlay_title: Label
var overlay_body: RichTextLabel
var overlay_body_scroll: ScrollContainer
var overlay_extra: VBoxContainer
var overlay_close: Button

var toast: PanelContainer
var toast_label: Label
var toast_timer: Timer
var suppress_toast: bool = false

var current_panel: String = "map"
var journal_tab: String = "clues"
var composer_recipient: String = ""
var composer_letter_id: String = ""
var letter_list: VBoxContainer
var letter_preview: Label
var recip_buttons: Dictionary = {}
var help_btn: Button

func _ready() -> void:
	ui_font = load("res://fonts/NotoSans-Regular.ttf")
	if ui_font != null:
		var th := Theme.new()
		th.default_font = ui_font
		th.default_font_size = 16
		theme = th
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	GameState.state_changed.connect(_on_state_changed)
	GameState.letter_sent.connect(_on_letter_sent)
	GameState.clue_found.connect(_on_clue_found)
	GameState.chapter_ended.connect(_on_chapter_ended)
	SaveManager.saved.connect(_on_saved)
	resized.connect(_on_root_resized)
	_refresh_all()
	_show_title()

func _on_root_resized() -> void:
	_layout_map()
	_fit_overlay_card()

func _apply_font(c: Control, size: int, color: Color = COL_INK) -> void:
	if ui_font != null:
		c.add_theme_font_override("font", ui_font)
	c.add_theme_font_size_override("font_size", size)
	if c is Label or c is Button or c is RichTextLabel:
		if c is RichTextLabel:
			c.add_theme_color_override("default_color", color)
		else:
			c.add_theme_color_override("font_color", color)

func _mk_btn(text: String, min_w: int = 0, min_h: int = 48) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, min_h)
	_apply_font(b, 16, COL_PAPER)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = COL_ACCENT
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	var sbd: StyleBoxFlat = sb.duplicate()
	sbd.bg_color = Color("3a2a20")
	b.add_theme_stylebox_override("disabled", sbd)
	b.add_theme_color_override("font_hover_color", COL_PAPER)
	b.add_theme_color_override("font_pressed_color", COL_PAPER)
	b.add_theme_color_override("font_disabled_color", COL_MUTED)
	return b

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	play_root = VBoxContainer.new()
	play_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play_root.add_theme_constant_override("separation", 0)
	add_child(play_root)

	_build_header()
	content_host = Control.new()
	content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_root.add_child(content_host)

	map_panel = _make_full_panel()
	content_host.add_child(map_panel)
	_build_map(map_panel)

	letter_panel = _build_letter_panel()
	content_host.add_child(letter_panel)
	timeline_panel = _build_text_panel("Zaman Çizelgesi")
	content_host.add_child(timeline_panel)
	journal_panel = _build_journal_panel()
	content_host.add_child(journal_panel)
	result_panel = _build_result_panel()
	content_host.add_child(result_panel)

	_build_bottom()
	_build_title()
	_build_opening()
	_build_overlay()
	_build_toast()
	_show_content("map")

func _make_full_panel() -> Control:
	var p := Control.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.anchor_right = 1.0
	p.anchor_bottom = 1.0
	p.offset_left = 0
	p.offset_top = 0
	p.offset_right = 0
	p.offset_bottom = 0
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return p

func _build_header() -> void:
	header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 70)
	header.add_theme_constant_override("separation", 8)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 6)
	pad.add_child(header)
	play_root.add_child(pad)
	var title := Label.new()
	title.text = "Zaman Postası"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(title, 22, COL_PAPER)
	header.add_child(title)
	help_btn = _mk_btn("?", 48, 48)
	help_btn.pressed.connect(_show_help)
	header.add_child(help_btn)
	stamp_label = Label.new()
	_apply_font(stamp_label, 16, COL_ACCENT)
	header.add_child(stamp_label)
	heat_label = Label.new()
	_apply_font(heat_label, 16, COL_PAPER_DARK)
	header.add_child(heat_label)
	var restart := _mk_btn("Yeniden", 90, 48)
	restart.pressed.connect(_on_restart)
	header.add_child(restart)

func _build_bottom() -> void:
	bottom_bar = HBoxContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 78)
	bottom_bar.add_theme_constant_override("separation", 6)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 8)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 10)
	pad.add_child(bottom_bar)
	play_root.add_child(pad)
	for item in [["Harita", "map"], ["Mektup", "letter"], ["Zaman", "timeline"], ["Defter", "journal"], ["Sonuç", "result"]]:
		var b := _mk_btn(item[0], 0, 58)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mode: String = item[1]
		b.pressed.connect(_show_panel.bind(mode))
		bottom_bar.add_child(b)
		nav_buttons[mode] = b

func _build_map(parent: Control) -> void:
	var paper := ColorRect.new()
	paper.color = COL_PAPER
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.offset_left = 10
	paper.offset_top = 4
	paper.offset_right = -10
	paper.offset_bottom = -4
	parent.add_child(paper)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	parent.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)
	map_caption = Label.new()
	map_caption.text = "İğdeyaka · 2026  (geçmişe mektupla dokun)"
	_apply_font(map_caption, 15, COL_MUTED)
	v.add_child(map_caption)
	map_legend = HBoxContainer.new()
	map_legend.add_theme_constant_override("separation", 10)
	v.add_child(map_legend)
	_fill_legend()
	map_grid = GridContainer.new()
	map_grid.columns = 2
	map_grid.add_theme_constant_override("h_separation", 10)
	map_grid.add_theme_constant_override("v_separation", 10)
	map_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(map_grid)
	var defs := [
		["bakery", "Fırın", "K1"],
		["school", "Okul", "INFO_SCHOOL"],
		["bridge", "Köprü", "INFO_BRIDGE"],
		["archive", "Arşiv / Telgraf", "K3"],
		["mill", "Değirmen", "K4"],
		["culvert", "Menfez / Dere", "INFO_CULVERT"],
		["cemetery", "Mezarlık", "K2"],
		["post", "Posta Kutusu", "POST"],
	]
	for d in defs:
		var cell := Button.new()
		cell.name = str(d[0])
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.clip_text = false
		_apply_font(cell, 18, COL_INK)
		var st := StyleBoxFlat.new()
		st.bg_color = COL_PAPER_DARK
		st.set_corner_radius_all(12)
		st.set_border_width_all(2)
		st.border_color = COL_INK
		cell.add_theme_stylebox_override("normal", st)
		cell.add_theme_stylebox_override("hover", st)
		cell.add_theme_stylebox_override("pressed", st)
		cell.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var key: String = d[2]
		cell.pressed.connect(_on_map_spot.bind(key))
		map_grid.add_child(cell)
		building_nodes[d[0]] = cell
	map_hint = Label.new()
	map_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(map_hint, 15, COL_INK)
	v.add_child(map_hint)
	parent.resized.connect(_layout_map)

func _fill_legend() -> void:
	for c in map_legend.get_children():
		c.queue_free()
	for item in [["İyi / açık", COL_GOOD], ["Kapalı / borç", COL_ACCENT], ["Yıkık / kayıp", COL_BAD], ["Yok / soluk", COL_MUTED]]:
		var chip := HBoxContainer.new()
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(14, 14)
		sw.color = Color(item[1]).lerp(COL_PAPER, 0.45)
		chip.add_child(sw)
		var lb := Label.new()
		lb.text = str(item[0])
		_apply_font(lb, 12, COL_INK)
		chip.add_child(lb)
		map_legend.add_child(chip)

func _layout_map() -> void:
	if map_grid == null:
		return
	var fs := 18
	if size.x > 1000:
		fs = 22
	elif size.x < 500:
		fs = 16
	for id in building_nodes:
		var cell: Button = building_nodes[id]
		_apply_font(cell, fs, COL_INK)

func _build_letter_panel() -> Control:
	var wrap := _make_full_panel()
	var paper := ColorRect.new()
	paper.color = COL_PAPER
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(paper)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	wrap.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)
	var t := Label.new()
	t.text = "Mektup yaz (hazır cümle parçaları)"
	_apply_font(t, 20, COL_INK)
	v.add_child(t)
	var recip_row := HBoxContainer.new()
	recip_row.add_theme_constant_override("separation", 6)
	v.add_child(recip_row)
	for cid in ["H", "F", "N", "C"]:
		var info: Dictionary = GameState.CHARACTERS_STORY[cid]
		var b := _mk_btn(str(info["name"]), 0, 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_font(b, 14, COL_PAPER)
		b.pressed.connect(_select_recipient.bind(cid))
		recip_row.add_child(b)
		recip_buttons[cid] = b
	var style_row := HBoxContainer.new()
	style_row.add_theme_constant_override("separation", 6)
	v.add_child(style_row)
	var tone_l := Label.new()
	tone_l.text = "Üslup:"
	_apply_font(tone_l, 14, COL_INK)
	style_row.add_child(tone_l)
	for item in [["Nazik", "nazik"], ["Acil", "acil"]]:
		var b2 := _mk_btn(item[0], 80, 40)
		b2.pressed.connect(_set_tone.bind(item[1]))
		style_row.add_child(b2)
	var sign_l := Label.new()
	sign_l.text = "  İmza:"
	_apply_font(sign_l, 14, COL_INK)
	style_row.add_child(sign_l)
	for item in [["İsimsiz", "isimsiz"], ["Bir dost", "dost"], ["Torun", "torun"]]:
		var b3 := _mk_btn(item[0], 90, 40)
		b3.pressed.connect(_set_sign.bind(item[1]))
		style_row.add_child(b3)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	letter_list = VBoxContainer.new()
	letter_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	letter_list.add_theme_constant_override("separation", 8)
	scroll.add_child(letter_list)
	letter_preview = Label.new()
	letter_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	letter_preview.custom_minimum_size = Vector2(0, 130)
	_apply_font(letter_preview, 15, COL_INK)
	letter_preview.text = "Önce bir alıcı, sonra bir mektup seç."
	v.add_child(letter_preview)
	var send_btn := _mk_btn("Mektubu Gönder (1 pul)", 0, 58)
	send_btn.pressed.connect(_on_send_pressed)
	v.add_child(send_btn)
	wrap.visible = false
	return wrap

func _build_text_panel(title_text: String) -> Control:
	var wrap := _make_full_panel()
	var paper := ColorRect.new()
	paper.color = COL_PAPER
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(paper)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	wrap.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)
	var t := Label.new()
	t.name = "Title"
	t.text = title_text
	_apply_font(t, 22, COL_INK)
	v.add_child(t)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	var body := RichTextLabel.new()
	body.name = "Body"
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(body, 16, COL_INK)
	scroll.add_child(body)
	wrap.visible = false
	return wrap

func _build_journal_panel() -> Control:
	var wrap := _build_text_panel("Araştırma Defteri")
	var v: VBoxContainer = wrap.get_child(1).get_child(0)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	v.add_child(tabs)
	v.move_child(tabs, 1)
	for item in [["İpuçları", "clues"], ["Karakterler", "chars"], ["Bağlar", "links"]]:
		var b := _mk_btn(item[0], 0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_set_journal_tab.bind(item[1]))
		tabs.add_child(b)
	return wrap

func _build_result_panel() -> Control:
	var wrap := _build_text_panel("Bölüm Sonu · Külün Kokusu")
	var v: VBoxContainer = wrap.get_child(1).get_child(0)
	var replay := _mk_btn("Tekrar oyna", 0, 56)
	replay.pressed.connect(_on_confirm_restart)
	v.add_child(replay)
	var nxt := _mk_btn("Sonraki bölüm (yakında)", 0, 52)
	nxt.disabled = true
	v.add_child(nxt)
	return wrap

func _build_title() -> void:
	title_screen = ColorRect.new()
	title_screen.color = COL_BG
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.visible = false
	add_child(title_screen)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(c)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(420, 0)
	v.add_theme_constant_override("separation", 14)
	c.add_child(v)
	var t := Label.new()
	t.text = "Zaman Postası"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(t, 36, COL_PAPER)
	v.add_child(t)
	var s := Label.new()
	s.text = "Külün Kokusu  ·  Bölüm 1"
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(s, 20, COL_ACCENT)
	v.add_child(s)
	var blurb := Label.new()
	blurb.text = "1925 yangınında bir can kaybeden bir ailenin torunu, paslı bir posta kutusuyla geçmişe mektup gönderir."
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(blurb, 16, COL_PAPER_DARK)
	v.add_child(blurb)
	var cont := _mk_btn("Devam", 0, 56)
	cont.name = "Devam"
	cont.pressed.connect(_on_continue)
	v.add_child(cont)
	var nw := _mk_btn("Yeni oyun", 0, 56)
	nw.pressed.connect(_on_new_game)
	v.add_child(nw)

func _build_opening() -> void:
	opening_screen = ColorRect.new()
	opening_screen.color = COL_BG
	opening_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opening_screen.visible = false
	add_child(opening_screen)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	opening_screen.add_child(v)
	var pad_top := Control.new()
	pad_top.custom_minimum_size = Vector2(0, 8)
	v.add_child(pad_top)
	opening_art = TextureRect.new()
	opening_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	opening_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	opening_art.custom_minimum_size = Vector2(0, 280)
	opening_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(opening_art)
	var text_pad := MarginContainer.new()
	text_pad.add_theme_constant_override("margin_left", 20)
	text_pad.add_theme_constant_override("margin_right", 20)
	v.add_child(text_pad)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 8)
	text_pad.add_child(tv)
	opening_title = Label.new()
	_apply_font(opening_title, 24, COL_PAPER)
	tv.add_child(opening_title)
	opening_body = Label.new()
	opening_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(opening_body, 17, COL_PAPER_DARK)
	tv.add_child(opening_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var row_pad := MarginContainer.new()
	row_pad.add_theme_constant_override("margin_left", 16)
	row_pad.add_theme_constant_override("margin_right", 16)
	row_pad.add_theme_constant_override("margin_bottom", 16)
	row_pad.add_child(row)
	v.add_child(row_pad)
	var skip := _mk_btn("Atla", 0, 52)
	skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip.pressed.connect(_finish_opening)
	row.add_child(skip)
	var nxt := _mk_btn("İleri", 0, 52)
	nxt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nxt.pressed.connect(_opening_next)
	row.add_child(nxt)

func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.1, 0.06, 0.03, 0.72)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	overlay_card = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = COL_PAPER
	st.set_corner_radius_all(16)
	st.content_margin_left = 22
	st.content_margin_right = 22
	st.content_margin_top = 20
	st.content_margin_bottom = 20
	overlay_card.add_theme_stylebox_override("panel", st)
	center.add_child(overlay_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	overlay_card.add_child(v)
	overlay_title = Label.new()
	overlay_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(overlay_title, 22, COL_INK)
	v.add_child(overlay_title)
	overlay_body_scroll = ScrollContainer.new()
	overlay_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(overlay_body_scroll)
	overlay_body = RichTextLabel.new()
	overlay_body.bbcode_enabled = true
	overlay_body.fit_content = true
	overlay_body.scroll_active = false
	overlay_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(overlay_body, 16, COL_INK)
	overlay_body_scroll.add_child(overlay_body)
	overlay_extra = VBoxContainer.new()
	overlay_extra.add_theme_constant_override("separation", 8)
	v.add_child(overlay_extra)
	overlay_close = _mk_btn("Tamam", 0, 52)
	overlay_close.pressed.connect(_hide_overlay)
	v.add_child(overlay_close)

func _build_toast() -> void:
	toast = PanelContainer.new()
	toast.visible = false
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 1.0
	toast.anchor_bottom = 1.0
	toast.offset_left = -90
	toast.offset_right = 90
	toast.offset_top = -150
	toast.offset_bottom = -108
	var st := StyleBoxFlat.new()
	st.bg_color = Color("2B1B12CC")
	st.set_corner_radius_all(10)
	toast.add_theme_stylebox_override("panel", st)
	add_child(toast)
	toast_label = Label.new()
	toast_label.text = "Kaydedildi"
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(toast_label, 15, COL_PAPER)
	toast.add_child(toast_label)
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.wait_time = 1.6
	toast_timer.timeout.connect(func(): toast.visible = false)
	add_child(toast_timer)

func _on_saved() -> void:
	if suppress_toast or title_screen.visible or opening_screen.visible:
		return
	toast.visible = true
	toast_timer.start()

func _show_title() -> void:
	play_root.visible = false
	opening_screen.visible = false
	overlay.visible = false
	title_screen.visible = true
	var cont: Button = title_screen.find_child("Devam", true, false)
	if cont:
		cont.disabled = not SaveManager.has_save()

func _on_continue() -> void:
	if not SaveManager.has_save():
		return
	suppress_toast = true
	SaveManager.load_game()
	suppress_toast = false
	title_screen.visible = false
	play_root.visible = true
	if GameState.chapter_closed:
		_show_content("result")
		_refresh_result()
	else:
		_show_content("map")
	_refresh_all()

func _on_new_game() -> void:
	if SaveManager.has_save():
		_show_overlay("Yeni oyun?", "Mevcut kayıt silinir ve hikâye baştan başlar.", [["Evet, baştan başla", _start_new_game]], "İptal")
	else:
		_start_new_game()

func _start_new_game() -> void:
	_hide_overlay()
	suppress_toast = true
	SaveManager.clear_save()
	GameState.reset()
	suppress_toast = false
	title_screen.visible = false
	_start_opening()

func _start_opening() -> void:
	opening_index = 0
	opening_screen.visible = true
	play_root.visible = false
	_render_opening()

func _render_opening() -> void:
	var p: Dictionary = OPENING[opening_index]
	opening_art.texture = load(str(p["art"]))
	opening_title.text = "%d / 4  ·  %s" % [opening_index + 1, p["title"]]
	opening_body.text = str(p["body"])

func _opening_next() -> void:
	if opening_index >= OPENING.size() - 1:
		_finish_opening()
		return
	opening_index += 1
	_render_opening()

func _finish_opening() -> void:
	opening_screen.visible = false
	play_root.visible = true
	GameState.opening_seen = true
	GameState.intro_seen = true
	GameState.discover_clue("POST")
	_show_content("map")
	if not GameState.help_seen:
		_show_help()
		GameState.help_seen = true
		SaveManager.autosave()

func _show_panel(mode: String) -> void:
	# Overlays never steal the content host; tabs always switch a real panel.
	if mode == "result":
		if GameState.chapter_closed:
			_show_content("result")
			_refresh_result()
			return
		_try_end_or_preview()
		return
	_show_content(mode)
	if mode == "letter":
		_refresh_letter_panel()
	elif mode == "timeline":
		_refresh_timeline()
	elif mode == "journal":
		_refresh_journal()
	elif mode == "map":
		_refresh_map()

func _show_content(mode: String) -> void:
	current_panel = mode
	map_panel.visible = mode == "map"
	letter_panel.visible = mode == "letter"
	timeline_panel.visible = mode == "timeline"
	journal_panel.visible = mode == "journal"
	result_panel.visible = mode == "result"
	# Keep content_host expanded even if a panel is empty.

func _hide_overlay() -> void:
	overlay.visible = false
	# Do not change current_panel. Layout stays put.

func _show_overlay(title: String, body: String, extra_btns: Array = [], close_label: String = "Tamam") -> void:
	overlay_title.text = title
	overlay_body.text = body
	for c in overlay_extra.get_children():
		c.queue_free()
	for item in extra_btns:
		var b := _mk_btn(str(item[0]), 0, 52)
		b.pressed.connect(item[1])
		overlay_extra.add_child(b)
	overlay_close.text = close_label
	overlay.visible = true
	_fit_overlay_card()

func _fit_overlay_card() -> void:
	if overlay_card == null or not overlay.visible:
		return
	var max_w: int = mini(560, int(size.x * 0.92))
	var max_h: int = int(size.y * 0.78)
	overlay_body.custom_minimum_size = Vector2(max_w - 48, 0)
	overlay_card.custom_minimum_size = Vector2(max_w, 0)
	# After a frame, clamp height if needed.
	await get_tree().process_frame
	if not is_instance_valid(overlay_card):
		return
	var want: float = overlay_card.get_combined_minimum_size().y
	if want > max_h:
		overlay_card.custom_minimum_size = Vector2(max_w, max_h)
		overlay_body_scroll.custom_minimum_size = Vector2(0, maxi(80, max_h - 180))
	else:
		overlay_card.custom_minimum_size = Vector2(max_w, 0)
		overlay_body_scroll.custom_minimum_size = Vector2(0, 0)

func _show_help() -> void:
	_show_overlay("Nasıl oynanır?",
		"[b]Sen kimsin?[/b] 1925 yangınında bir yakınını kaybeden bir ailenin torunusun. Büyükannemin zarfı seni bu kutuya getirdi.\n\n"
		+ "[b]Pul[/b]: Bu bölümde 3 pulun var. Her mektup 1 pul harcar. Pul satın alınmaz.\n\n"
		+ "[b]H (yangın ısısı)[/b]: Yangının şiddeti. Başlangıç 5. 0-1: yangın önlendi. 2-3: kontrol altında (mahallede kaldı; yine de kayıp olabilir). 4-5: büyük yangın.\n\n"
		+ "[b]Şüphe[/b]: 1925'teki alıcı, geleceği bilen bir mektuptan kuşkulanabilir. Şüphe yüksekse yanıt daha tedirgin olur.\n\n"
		+ "[b]Bölümü bitirmek[/b] için en az 1 mektup ve 2 başlangıç ipucu gerekir (fırın, mezarlık, telgraf veya değirmen). Köprü ve menfez bilgi verir ama bu sayıya girmez.")

func _on_map_spot(key: String) -> void:
	AudioManager.play_paper()
	if key == "INFO_SCHOOL":
		if bool(GameState.last_result.get("school", false)):
			_show_overlay("Okul", "Tabelası geri geldi. Feride'nin kasabada kalması, okul umudunu yaşattı.")
		else:
			_show_overlay("Okul", "Bu yapı bugün yok. 2026 haritasında okul izi silinmiş. Geleceği, 1925'te Feride'nin kasabada kalıp kalmamasına bağlı.")
		return
	if key == "INFO_BRIDGE":
		_show_overlay("Taş köprü", "Köprü 2026'da hâlâ duruyor. 1925 yangını onu doğrudan yok etmez; asıl sınav 1926 selidir. Bu nokta bir başlangıç ipucu sayılmaz.")
		return
	if key == "INFO_CULVERT":
		_show_overlay("Menfez / Dere", "Yangını küçültmek için kömürü buraya taşımak, sonraki yıl seli ağırlaştırabilir. Bu nokta bir başlangıç ipucu sayılmaz.")
		return
	if GameState.CLUES.has(key):
		var already: bool = GameState.observed_clues.has(key)
		if not already:
			GameState.discover_clue(key)
		var c: Dictionary = GameState.CLUES[key]
		var extra := ""
		var letters: Array = c.get("letters", [])
		if letters.size() > 0:
			extra = "\n\n[b]Anladım![/b] Bu iz, şu mektupları anlamlı kılar: " + ", ".join(letters) + "."
		if key == "K2" and str(GameState.last_result.get("fire", "")) == "kontrol altında" and int(GameState.last_result.get("deaths", 0)) > 0:
			extra += "\n\nYangın kontrol altında olsa da bu şiddette varsayılan kayıp 1 kişidir; bu bir çelişki değil."
		_show_overlay(str(c.get("title", key)), str(c.get("text", "")) + extra)
	_refresh_map()

func _select_recipient(rid: String) -> void:
	composer_recipient = rid
	composer_letter_id = ""
	_refresh_letter_panel()

func _set_tone(v: String) -> void:
	GameState.letter_tone = v
	if composer_letter_id != "":
		_select_letter(composer_letter_id)

func _set_sign(v: String) -> void:
	GameState.letter_sign = v
	if composer_letter_id != "":
		_select_letter(composer_letter_id)

func _refresh_letter_panel() -> void:
	for c in letter_list.get_children():
		c.queue_free()
	for cid in recip_buttons:
		var b: Button = recip_buttons[cid]
		var info: Dictionary = GameState.CHARACTERS_STORY[cid]
		var written: bool = GameState.has_sent_to(cid)
		b.text = ("✓ " if written else "") + str(info["name"])
		b.disabled = written
	if composer_recipient == "":
		letter_preview.text = "Önce bir alıcı seç. Her kişinin mesleğini Defter'de okuyabilirsin."
		return
	if GameState.has_sent_to(composer_recipient):
		letter_preview.text = "Bu kişiye zaten mektup gönderdin."
		return
	var ch: Dictionary = GameState.CHARACTERS_STORY.get(composer_recipient, {})
	var intro := Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "%s, %s — %s" % [ch.get("name", ""), ch.get("role", ""), ch.get("intro", "")]
	_apply_font(intro, 14, COL_MUTED)
	letter_list.add_child(intro)
	var letters: Array = ChapterDatabase.letters_by_recipient.get(composer_recipient, [])
	for L in letters:
		var lid: String = L["id"]
		var supported: bool = GameState.has_clue_for_letter(lid)
		var clue_id: String = GameState.letter_supported_by(lid)
		var hint := ""
		if clue_id != "":
			var ct: Dictionary = GameState.CLUES.get(clue_id, {})
			if supported:
				hint = "  ·  İz: " + str(ct.get("title", clue_id))
			else:
				hint = "  ·  Henüz ilgili izi incelemedin"
		var b2 := _mk_btn("%s — %s%s" % [lid, L["topic"], hint], 0, 64)
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if not supported:
			b2.modulate = Color(1, 1, 1, 0.75)
		b2.pressed.connect(_select_letter.bind(lid))
		letter_list.add_child(b2)
	if composer_letter_id == "":
		letter_preview.text = "Bir mektup konusu seç. Üslup ve imza yanıtın tonunu değiştirir; tarihi değiştirmez."
	else:
		_select_letter(composer_letter_id)

func _select_letter(lid: String) -> void:
	composer_letter_id = lid
	var L: Dictionary = ChapterDatabase.get_letter(lid)
	var heat_n := int(L.get("heat", 0))
	var heat_words := "Yangın ısısını değiştirmez."
	if heat_n < 0:
		heat_words = "Yangın ısısını %d düşürür (yangın küçülür)." % abs(heat_n)
	elif heat_n > 0:
		heat_words = "Yangın ısısını %d yükseltir." % heat_n
	var sus_n := int(L.get("suspicion", 1))
	var sus_words := "Alıcı biraz kuşkulanır (şüphe +%d)." % sus_n
	if sus_n >= 2:
		sus_words = "Alıcı, mektubun geleceği bildiğini fark edebilir (şüphe +%d)." % sus_n
	var warn := ""
	if lid == "F1":
		warn = "\n\nDikkat: Bu mektup okulun kaderini değiştirebilir; Feride senden şüphelenecek."
	var clue_line := ""
	var cid: String = GameState.letter_supported_by(lid)
	if cid != "" and GameState.observed_clues.has(cid):
		clue_line = "\nBağlantı: Bu satırlar «%s» izinden geliyor." % str(GameState.CLUES[cid].get("title", cid))
	elif cid != "":
		clue_line = "\nHenüz ilgili izi haritada incelemedin; yine de gönderebilirsin, ama bağlamı kaçırabilirsin."
	letter_preview.text = "Alıcı: %s\nKonu: %s\nTavsiye: %s\n\n«%s»\n\n%s\n%s\nÜslup: %s · İmza: %s\nSonuç: %s%s%s" % [
		L.get("recipient_name", ""),
		L.get("topic", ""),
		L.get("advice", ""),
		L.get("letter", ""),
		heat_words,
		sus_words,
		("nazik" if GameState.letter_tone == "nazik" else "acil"),
		_sign_label(GameState.letter_sign),
		L.get("consequence", ""),
		clue_line,
		warn,
	]

func _sign_label(s: String) -> String:
	match s:
		"dost":
			return "bir dost"
		"torun":
			return "torun"
		_:
			return "isimsiz"

func _on_send_pressed() -> void:
	if composer_letter_id == "":
		_show_overlay("Eksik seçim", "Alıcı ve mektup seçmelisin.")
		return
	var err := GameState.can_send(composer_letter_id)
	if err != "":
		_show_overlay("Gönderilemedi", err)
		return
	AudioManager.play_stamp()
	var lid := composer_letter_id
	GameState.send_letter(lid)
	composer_letter_id = ""
	composer_recipient = ""
	_refresh_letter_panel()
	_show_content("map")
	_refresh_map()

func _on_letter_sent(letter_id: String, _result: Dictionary) -> void:
	var L: Dictionary = ChapterDatabase.get_letter(letter_id)
	var body := "[b]Gönderildi:[/b] %s\n\n%s\n\n[b]Yanıt:[/b]\n%s\n\n[i]%s[/i]" % [
		L.get("letter", ""),
		L.get("consequence", ""),
		GameState.flavor_reply(letter_id),
		StoryResolver.summarize_turkish(GameState.last_result),
	]
	_show_overlay("Mektup yola çıktı · %s" % letter_id, body)
	_refresh_all()

func _on_clue_found(_id: String) -> void:
	_refresh_all()

func _on_state_changed() -> void:
	_refresh_all()

func _on_chapter_ended(_result: Dictionary) -> void:
	_show_content("result")
	_refresh_result()

func _refresh_all() -> void:
	stamp_label.text = "%d pul" % GameState.stamps_left()
	var r: Dictionary = GameState.last_result
	heat_label.text = "H %d" % int(r.get("heat", 5))
	_refresh_map()
	if current_panel == "letter":
		_refresh_letter_panel()
	elif current_panel == "timeline":
		_refresh_timeline()
	elif current_panel == "journal":
		_refresh_journal()
	elif current_panel == "result":
		_refresh_result()

func _refresh_map() -> void:
	var r: Dictionary = GameState.last_result
	_set_building("bakery", _bakery_label(str(r.get("bakery", "açık"))), _bakery_color(str(r.get("bakery", "açık"))))
	var school_on: bool = bool(r.get("school", false))
	_set_building("school", "Okul\n(var)" if school_on else "Okul\n(yok)", COL_GOOD if school_on else COL_MUTED)
	var br := "Köprü"
	if int(r.get("bridge_stress", 0)) > 0:
		br = "Köprü\n(stresli)"
	_set_building("bridge", br, COL_BAD if int(r.get("bridge_stress", 0)) > 0 else COL_PAPER_DARK)
	var arch := "Arşiv / Telgraf\n(belge var)" if r.get("archive", false) else "Arşiv / Telgraf"
	_set_building("archive", arch, COL_GOOD if r.get("archive", false) else COL_PAPER_DARK)
	var mill := "Değirmen"
	if int(r.get("factory_debt", 0)) > 0:
		mill = "Değirmen\nborç +%d" % int(r.factory_debt)
	_set_building("mill", mill, COL_ACCENT if int(r.get("factory_debt", 0)) > 0 else COL_PAPER_DARK)
	var culv := "Menfez / Dere"
	if int(r.get("culvert", 0)) > 0:
		culv = "Menfez\ntıkalı %d" % int(r.culvert)
	if int(r.get("pollution", 0)) > 0:
		culv += "\nkirli"
	_set_building("culvert", culv, COL_BAD if int(r.get("culvert", 0)) > 0 else COL_PAPER_DARK)
	var cem := "Mezarlık\n%d kayıp" % int(r.get("deaths", 4))
	if not r.get("hasan_survives", true):
		cem += "\nHasan yok"
	_set_building("cemetery", cem, COL_BAD if int(r.get("deaths", 0)) > 0 else COL_GOOD)
	var post := "Posta Kutusu\n(açık)" if GameState.observed_clues.has("POST") else "Posta Kutusu"
	_set_building("post", post, COL_ACCENT)
	var susp = r.get("suspicion", {})
	var sus_txt := ""
	if typeof(susp) == TYPE_DICTIONARY and not susp.is_empty():
		var parts: PackedStringArray = []
		for k in susp.keys():
			var nm: Dictionary = GameState.CHARACTERS_STORY.get(str(k), {})
			parts.append("%s +%s" % [nm.get("name", k), str(susp[k])])
		sus_txt = " · Şüphe: " + ", ".join(parts)
	map_hint.text = "Yangın: %s · Kayıp: %d%s\nİpucu (başlangıç): %d / 2  ·  Gönderilen: %s" % [
		str(r.get("fire", "?")),
		int(r.get("deaths", 0)),
		sus_txt,
		GameState.starting_clue_count(),
		(", ".join(GameState.sent_letter_ids) if GameState.sent_letter_ids.size() else "yok"),
	]

func _bakery_label(state: String) -> String:
	match state:
		"yıkık":
			return "Fırın\nYIKIK"
		"kapalı":
			return "Fırın\nKAPALI"
		"hasarlı":
			return "Fırın\nHASARLI"
		_:
			return "Fırın\nAÇIK"

func _bakery_color(state: String) -> Color:
	match state:
		"yıkık":
			return COL_BAD
		"kapalı":
			return COL_ACCENT
		"hasarlı":
			return Color("A67C52")
		_:
			return COL_GOOD

func _set_building(id: String, text: String, color: Color) -> void:
	if not building_nodes.has(id):
		return
	var cell: Button = building_nodes[id]
	cell.text = text
	var st := StyleBoxFlat.new()
	st.bg_color = color if color == COL_PAPER_DARK else color.lerp(COL_PAPER, 0.45)
	st.set_corner_radius_all(12)
	st.set_border_width_all(2)
	st.border_color = COL_INK
	cell.add_theme_stylebox_override("normal", st)
	cell.add_theme_stylebox_override("hover", st)
	cell.add_theme_stylebox_override("pressed", st)

func _refresh_timeline() -> void:
	var body: RichTextLabel = timeline_panel.find_child("Body", true, false)
	if body == null:
		return
	if GameState.timeline_entries.is_empty():
		body.text = "Henüz zaman çizelgesi boş. Mektup gönderince bağlantılar burada görünür.\n\nÖrnek: Cemil Usta'nın lambaları > yangın ısısı düşer > Hasan Usta sağ kalabilir."
		return
	var s := ""
	for e in GameState.timeline_entries:
		s += "[b]%s[/b]\n%s\n\n" % [e.get("title", ""), e.get("body", "")]
	body.text = s

func _set_journal_tab(tab: String) -> void:
	journal_tab = tab
	_refresh_journal()

func _refresh_journal() -> void:
	var body: RichTextLabel = journal_panel.find_child("Body", true, false)
	if body == null:
		return
	if journal_tab == "chars":
		body.text = _character_pages()
	elif journal_tab == "links":
		body.text = _relationship_text()
	else:
		var s := ""
		for e in GameState.journal_entries:
			s += "[b]%s[/b]\n%s\n\n" % [e.get("title", ""), e.get("body", "")]
		body.text = s if s != "" else "Defter boş. Haritadaki izleri incele."

func _character_pages() -> String:
	var s := "Haritadaki izler bu insanları somutlar. Mektup atmadan önce bir bak.\n\n"
	for cid in ["H", "F", "N", "C"]:
		var c: Dictionary = GameState.CHARACTERS_STORY[cid]
		s += "[img=90x112]%s[/img]  [b]%s[/b]  ·  %s, %d\n%s\n\n" % [c["portrait"], c["name"], c["role"], int(c["age"]), c["intro"]]
	return s

func _relationship_text() -> String:
	return "[b]İğdeyaka bağları[/b]\n\n" \
		+ "Hasan Usta  —  baba/kız  —  Feride\n" \
		+ "Hasan Usta  —  ortak kömür ve gaz lambası  —  Cemil Usta\n" \
		+ "Nermin  —  telgraf uyarısı  —  Cemil Usta\n" \
		+ "Feride  —  okul umudu / ders defterleri  —  değirmen ambarı (Cemil Usta)\n\n" \
		+ "[b]Neden Cemil Usta'ya mektup Hasan'ı kurtarabilir?[/b]\n" \
		+ "Yangın, değirmendeki bakımsız gaz lambasından ortak kömüre ve oradan fırına sıçrar. Cemil Usta lambaları değiştirirse (C1) yangın ısısı düşer. Isı 4'ün altına inince Hasan Usta'ya hiç mektup gitmese de hayatta kalır. Bu bir hata değil; aynı gecenin paylaşılmış riskidir."

func _refresh_result() -> void:
	var body: RichTextLabel = result_panel.find_child("Body", true, false)
	if body:
		body.text = GameState.ending_summary()

func _try_end_or_preview() -> void:
	var summary: String = StoryResolver.summarize_turkish(GameState.last_result)
	if GameState.can_end_chapter():
		_show_overlay("Bölümü bitir?", summary + "\n\nBölümü kapatmak istiyor musun?", [["Bölümü kapat", _on_confirm_end_chapter]], "İptal")
	else:
		var need: String = "Bölümü kapatmak için en az 1 mektup ve 2 başlangıç ipucu gerekir (fırın, mezarlık, telgraf veya değirmen). Şu an: %d mektup, %d ipucu." % [GameState.sent_letter_ids.size(), GameState.starting_clue_count()]
		_show_overlay("Ara sonuç", summary + "\n\n" + need)

func _on_confirm_end_chapter() -> void:
	_hide_overlay()
	GameState.end_chapter()
	_show_content("result")
	_refresh_result()

func _on_restart() -> void:
	_show_overlay("Yeniden başla?", "Kayıt silinir ve bölüm başa döner.", [["Evet, sıfırla", _on_confirm_restart]], "İptal")

func _on_confirm_restart() -> void:
	_hide_overlay()
	suppress_toast = true
	SaveManager.clear_save()
	GameState.reset()
	suppress_toast = false
	composer_recipient = ""
	composer_letter_id = ""
	play_root.visible = false
	_start_opening()
