extends Node
## Runtime play state for Chapter 1 prototype.

signal state_changed
signal letter_sent(letter_id: String, result: Dictionary)
signal clue_found(clue_id: String)
signal chapter_ended(result: Dictionary)

const CLUES := {
	"K1": {
		"title": "Fırın enkazı",
		"text": "Kömür isi ve sönmüş bir gaz lambası kokusu. Yangın burada büyümüş olabilir. Burası Hasan Usta'nın fırınıydı; kömür stoku Cemil Usta'nın değirmeniyle ortak.",
		"character": "H",
		"letters": ["H1", "H2", "C2"],
	},
	"K2": {
		"title": "Mezar taşları",
		"text": "1925 tarihli dört taş: 'İğdeyaka yangınında dört can.' Büyükannenin kaybettiği isim belki de bunlardan biri. O gece bir uyarı ya da komşu nöbeti hayat kurtarabilirdi.",
		"character": "H",
		"letters": ["H3", "N1"],
	},
	"K3": {
		"title": "Telgraf penceresi",
		"text": "Hasarlı camın arkasında yanmış bir teslim defteri izi. Burası Nermin'in nöbet tuttuğu telgraf noktası. Kayıtlar yangının kökenini kanıtlayabilir; bir uyarı da değirmene yetişebilirdi.",
		"character": "N",
		"letters": ["N2", "N3"],
	},
	"K4": {
		"title": "Değirmen çizelgesi",
		"text": "Cemil Usta'nın bakım defterinde eksik bir imza satırı. Eski gaz lambaları değiştirilmezse kıvılcım ortak kömürden Hasan'ın fırınına sıçrayabilir.",
		"character": "C",
		"letters": ["C1", "C3"],
	},
	"POST": {
		"title": "Paslı posta kutusu",
		"text": "Üzerinde: 'Yazılmamış olanı da taşıyoruz.' Büyükannenin zarfındaki adres burayı gösteriyordu. Kutuya atılan mektuplar 1925 Haziran'ına gidiyor.",
		"character": "",
		"letters": [],
	},
}

const LETTER_CLUE := {
	"H1": "K1", "H2": "K1", "H3": "K2",
	"F1": "K1", "F2": "K2", "F3": "K4",
	"N1": "K2", "N2": "K3", "N3": "K3",
	"C1": "K4", "C2": "K1", "C3": "K4",
}

const CHARACTERS_STORY := {
	"H": {
		"id": "H",
		"name": "Hasan Usta",
		"age": 46,
		"role": "Fırıncı",
		"portrait": "res://art/portrait_hasan.png",
		"intro": "Feride'nin babası. Ekmek ve namus arasında sıkışmış; iftira edilmekten korkar.",
	},
	"F": {
		"id": "F",
		"name": "Feride",
		"age": 19,
		"role": "Öğretmen adayı",
		"portrait": "res://art/portrait_feride.png",
		"intro": "Çocuklara ders vermek isteyen, inatçı ve meraklı bir genç. Okul umudu ile şehirdeki sağlık eğitimi arasında kalmıştır.",
	},
	"N": {
		"id": "N",
		"name": "Nermin",
		"age": 28,
		"role": "Telgraf görevlisi",
		"portrait": "res://art/portrait_nermin.png",
		"intro": "Dikkatli, kuşkucu, kayıt tutmayı sever. Teslim defterindeki eksik satır onu rahatsız eder.",
	},
	"C": {
		"id": "C",
		"name": "Cemil Usta",
		"age": 41,
		"role": "Değirmen ustabaşı",
		"portrait": "res://art/portrait_cemil.png",
		"intro": "İşçiler ve makineler arasında kalmıştır. Eski gaz lambalarına bütçe ayrılmamıştır; fırınla aynı kömür ve lamba riskini paylaşır.",
	},
}

