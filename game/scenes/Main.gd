extends Control
## Zaman Postası — Bölüm 1 prototip arayüzü (tek sahne, kodla UI).

const COL_BG := Color("473324")
const COL_PAPER := Color("E8D5B5")
const COL_PAPER_DARK := Color("D4B896")
const COL_INK := Color("2B1B12")
const COL_ACCENT := Color("C45C26")
const COL_GOOD := Color("3E6B4F")
const COL_BAD := Color("8B3A2A")
const COL_MUTED := Color("8A7058")
const COL_PANEL := Color("5A3D28")

var header: HBoxContainer
var stamp_label: Label
var heat_label: Label
var map_panel: Control
var building_nodes: Dictionary = {}
var hotspot_buttons: Dictionary = {}
var bottom_bar: HBoxContainer
var overlay: Control
var overlay_title: Label
var overlay_body: RichTextLabel
var overlay_extra: VBoxContainer
var current_panel: String = "map" # map|letter|timeline|journal|end

# Letter composer state
var composer_recipient: String = ""
var composer_letter_id: String = ""
var letter_panel: Control
var letter_list: VBoxContainer
var letter_preview: Label
var send_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	GameState.state_changed.connect(_on_state_changed)
	GameState.letter_sent.connect(_on_letter_sent)
	GameState.clue_found.connect(_on_clue_found)
	GameState.chapter_ended.connect(_on_chapter_ended)
	SaveManager.load_game()
	_refresh_all()
	if not GameState.intro_seen:
		_show_intro()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 72)
	header.add_theme_constant_override("separation", 8)
	_pad(header, 12, 10, 12, 8)
	root.add_child(header)

	var title := Label.new()
	title.text = "Zaman Postası"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COL_PAPER)
	header.add_child(title)

	stamp_label = Label.new()
	stamp_label.add_theme_font_size_override("font_size", 18)
	stamp_label.add_theme_color_override("font_color", COL_ACCENT)
	header.add_child(stamp_label)

	heat_label = Label.new()
	heat_label.add_theme_font_size_override("font_size", 16)
	heat_label.add_theme_color_override("font_color", COL_PAPER_DARK)
	header.add_child(heat_label)

	var restart := _mk_btn("↻", 56)
	restart.pressed.connect(_on_restart)
	header.add_child(restart)

	# Map area
	map_panel = Control.new()
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(map_panel)
	_build_map(map_panel)

	# Letter composer (hidden by default, overlays map area via sibling)
	letter_panel = _build_letter_panel()
	letter_panel.visible = false
	root.add_child(letter_panel)
	# Move letter panel to fill between header and bottom — use set as sibling replacing visually
	# Actually put letter_panel as child of a content stack
	# Simpler: letter_panel is full overlay inside map_panel's parent with expand
	root.move_child(letter_panel, map_panel.get_index())
	letter_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	letter_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	bottom_bar = HBoxContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 78)
	bottom_bar.add_theme_constant_override("separation", 6)
	_pad(bottom_bar, 8, 8, 8, 10)
	root.add_child(bottom_bar)
	for item in [
		["Harita", "map"],
		["Mektup", "letter"],
		["Zaman", "timeline"],
		["Defter", "journal"],
		["Sonuç", "end"],
	]:
		var b := _mk_btn(item[0], 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 58)
		var mode: String = item[1]
		b.pressed.connect(func(): _show_panel(mode))
		bottom_bar.add_child(b)

	overlay = _build_overlay()
	add_child(overlay)

func _pad(c: Control, l: int, t: int, r: int, b: int) -> void:
	# Use margin via Theme / separate MarginContainer wrapper when needed.
	c.set_meta("pad", Vector4(l, t, r, b))

