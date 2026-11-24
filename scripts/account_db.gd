extends Node
# Dummy "database" untuk testing. Data disimpan di user://accounts_dummy.json
# Ganti isi fungsi-fungsi publik di bawah dengan request ke backend nanti.
# Semua fungsi publik mengembalikan Dictionary: {"ok": bool, "error": String, ...}

const SAVE_PATH := "user://accounts_dummy.json"
const START_COINS := 1020
const USERNAME_MIN := 3
const USERNAME_MAX := 16
const PASSWORD_MIN := 6

# true = tombol Google membuat/masuk ke akun palsu supaya alurnya bisa dites.
# false = tombol Google menampilkan "belum tersedia".
const FAKE_GOOGLE_FOR_TESTING := true
const GOOGLE_TEST_EMAIL := "google.user@gmail.com"

var accounts: Dictionary = {}  # email -> {email, password_hash, username, coins}


func _ready() -> void:
	_load()
	if accounts.is_empty():
		_seed()
		_save()


# ---------- API publik ----------

func register(email: String, password: String) -> Dictionary:
	email = email.strip_edges().to_lower()
	if not _is_valid_email(email):
		return _fail("Please enter a valid email address.")
	if password.length() < PASSWORD_MIN:
		return _fail("Password must be at least %d characters." % PASSWORD_MIN)
	if accounts.has(email):
		return _fail("This email is already registered.")

	accounts[email] = {
		"email": email,
		"password_hash": _hash(email, password),
		"username": "",   # kosong -> Home akan memunculkan popup username
		"coins": START_COINS,
	}
	_save()
	return {"ok": true, "account": accounts[email].duplicate()}


func authenticate(email: String, password: String) -> Dictionary:
	email = email.strip_edges().to_lower()
	var acc: Dictionary = accounts.get(email, {})
	if acc.is_empty() or acc["password_hash"] == "" \
			or acc["password_hash"] != _hash(email, password):
		return _fail("Email or password is wrong.")
	return {"ok": true, "account": acc.duplicate()}


func set_username(email: String, username: String) -> Dictionary:
	username = username.strip_edges()
	if not accounts.has(email):
		return _fail("Account not found. Please log in again.")
	if username.length() < USERNAME_MIN or username.length() > USERNAME_MAX:
		return _fail("Username must be %d-%d characters." % [USERNAME_MIN, USERNAME_MAX])

	var regex := RegEx.new()
	regex.compile("^[A-Za-z0-9_]+$")
	if regex.search(username) == null:
		return _fail("Use only letters, numbers, and underscores.")

	for other_email in accounts:
		if other_email != email \
				and accounts[other_email]["username"].to_lower() == username.to_lower():
			return _fail("That username is already taken.")

	accounts[email]["username"] = username
	_save()
	return {"ok": true, "username": username}


# TODO backend: ganti dengan alur OAuth Google yang asli.
func google_sign_in() -> Dictionary:
	if not FAKE_GOOGLE_FOR_TESTING:
		return _fail("Google sign-in is not available yet.")
	if not accounts.has(GOOGLE_TEST_EMAIL):
		accounts[GOOGLE_TEST_EMAIL] = {
			"email": GOOGLE_TEST_EMAIL,
			"password_hash": "",
			"username": "",
			"coins": START_COINS,
		}
		_save()
	return {"ok": true, "account": accounts[GOOGLE_TEST_EMAIL].duplicate()}


# ---------- Internal ----------

func _fail(message: String) -> Dictionary:
	return {"ok": false, "error": message}


func _is_valid_email(email: String) -> bool:
	return email.contains("@") and email.get_slice("@", 1).contains(".") \
		and not email.begins_with("@") and not email.ends_with(".")


# Hanya untuk testing. Backend asli harus hash di server (bcrypt/argon2).
func _hash(email: String, password: String) -> String:
	return (email + ":" + password).sha256_text()


func _seed() -> void:
	var seeds := [
		["scholar@campus.co.id", "scholar123", "Scholar", 150],
		["test@test.com", "test123", "Tester", 500],
		["newbie@test.com", "newbie123", "", 150],  # username kosong, buat tes popup
	]
	for s in seeds:
		accounts[s[0]] = {
			"email": s[0],
			"password_hash": _hash(s[0], s[1]),
			"username": s[2],
			"coins": s[3],
		}


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Gagal menyimpan akun dummy.")
		return
	file.store_string(JSON.stringify(accounts, "\t"))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		accounts = parsed

func update_profile(email: String, data: Dictionary) -> Dictionary:
	if not accounts.has(email):
		return _fail("Account not found. Please log in again.")
	var profile: Dictionary = accounts[email].get("profile", {})
	for key in ["name", "country", "school", "about"]:
		if data.has(key):
			profile[key] = str(data[key]).strip_edges()
	accounts[email]["profile"] = profile
	_save()
	return {"ok": true, "profile": profile.duplicate()}


func set_avatar(email: String, avatar: Dictionary) -> Dictionary:
	if not accounts.has(email):
		return _fail("Account not found. Please log in again.")
	accounts[email]["avatar"] = avatar.duplicate()
	_save()
	return {"ok": true}

# Simpan koin dan item yang dimiliki setelah pembelian
func save_purchase(email: String, coins: int, owned_items: Array) -> Dictionary:
	if not accounts.has(email):
		return _fail("Account not found. Please log in again.")
	accounts[email]["coins"] = coins
	accounts[email]["owned_items"] = owned_items.duplicate()
	_save()
	return {"ok": true}
