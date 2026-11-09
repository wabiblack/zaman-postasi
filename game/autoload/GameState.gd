extends Node
## Runtime play state for Chapter 1 prototype.

signal state_changed
signal letter_sent(letter_id: String, result: Dictionary)
signal clue_found(clue_id: String)
signal chapter_ended(result: Dictionary)

const CLUES := {
	"K1": {"title": "Fırın enkazı", "text": "Kömür isi ve gaz kokusu. Yangın burada büyümüş olabilir."},
	"K2": {"title": "Mezar taşları", "text": "1925 tarihli dört taş: 'İğdeyaka yangınında dört can.'"},
	"K3": {"title": "Telgraf penceresi", "text": "Hasarlı camın arkasında yanmış bir teslim defteri izi."},
	"K4": {"title": "Değirmen çizelgesi", "text": "Bakım defterinde eksik bir imza satırı."},
	"POST": {"title": "Paslı posta kutusu", "text": "Üzerinde: 'Yazılmamış olanı da taşıyoruz.' 1925'e giden mektuplar."},
}

var sent_letter_ids: Array = []
var observed_clues: Array = []
var journal_entries: Array = []
var timeline_entries: Array = []
var last_result: Dictionary = {}
var intro_seen: bool = false
var chapter_closed: bool = false

func _ready() -> void:
	reset()

func reset() -> void:
	sent_letter_ids.clear()
	observed_clues.clear()
	journal_entries.clear()
	timeline_entries.clear()
	last_result = StoryResolver.resolve([])
	intro_seen = false
	chapter_closed = false
	_add_journal("2026 · İğdeyaka tepesi", "Eskiden burada bir kasaba vardı. Paslı bir posta kutusu duruyor.")
	state_changed.emit()

func stamps_left() -> int:
	return ChapterDatabase.stamp_budget() - sent_letter_ids.size()

func has_sent_to(recipient: String) -> bool:
	for lid in sent_letter_ids:
		var L: Dictionary = ChapterDatabase.get_letter(lid)
		if str(L.get("recipient", "")) == recipient:
			return true
	return false

func discover_clue(clue_id: String) -> void:
	if observed_clues.has(clue_id):
		return
	observed_clues.append(clue_id)
	var c: Dictionary = CLUES.get(clue_id, {})
	_add_journal(str(c.get("title", clue_id)), str(c.get("text", "")))
	clue_found.emit(clue_id)
	state_changed.emit()
	SaveManager.autosave()

func can_send(letter_id: String) -> String:
	if chapter_closed:
		return "Bölüm kapandı."
	if stamps_left() <= 0:
		return "Pul kalmadı."
	if sent_letter_ids.has(letter_id):
		return "Bu mektup zaten gönderildi."
	var letter: Dictionary = ChapterDatabase.get_letter(letter_id)
	if letter.is_empty():
		return "Geçersiz mektup."
	if has_sent_to(str(letter.recipient)):
		return "Bu kişiye zaten mektup gönderdin."
	# Soft unlock: need at least POST + one map clue; letter UI can still open earlier with warning
	return ""

func send_letter(letter_id: String) -> Dictionary:
	var err := can_send(letter_id)
	if err != "":
		push_warning(err)
		return {}
	sent_letter_ids.append(letter_id)
	last_result = StoryResolver.resolve(sent_letter_ids)
	var letter: Dictionary = ChapterDatabase.get_letter(letter_id)
	_add_journal("Mektup gönderildi · %s" % letter_id, str(letter.get("letter", "")))
	_add_timeline(letter)
	letter_sent.emit(letter_id, last_result)
	state_changed.emit()
	SaveManager.autosave()
	return last_result

func _add_journal(title: String, body: String) -> void:
	journal_entries.append({"title": title, "body": body})

func _add_timeline(letter: Dictionary) -> void:
	timeline_entries.append({
		"id": letter.get("id", ""),
		"title": "%s → %s" % [letter.get("id", ""), letter.get("recipient_name", "")],
		"body": str(letter.get("consequence", "")),
	})
	# Simple causal hints from GDD examples
	if letter.get("id") == "H1":
		timeline_entries.append({"id": "link_H1", "title": "Bağlantı", "body": "Fırın kapandı → gelir bitti → Feride ayrılabilir → okul risk altında."})
	if letter.get("id") == "N2":
		timeline_entries.append({"id": "link_N2", "title": "Bağlantı", "body": "Kayıtlar kopyalandı → yangının kökeni belgelenebilir; söylenti artar."})
	if letter.get("id") == "F1":
		timeline_entries.append({"id": "link_F1", "title": "Bağlantı", "body": "Nöbet → alev erken görülür → okul umudu sürer; Feride şüphelenir."})

func can_end_chapter() -> bool:
	var clue_count := 0
	for c in observed_clues:
		if str(c) != "POST":
			clue_count += 1
	return sent_letter_ids.size() >= 1 and clue_count >= 2 and not chapter_closed

func end_chapter() -> void:
	if chapter_closed:
		return
	chapter_closed = true
	last_result = StoryResolver.resolve(sent_letter_ids)
	chapter_ended.emit(last_result)
	state_changed.emit()
	SaveManager.autosave()