func _mk_btn(text: String, min_w: int = 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 48)
	b.add_theme_font_size_override("font_size", 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = COL_ACCENT
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.add_theme_color_override("font_color", COL_PAPER)
	b.add_theme_color_override("font_hover_color", COL_PAPER)
	b.add_theme_color_override("font_pressed_color", COL_PAPER)
	return b

func _build_map(parent: Control) -> void:
	var paper := ColorRect.new()
	paper.color = COL_PAPER
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.offset_left = 10
	paper.offset_top = 4
	paper.offset_right = -10
	paper.offset_bottom = -4
	parent.add_child(paper)

	var caption := Label.new()
	caption.text = "İğdeyaka · 2026 (geçmişe mektupla dokun)"
	caption.position = Vector2(24, 16)
	caption.add_theme_font_size_override("font_size", 15)
	caption.add_theme_color_override("font_color", COL_MUTED)
	parent.add_child(caption)

	# Buildings as flat rounded panels
	var defs := [
		["bakery", "Fırın", Vector2(40, 70), Vector2(200, 110)],
		["school", "Okul", Vector2(270, 70), Vector2(180, 110)],
		["bridge", "Köprü", Vector2(40, 210), Vector2(200, 90)],
		["archive", "Arşiv/Telgraf", Vector2(270, 210), Vector2(180, 90)],
		["mill", "Değirmen", Vector2(40, 330), Vector2(200, 100)],
		["culvert", "Menfez/Dere", Vector2(270, 330), Vector2(180, 100)],
		["cemetery", "Mezarlık", Vector2(40, 460), Vector2(200, 100)],
		["post", "Posta Kutusu", Vector2(270, 460), Vector2(180, 100)],
	]
	for d in defs:
		var panel := Panel.new()
		panel.position = d[2]
		panel.size = d[3]
		var style := StyleBoxFlat.new()
		style.bg_color = COL_PAPER_DARK
		style.set_corner_radius_all(12)
		style.border_color = COL_INK
		style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", style)
		parent.add_child(panel)
		var lab := Label.new()
		lab.name = "Title"
		lab.text = d[1]
		lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 18)
		lab.add_theme_color_override("font_color", COL_INK)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(lab)
		building_nodes[d[0]] = panel

	# Hotspots (invisible buttons over clue spots)
	var spots := [
		["POST", "post", "Posta kutusu"],
		["K1", "bakery", "Fırını incele"],
		["K2", "cemetery", "Mezarlığı incele"],
		["K3", "archive", "Telgrafı incele"],
		["K4", "mill", "Değirmeni incele"],
	]
	for s in spots:
		var target: Panel = building_nodes[s[1]]
		var btn := Button.new()
		btn.text = ""
		btn.flat = true
		btn.position = target.position
		btn.size = target.size
		btn.tooltip_text = s[2]
		var cid: String = s[0]
		btn.pressed.connect(func(): _on_hotspot(cid))
		parent.add_child(btn)
		hotspot_buttons[cid] = btn

	var hint := Label.new()
	hint.name = "MapHint"
	hint.position = Vector2(24, 580)
	hint.size = Vector2(660, 80)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", COL_INK)
	hint.text = "İpucu noktalarına dokun. Sonra Mektup sekmesinden geçmişe yaz."
	parent.add_child(hint)

func _build_letter_panel() -> Control:
	var wrap := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COL_PAPER
	style.set_corner_radius_all(0)
	wrap.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	wrap.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)

	var t := Label.new()
	t.text = "Mektup Yaz (hazır cümle parçaları)"
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", COL_INK)
	v.add_child(t)

	var recip_row := HBoxContainer.new()
	recip_row.add_theme_constant_override("separation", 8)
	v.add_child(recip_row)
	for c in ChapterDatabase.characters:
		var b := _mk_btn(str(c["name"]).split(" ")[0], 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 52)
		var rid: String = c["id"]
		b.pressed.connect(func(): _select_recipient(rid))
		# store ref via meta
		b.set_meta("recipient", rid)
		recip_row.add_child(b)
		b.add_theme_color_override("font_color", COL_PAPER)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	letter_list = VBoxContainer.new()
	letter_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	letter_list.add_theme_constant_override("separation", 8)
	scroll.add_child(letter_list)

	letter_preview = Label.new()
	letter_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	letter_preview.custom_minimum_size = Vector2(0, 110)
	letter_preview.add_theme_font_size_override("font_size", 16)
	letter_preview.add_theme_color_override("font_color", COL_INK)
	letter_preview.text = "Önce bir alıcı, sonra bir mektup seç."
	v.add_child(letter_preview)

	send_btn = _mk_btn("✉  Mektubu Gönder (1 pul)", 0)
	send_btn.custom_minimum_size = Vector2(0, 60)
	send_btn.pressed.connect(_on_send_pressed)
	v.add_child(send_btn)
	return wrap

