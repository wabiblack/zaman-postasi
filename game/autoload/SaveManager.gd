extends Node
## Minimal JSON save/load under user://

signal saved

const SAVE_PATH := "user://zaman_postasi_b01.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func autosave() -> void:
	save_game()

func save_game() -> void:
	var data := {
		"save_schema": 1,
		"chapter": "B01",
		"sent_letter_ids": GameState.sent_letter_ids.duplicate(),
		"observed_clues": GameState.observed_clues.duplicate(),
		"intro_seen": GameState.intro_seen,
		"help_seen": GameState.help_seen,
		"opening_seen": GameState.opening_seen,
		"letter_tone": GameState.letter_tone,
		"letter_sign": GameState.letter_sign,
		"chapter_closed": GameState.chapter_closed,
		"journal_entries": GameState.journal_entries.duplicate(true),
		"timeline_entries": GameState.timeline_entries.duplicate(true),
	}
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(SAVE_PATH))
	saved.emit()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	GameState.sent_letter_ids = data.get("sent_letter_ids", [])
	GameState.observed_clues = data.get("observed_clues", [])
	GameState.intro_seen = bool(data.get("intro_seen", false))
	GameState.help_seen = bool(data.get("help_seen", false))
	GameState.opening_seen = bool(data.get("opening_seen", false))
	GameState.letter_tone = str(data.get("letter_tone", "nazik"))
	GameState.letter_sign = str(data.get("letter_sign", "isimsiz"))
	GameState.chapter_closed = bool(data.get("chapter_closed", false))
	GameState.journal_entries = data.get("journal_entries", [])
	GameState.timeline_entries = data.get("timeline_entries", [])
	GameState.last_result = StoryResolver.resolve(GameState.sent_letter_ids)
	GameState.state_changed.emit()
	return true

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