var sent_letter_ids: Array = []
var observed_clues: Array = []
var journal_entries: Array = []
var timeline_entries: Array = []
var last_result: Dictionary = {}
var intro_seen: bool = false
var help_seen: bool = false
var opening_seen: bool = false
var chapter_closed: bool = false
var letter_tone: String = "nazik"  # nazik | acil
var letter_sign: String = "isimsiz"  # isimsiz | dost | torun

func _ready() -> void:
	reset()

func reset() -> void:
	sent_letter_ids.clear()
	observed_clues.clear()
	journal_entries.clear()
	timeline_entries.clear()
	last_result = StoryResolver.resolve([])
	intro_seen = false
	help_seen = false
	opening_seen = false
	chapter_closed = false
	letter_tone = "nazik"
	letter_sign = "isimsiz"
	_add_journal("2026 · İğdeyaka tepesi", "Büyükannemin zarfı beni buraya getirdi. Eskiden burada bir kasaba vardı. Paslı bir posta kutusu duruyor.")
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
	_add_outcome_explanations(letter_id, last_result)
	letter_sent.emit(letter_id, last_result)
	state_changed.emit()
	SaveManager.autosave()
	return last_result

func _add_journal(title: String, body: String) -> void:
	journal_entries.append({"title": title, "body": body})

func _add_timeline(letter: Dictionary) -> void:
	timeline_entries.append({
		"id": letter.get("id", ""),
		"title": "%s > %s" % [letter.get("id", ""), letter.get("recipient_name", "")],
		"body": str(letter.get("consequence", "")),
	})
	# Simple causal hints from GDD examples
	if letter.get("id") == "H1":
		timeline_entries.append({"id": "link_H1", "title": "Bağlantı", "body": "Fırın kapandı > gelir bitti > Feride ayrılabilir > okul risk altında."})
	if letter.get("id") == "N2":
		timeline_entries.append({"id": "link_N2", "title": "Bağlantı", "body": "Kayıtlar kopyalandı > yangının kökeni belgelenebilir; söylenti artar."})
	if letter.get("id") == "F1":
		timeline_entries.append({"id": "link_F1", "title": "Bağlantı", "body": "Nöbet > alev erken görülür > okul umudu sürer; Feride şüphelenir."})

func end_chapter() -> void:
	if chapter_closed:
		return
	chapter_closed = true
	last_result = StoryResolver.resolve(sent_letter_ids)
	chapter_ended.emit(last_result)
	state_changed.emit()
	SaveManager.autosave()

func starting_clue_count() -> int:
	# GDD 7.8: iki başlangıç ipucu. POST otomatik açılır, sayıya girmez.
	# Resmi başlangıç ipuçları: K1 fırın, K2 mezarlık, K3 telgraf, K4 değirmen.
	var n := 0
	for c in observed_clues:
		if str(c) in ["K1", "K2", "K3", "K4"]:
			n += 1
	return n

func can_end_chapter() -> bool:
	return sent_letter_ids.size() >= 1 and starting_clue_count() >= 2 and not chapter_closed

func _add_outcome_explanations(letter_id: String, result: Dictionary) -> void:
	# C1 can save Hasan without a letter to him: heat drops below 4.
	if letter_id == "C1" and bool(result.get("hasan_survives", false)) and not has_sent_to("H"):
		var note := "Değirmendeki eski gaz lambaları değişince yangın ısısı 5'ten %d'ye indi. Hasan'a mektup gitmese de ısı 4'ün altında kaldığı için Hasan yangından sağ çıktı. Değirmen borcu ise sonraki bölüme taşınır." % int(result.get("heat", 0))
		_add_journal("Neden Hasan kurtuldu?", note)
		timeline_entries.append({"id": "link_C1_hasan", "title": "Dolaylı sonuç", "body": note})
	if str(result.get("fire", "")) == "kontrol altında" and int(result.get("deaths", 0)) > 0:
		var note2 := "Yangın mahallede tutuldu (kontrol altında). Bu şiddette varsayılan kayıp 1 kişidir; bu bir çelişki değil. Komşu nöbeti (H3) veya yangın çanı (N1) kaybı azaltabilir."
		var already := false
		for e in journal_entries:
			if str(e.get("title", "")) == "Kayıp ve yangın şiddeti":
				already = true
				break
		if not already:
			_add_journal("Kayıp ve yangın şiddeti", note2)