func _build_overlay() -> Control:
	var o := ColorRect.new()
	o.color = Color(0.1, 0.06, 0.03, 0.82)
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.visible = false
	o.mouse_filter = Control.MOUSE_FILTER_STOP

	var card := Panel.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.anchor_left = 0.06
	card.anchor_right = 0.94
	card.anchor_top = 0.12
	card.anchor_bottom = 0.88
	card.offset_left = 0
	card.offset_right = 0
	card.offset_top = 0
	card.offset_bottom = 0
	var st := StyleBoxFlat.new()
	st.bg_color = COL_PAPER
	st.set_corner_radius_all(16)
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 18
	st.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", st)
	o.add_child(card)

	var vv := VBoxContainer.new()
	vv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vv.add_theme_constant_override("separation", 12)
	card.add_child(vv)

	overlay_title = Label.new()
	overlay_title.add_theme_font_size_override("font_size", 24)
	overlay_title.add_theme_color_override("font_color", COL_INK)
	overlay_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vv.add_child(overlay_title)

	var body_scroll := ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vv.add_child(body_scroll)
	overlay_body = RichTextLabel.new()
	overlay_body.bbcode_enabled = true
	overlay_body.fit_content = true
	overlay_body.scroll_active = false
	overlay_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_body.add_theme_color_override("default_color", COL_INK)
	overlay_body.add_theme_font_size_override("normal_font_size", 17)
	body_scroll.add_child(overlay_body)

	overlay_extra = VBoxContainer.new()
	overlay_extra.add_theme_constant_override("separation", 8)
	vv.add_child(overlay_extra)

	var close := _mk_btn("Tamam", 0)
	close.custom_minimum_size = Vector2(0, 56)
	close.pressed.connect(func(): overlay.visible = false)
	vv.add_child(close)
	return o

func _show_overlay(title: String, body: String, extra_btns: Array = []) -> void:
	overlay_title.text = title
	overlay_body.text = body
	for c in overlay_extra.get_children():
		c.queue_free()
	for item in extra_btns:
		var b := _mk_btn(str(item[0]), 0)
		b.custom_minimum_size = Vector2(0, 52)
		var cb: Callable = item[1] as Callable
		b.pressed.connect(cb)
		overlay_extra.add_child(b)
	overlay.visible = true

func _show_intro() -> void:
	_show_overlay(
		"İğdeyaka · Külün Kokusu",
		"[b]Burada eskiden bir kasaba vardı.[/b]\n\n2026'da tepedeki paslı posta kutusu, 1925 Haziran'ına mektup taşıyor.\n\nYangın gecesinden önce doğru kişilere doğru uyarıları gönder; ama her kurtarışın bir bedeli var.\n\n• Haritadaki noktaları incele\n• En fazla 3 pul kullan\n• Alıcı başına 1 mektup\n• En az 1 mektup + 2 ipucu sonrası sonucu kapat",
		[["Başla", _on_intro_start]]
	)

func _on_intro_start() -> void:
	GameState.intro_seen = true
	overlay.visible = false
	GameState.discover_clue("POST")
	SaveManager.autosave()

func _show_panel(mode: String) -> void:
	current_panel = mode
	map_panel.visible = mode == "map"
	letter_panel.visible = mode == "letter"
	if mode == "letter":
		_refresh_letter_panel()
	elif mode == "timeline":
		_show_timeline()
	elif mode == "journal":
		_show_journal()
	elif mode == "end":
		_try_end_or_preview()
	elif mode == "map":
		_refresh_map()

func _on_hotspot(clue_id: String) -> void:
	AudioManager.play_paper()
	GameState.discover_clue(clue_id)
	var c: Dictionary = GameState.CLUES.get(clue_id, {})
	_show_overlay(str(c.get("title", clue_id)), str(c.get("text", "")))

