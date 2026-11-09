extends Node
## Loads authoritative Chapter-1 JSON from paket schema.

var chapter: Dictionary = {}
var letters_by_id: Dictionary = {}
var letters_by_recipient: Dictionary = {}
var characters: Array = []  # [{id, name, role, age_hint}]

const RECIPIENT_ORDER := ["H", "F", "N", "C"]

const REPLIES := {
	"H1": "Üç gün ekmek çıkarmazsam bizi kim doyuracak? Yine de lambanın kokusu içime sinmiyordu.",
	"H2": null,
	"H3": "Komşular çağrıma geldi. Ama bu mektubu kim gönderdi, bilen yok.",
	"F1": "Kim olduğunu bilmiyorum. Fakat dediğin saatte koku geldi. Bunu nasıl bildin?",
	"F2": "Gitmek korkutuyor. Yine de bir gün geri dönüp işe yaramayı umuyorum.",
	"F3": "Defterler kurtuldu. Cemil Usta bu işe pek sevinmedi.",
	"N1": null,
	"N2": "Dosyayı sakladım. Birisinin geleceği bu kadar merak etmesi tuhaf.",
	"N3": "Telgraf yetişti. Fakat Cemil bana zararını unutturmayacak gibi.",
	"C1": null,
	"C2": null,
	"C3": "Defteri teslim ettim. Kimse bu kadar eski bir imzayla neden ilgilendiğini anlamıyor.",
}

func _ready() -> void:
	load_chapter("res://data/Bolum1_Karar_Sistemi.json")

func load_chapter(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("ChapterDatabase: cannot open %s" % path)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ChapterDatabase: invalid JSON")
		return
	chapter = parsed
	characters.clear()
	var raw_chars: Variant = chapter.get("characters", {})
	if typeof(raw_chars) == TYPE_DICTIONARY:
		for rid in RECIPIENT_ORDER:
			if raw_chars.has(rid):
				var label: String = str(raw_chars[rid])
				var name: String = label
				if "—" in label:
					name = label.split("—")[0].strip_edges()
				elif "-" in label:
					name = label.split("-")[0].strip_edges()
				characters.append({"id": rid, "name": name, "role": label, "full": label})
	letters_by_id.clear()
	letters_by_recipient.clear()
	for letter in chapter.get("letters", []):
		var L: Dictionary = letter.duplicate(true)
		# Compose full letter text if missing
		if not L.has("letter") or L["letter"] == null:
			L["letter"] = _compose_letter(L)
		if not L.has("recipient_name"):
			L["recipient_name"] = get_character(str(L.get("recipient", ""))).get("name", L.get("recipient", ""))
		if not L.has("reply"):
			L["reply"] = REPLIES.get(str(L.get("id", "")), null)
		letters_by_id[L["id"]] = L
		var rid2: String = str(L["recipient"])
		if not letters_by_recipient.has(rid2):
			letters_by_recipient[rid2] = []
		letters_by_recipient[rid2].append(L)

func _compose_letter(L: Dictionary) -> String:
	var recip: Dictionary = get_character(str(L.get("recipient", "")))
	var name: String = str(recip.get("name", str(L.get("recipient", ""))))
	var topic: String = str(L.get("topic", ""))
	var advice: String = str(L.get("advice", ""))
	return "%s, %s hakkında: %s" % [name, topic, advice]

func get_letter(id: String) -> Dictionary:
	return letters_by_id.get(id, {})

func get_character(id: String) -> Dictionary:
	for c in characters:
		if c["id"] == id:
			return c
	return {}

func stamp_budget() -> int:
	return int(chapter.get("letter_budget", chapter.get("stamp_budget", 3)))

func chapter_title() -> String:
	return "Külün Kokusu"

func narrative_for_fire(fire: String) -> String:
	match fire:
		"önlendi":
			return "Yangın başlamadan bastırıldı. Gelecek haritada yanık izi yok."
		"kontrol altında":
			return "Yangın mahallede kaldı. Fırın hasarlı veya kapalı görünebilir."
		_:
			return "Yangın mahalleyi yuttu. Fırın enkaza döndü."