func letter_supported_by(letter_id: String) -> String:
	return str(LETTER_CLUE.get(letter_id, ""))

func has_clue_for_letter(letter_id: String) -> bool:
	var cid := letter_supported_by(letter_id)
	if cid == "":
		return true
	return observed_clues.has(cid)

func flavor_reply(letter_id: String) -> String:
	var letter: Dictionary = ChapterDatabase.get_letter(letter_id)
	var base = letter.get("reply", null)
	var lines: PackedStringArray = []
	if base == null or str(base) == "":
		lines.append("Cevap gelmez.")
	else:
		lines.append(str(base))
	var sus := int(letter.get("suspicion", 1))
	if sus >= 2:
		lines.append("Mektup, henüz olmamış bir geceyi biliyor gibi duruyor. 1925'te bu, kuşku uyandırır.")
	elif sus >= 1:
		lines.append("Gönderenin kimliği belirsiz; satırların tam zamanında gelmesi tuhaf kaçtı.")
	if letter_tone == "acil":
		lines.append("Acil üslup onu tedirgin etti; mektubu iki kez okudu.")
	else:
		lines.append("Nazik üslup sayesinde satırları baştan sona okudu.")
	match letter_sign:
		"dost":
			lines.append("Bir dost diye imzalanmıştı.")
		"torun":
			lines.append("Torun diye bir imza, 1925'te saçma duruyor; belki de bu yüzden kuşkuyla bakıldı.")
		_:
			lines.append("İmza yoktu.")
	return "\n".join(lines)

func ending_summary() -> String:
	var original: Dictionary = StoryResolver.resolve([])
	var now: Dictionary = last_result
	var lines: PackedStringArray = []
	lines.append("[b]Kim yaşadı, kim gitti[/b]")
	if bool(now.get("hasan_survives", false)):
		lines.append("Hasan Usta yangından sağ çıktı." + (" (Orijinal zamanda hayatını kaybediyordu.)" if not bool(original.get("hasan_survives", false)) else ""))
	else:
		lines.append("Hasan Usta yangında hayatını kaybetti. Orijinal zaman çizgisi değişmedi.")
	if bool(now.get("feride_stays", false)):
		lines.append("Feride kasabada kaldı." + (" (Orijinalde ayrılıyordu.)" if not bool(original.get("feride_stays", false)) else ""))
	else:
		lines.append("Feride kasabadan ayrıldı.")
	lines.append("")
	lines.append("[b]Ne değişti?[/b]")
	lines.append("Yangın: %s (önce: %s). Kayıp: %d kişi (önce: %d)." % [str(now.get("fire", "")), str(original.get("fire", "")), int(now.get("deaths", 0)), int(original.get("deaths", 0))])
	lines.append("Fırın: %s (önce: %s)." % [str(now.get("bakery", "")), str(original.get("bakery", ""))])
	if bool(now.get("school", false)):
		lines.append("Okul tabelası gelecekte geri geldi. Orijinal zamanda okul hiç açılmıyordu.")
	else:
		lines.append("Okulun izi hâlâ yok.")
	if bool(now.get("archive", false)):
		lines.append("Yangına dair bir kayıt korundu.")
	else:
		lines.append("Yangının kökeni tam ispatlanamadı.")
	if int(now.get("culvert", 0)) > 0:
		lines.append("Menfez tıkandı; 1926 seli ağırlaşabilir.")
	if int(now.get("factory_debt", 0)) > 0:
		lines.append("Değirmen borcu sonraki bölüme taşınır (+%d)." % int(now.factory_debt))
	lines.append("")
	lines.append(StoryResolver.summarize_turkish(now))
	lines.append("")
	lines.append("Başka bir mektup seçsen tarih farklı akar. İstersen baştan dene.")
	return "\n".join(lines)