func _select_recipient(rid: String) -> void:
	composer_recipient = rid
	composer_letter_id = ""
	_refresh_letter_panel()

func _refresh_letter_panel() -> void:
	for c in letter_list.get_children():
		c.queue_free()
	if composer_recipient == "":
		letter_preview.text = "Önce bir alıcı seç."
		return
	if GameState.has_sent_to(composer_recipient):
		letter_preview.text = "Bu kişiye zaten mektup gönderdin."
		return
	var letters: Array = ChapterDatabase.letters_by_recipient.get(composer_recipient, [])
	for L in letters:
		var b := _mk_btn("%s — %s" % [L["id"], L["topic"]], 0)
		b.custom_minimum_size = Vector2(640, 64)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var lid: String = L["id"]
		b.pressed.connect(func(): _select_letter(lid))
		letter_list.add_child(b)
	if composer_letter_id == "":
		letter_preview.text = "Bir mektup konusu seç."
	else:
		_select_letter(composer_letter_id)

func _select_letter(lid: String) -> void:
	composer_letter_id = lid
	var L: Dictionary = ChapterDatabase.get_letter(lid)
	var warn := ""
	if lid == "F1":
		warn = "\n\n⚠ Bu mektup okulun kaderini değiştirebilir; Feride senden şüphelenecek."
	letter_preview.text = "Alıcı: %s\nKonu: %s\nTavsiye: %s\n\n«%s»\n\nΔH %+d · Şüphe +%d\nSonuç: %s%s" % [
		L.get("recipient_name", ""),
		L.get("topic", ""),
		L.get("advice", ""),
		L.get("letter", ""),
		int(L.get("heat", 0)),
		int(L.get("suspicion", 1)),
		L.get("consequence", ""),
		warn,
	]

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
	_show_panel("map")

func _on_letter_sent(letter_id: String, _result: Dictionary) -> void:
	var L: Dictionary = ChapterDatabase.get_letter(letter_id)
	var reply = L.get("reply", null)
	var reply_text := "Cevap gelmez." if reply == null else str(reply)
	var body := "[b]Gönderildi:[/b] %s\n\n%s\n\n[b]Yanıt:[/b] %s\n\n[i]%s[/i]" % [
		L.get("letter", ""),
		L.get("consequence", ""),
		reply_text,
		StoryResolver.summarize_turkish(GameState.last_result),
	]
	_show_overlay("Mektup yola çıktı · %s" % letter_id, body)
	_refresh_all()

func _on_clue_found(_id: String) -> void:
	_refresh_all()

func _on_state_changed() -> void:
	_refresh_all()

func _on_chapter_ended(result: Dictionary) -> void:
	_show_overlay("Bölüm Sonu · Külün Kokusu", StoryResolver.summarize_turkish(result) + "\n\nSonraki bölüm tohumu: İğdeyaka Deresi, Mayıs 1926.")

func _refresh_all() -> void:
	stamp_label.text = "✉ %d pul" % GameState.stamps_left()
	var r: Dictionary = GameState.last_result
	heat_label.text = "H=%d" % int(r.get("heat", 5))
	_refresh_map()

