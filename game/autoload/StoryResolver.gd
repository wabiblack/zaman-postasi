extends Node
## Deterministic Chapter-1 resolver matching paket/Bolum1_Durum_Testleri.json (175 states).

func resolve(letter_ids: Array) -> Dictionary:
	var selected: Array = []
	var ids: Dictionary = {}
	for raw in letter_ids:
		var lid := str(raw)
		var letter: Dictionary = ChapterDatabase.get_letter(lid)
		if letter.is_empty():
			push_error("StoryResolver: unknown letter %s" % lid)
			continue
		selected.append(letter)
		ids[lid] = true

	var heat_sum := 0
	for a in selected:
		heat_sum += int(a.get("heat", 0))
	var heat: int = maxi(0, 5 + heat_sum)

	var reduction := 0
	if ids.has("H3"):
		reduction += 1
	if ids.has("N1"):
		reduction += 2
	var base_deaths := 0
	if heat >= 4:
		base_deaths = 4
	elif heat >= 2:
		base_deaths = 1
	var deaths: int = maxi(0, base_deaths - reduction)

	var hasan_survives: bool = heat < 4 or ids.has("H3")
	var feride_protected: bool = ids.has("F1") or ids.has("F3")
	var feride_leaves: bool = ids.has("F2") or (((ids.has("H1") or (not hasan_survives)) and not feride_protected))
	var feride_stays: bool = not feride_leaves
	var school: bool = feride_stays and (heat <= 1 or (heat <= 3 and feride_protected))

	var bakery := "açık"
	if heat >= 4:
		bakery = "yıkık"
	elif ids.has("H1"):
		bakery = "kapalı"
	elif heat >= 2:
		bakery = "hasarlı"

	var archive: bool = ids.has("N2") or ids.has("C3") or (heat <= 1 and not ids.has("C1"))
	var factory_debt := 0
	for mid in ["F3", "N3", "C1", "C3"]:
		if ids.has(mid):
			factory_debt += 1
	var culvert := 0
	if ids.has("H2"):
		culvert += 1
	if ids.has("C2"):
		culvert += 2
	var bridge_stress := 1 if ids.has("N1") else 0
	var pollution := 1 if ids.has("C2") else 0
	var health_contact := 1 if ids.has("F2") else 0
	var rumor := 0
	for rid in ["H3", "N2", "C3"]:
		if ids.has(rid):
			rumor += 1

	var fire := "büyük yangın"
	if heat <= 1:
		fire = "önlendi"
	elif heat <= 3:
		fire = "kontrol altında"

	# Suspicion is play-state metadata (not in outcome JSON) — still useful for UI
	var suspicion: Dictionary = {}
	for a in selected:
		suspicion[str(a["recipient"])] = int(a.get("suspicion", 1))

	return {
		"heat": heat,
		"fire": fire,
		"deaths": deaths,
		"hasan_survives": hasan_survives,
		"feride_stays": feride_stays,
		"school": school,
		"bakery": bakery,
		"archive": archive,
		"factory_debt": factory_debt,
		"culvert": culvert,
		"bridge_stress": bridge_stress,
		"pollution": pollution,
		"health_contact": health_contact,
		"rumor": rumor,
		# UI helpers (ignored by strict test compare when filtered):
		"suspicion": suspicion,
		"stamps_left": ChapterDatabase.stamp_budget() - selected.size(),
	}

func outcome_only(result: Dictionary) -> Dictionary:
	var keys := ["heat", "fire", "deaths", "hasan_survives", "feride_stays", "school", "bakery", "archive", "factory_debt", "culvert", "bridge_stress", "pollution", "health_contact", "rumor"]
	var out := {}
	for k in keys:
		out[k] = result.get(k)
	return out

func summarize_turkish(result: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append(ChapterDatabase.narrative_for_fire(str(result.get("fire", ""))))
	lines.append("Yangın yoğunluğu: %d · Kayıp: %d" % [int(result.heat), int(result.deaths)])
	lines.append("Fırın: %s" % str(result.get("bakery", "?")))
	if result.get("school", false):
		lines.append("Gelecekte okul tabelası geri döndü.")
	else:
		lines.append("Okulun izi haritada silindi.")
	if str(result.get("fire", "")) == "kontrol altında" and int(result.get("deaths", 0)) > 0:
		lines.append("Kontrol altında olması sıfır kayıp demek değildir: bu şiddette varsayılan kayıp %d kişidir (H3 veya N1 azaltabilir)." % int(result.deaths))
	lines.append("Hasan hayatta: %s" % ("evet" if result.get("hasan_survives", false) else "hayır"))
	lines.append("Feride kasabada: %s" % ("evet" if result.get("feride_stays", false) else "hayır"))
	if int(result.get("culvert", 0)) > 0:
		lines.append("Dere menfezinde biriken kömür sonraki bölümün sel riskini artırır.")
	if result.get("archive", false):
		lines.append("Yangın belgesi / kayıt korundu.")
	else:
		lines.append("Yangının kökeni tam ispatlanamadı.")
	if int(result.get("factory_debt", 0)) > 0:
		lines.append("Değirmen borcu tohumu: +%d" % int(result.factory_debt))
	if int(result.get("rumor", 0)) > 0:
		lines.append("Söylenti: +%d" % int(result.rumor))
	return "\n".join(lines)
