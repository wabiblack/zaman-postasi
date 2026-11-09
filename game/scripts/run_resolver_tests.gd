extends SceneTree
## Headless validation against paket/Bolum1_Durum_Testleri.json (175 states).

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var resolver: Node = root.get_node_or_null("StoryResolver")
	if resolver == null:
		printerr("FAIL: StoryResolver autoload missing")
		quit(1)
		return
	var path := "res://data/Bolum1_Durum_Testleri.json"
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		printerr("FAIL: cannot open tests")
		quit(1)
		return
	var tests = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(tests) != TYPE_ARRAY:
		printerr("FAIL: tests not array")
		quit(1)
		return

	var passed := 0
	var failed := 0
	var first_failures: Array = []
	for t in tests:
		var letters: Array = t.get("letters", [])
		var expected: Dictionary = t.get("outcome", {})
		var full: Dictionary = resolver.call("resolve", letters)
		var got: Dictionary = resolver.call("outcome_only", full)
		if _dicts_equal(expected, got):
			passed += 1
		else:
			failed += 1
			if first_failures.size() < 8:
				first_failures.append({"letters": letters, "expected": expected, "got": got})

	print("RESOLVER_TEST passed=%d failed=%d total=%d" % [passed, failed, tests.size()])
	for ff in first_failures:
		print("FAIL case letters=", ff["letters"])
		print("  expected=", JSON.stringify(ff["expected"]))
		print("  got     =", JSON.stringify(ff["got"]))
	if failed == 0 and passed == tests.size() and tests.size() == 175:
		print("RESOLVER_TEST_OK")
		quit(0)
	else:
		printerr("RESOLVER_TEST_FAIL")
		quit(1)

func _dicts_equal(a: Dictionary, b: Dictionary) -> bool:
	for k in a.keys():
		if not b.has(k):
			return false
		if not _vals_equal(a[k], b[k]):
			return false
	for k in b.keys():
		if not a.has(k):
			return false
	return true

func _vals_equal(a, b) -> bool:
	if (typeof(a) in [TYPE_INT, TYPE_FLOAT]) and (typeof(b) in [TYPE_INT, TYPE_FLOAT]):
		return int(a) == int(b)
	if typeof(a) == TYPE_DICTIONARY and typeof(b) == TYPE_DICTIONARY:
		return _dicts_equal(a, b)
	return a == b