func _refresh_map() -> void:
	var r: Dictionary = GameState.last_result
	_set_building("bakery", _bakery_label(str(r.get("bakery", "açık"))), _bakery_color(str(r.get("bakery", "açık"))))
	var school_txt := "Okul\n(var)" if r.get("school", false) else "Okul\n(yok)"
	_set_building("school", school_txt, COL_GOOD if r.get("school", false) else COL_MUTED)
	var bridge_txt := "Köprü"
	if int(r.get("bridge_stress", 0)) > 0:
		bridge_txt = "Köprü\n(stresli)"
	_set_building("bridge", bridge_txt, COL_BAD if int(r.get("bridge_stress", 0)) > 0 else COL_PAPER_DARK)
	var arch := "Arşiv/Telgraf"
	if r.get("archive", false):
		arch = "Arşiv\n(belge var)"
	_set_building("archive", arch, COL_GOOD if r.get("archive", false) else COL_PAPER_DARK)
	var mill := "Değirmen"
	if int(r.get("factory_debt", 0)) > 0:
		mill = "Değirmen\nborç +%d" % int(r.factory_debt)
	_set_building("mill", mill, COL_ACCENT if int(r.get("factory_debt", 0)) > 0 else COL_PAPER_DARK)
	var culv := "Menfez/Dere"
	if int(r.get("culvert", 0)) > 0:
		culv = "Menfez\ntıkalı %d" % int(r.culvert)
	if int(r.get("pollution", 0)) > 0:
		culv += "\nkirli"
	_set_building("culvert", culv, COL_BAD if int(r.get("culvert", 0)) > 0 else COL_PAPER_DARK)
	var cem := "Mezarlık\n%d kayıp" % int(r.get("deaths", 4))
	if not r.get("hasan_survives", true):
		cem += "\nHasan yok"
	_set_building("cemetery", cem, COL_BAD if int(r.get("deaths", 0)) > 0 else COL_GOOD)
	var post := "Posta Kutusu"
	if GameState.observed_clues.has("POST"):
		post = "Posta Kutusu\n(açık)"
	_set_building("post", post, COL_ACCENT)

	var hint: Label = map_panel.get_node_or_null("MapHint")
	if hint:
		var susp = r.get("suspicion", {})
		var sus_txt := ""
		if typeof(susp) == TYPE_DICTIONARY and not susp.is_empty():
			var parts: PackedStringArray = []
			for k in susp.keys():
				parts.append("%s +%s" % [k, str(susp[k])])
			sus_txt = " · Şüphe: " + ", ".join(parts)
		hint.text = "Yangın: %s · Kayıp: %d%s\nİpucu: %d · Gönderilen: %s" % [
			str(r.get("fire", "?")),
			int(r.get("deaths", 0)),
			sus_txt,
			GameState.observed_clues.size(),
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
	var panel: Panel = building_nodes[id]
	var st: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
	st.bg_color = color if color != COL_PAPER_DARK else COL_PAPER_DARK
	# Keep readable: for status colors use tinted paper
	if color != COL_PAPER_DARK:
		st.bg_color = color.lerp(COL_PAPER, 0.45)
	panel.add_theme_stylebox_override("panel", st)
	var lab: Label = panel.get_node("Title")
	lab.text = text

func _show_timeline() -> void:
	var body := ""
	if GameState.timeline_entries.is_empty():
		body = "Henüz zaman çizelgesi boş. Mektup gönderince bağlantılar burada görünecek."
	else:
		for e in GameState.timeline_entries:
			body += "[b]%s[/b]\n%s\n\n" % [e.get("title", ""), e.get("body", "")]
	_show_overlay("Zaman Çizelgesi", body)

func _show_journal() -> void:
	var body := ""
	for e in GameState.journal_entries:
		body += "[b]%s[/b]\n%s\n\n" % [e.get("title", ""), e.get("body", "")]
	_show_overlay("Araştırma Defteri", body if body != "" else "Defter boş.")

func _try_end_or_preview() -> void:
	var summary: String = StoryResolver.summarize_turkish(GameState.last_result)
	if GameState.can_end_chapter():
		_show_overlay("Bölümü Bitir?", summary + "\n\nBölümü kapatmak istiyor musun?", [["Bölümü Kapat", _on_confirm_end_chapter]])
	else:
		var need: String = "En az 1 mektup ve 2 harita ipucu (posta kutusu hariç) gerekli."
		_show_overlay("Ara Sonuç", summary + "\n\n" + need)

func _on_confirm_end_chapter() -> void:
	overlay.visible = false
	GameState.end_chapter()

func _on_restart() -> void:
	_show_overlay("Yeniden Başla?", "Kayıt silinir ve bölüm başa döner.", [["Evet, sıfırla", _on_confirm_restart]])

func _on_confirm_restart() -> void:
	SaveManager.clear_save()
	GameState.reset()
	composer_recipient = ""
	composer_letter_id = ""
	overlay.visible = false
	_show_panel("map")
	_show_intro()
