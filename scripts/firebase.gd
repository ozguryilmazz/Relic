extends Node
## Firebase Realtime Database (REST): sürüm kontrolü ve skor tablosu.
## Godot için resmi SDK olmadığından HTTP istekleriyle çalışır.

signal update_available(version_name: String, url: String)

const API_KEY := "AIzaSyBmmnbSNvK2vwCvivtHG2OwsGPZemfT0GE"
const DB_URL := "https://relic-502f6-default-rtdb.europe-west1.firebasedatabase.app"
const RELEASES_URL := "https://github.com/ozguryilmazz/relic/releases/latest"
const SAVE_PATH := "user://player.cfg"

var id_token := ""
var refresh_token := ""
var uid := ""
var token_expiry := 0.0
var player_name := ""
var update_info := {}   # yeni sürüm varsa {name, url}

func _ready() -> void:
	_load()
	check_update()

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		refresh_token = cfg.get_value("auth", "refresh_token", "")
		uid = cfg.get_value("auth", "uid", "")
		player_name = cfg.get_value("player", "name", "")

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("auth", "refresh_token", refresh_token)
	cfg.set_value("auth", "uid", uid)
	cfg.set_value("player", "name", player_name)
	cfg.save(SAVE_PATH)

## Basit HTTP yardımcısı: {ok, code, data}
func _request(url: String, method := HTTPClient.METHOD_GET, body := "", headers := PackedStringArray(["Content-Type: application/json"])) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	var err := http.request(url, headers, method, body)
	if err != OK:
		http.queue_free()
		return {"ok": false, "code": 0, "data": null}
	var r: Array = await http.request_completed
	http.queue_free()
	var code: int = r[1]
	var text: String = (r[3] as PackedByteArray).get_string_from_utf8()
	var data = JSON.parse_string(text) if not text.is_empty() else null
	return {"ok": r[0] == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300, "code": code, "data": data}

# ---------------------------------------------------------------- sürüm

func check_update() -> void:
	if AppVersion.CODE <= 0:
		return
	var r := await _request(DB_URL + "/config/latest.json")
	if not r.ok or not (r.data is Dictionary):
		return
	var latest := int(r.data.get("code", 0))
	if latest > AppVersion.CODE:
		update_info = {"name": str(r.data.get("name", "")), "url": str(r.data.get("url", RELEASES_URL))}
		update_available.emit(update_info.name, update_info.url)

# ---------------------------------------------------------------- giriş

func _ensure_auth() -> bool:
	var now := Time.get_unix_time_from_system()
	if id_token != "" and now < token_expiry - 60.0:
		return true
	if refresh_token != "":
		var body := "grant_type=refresh_token&refresh_token=" + refresh_token.uri_encode()
		var r := await _request("https://securetoken.googleapis.com/v1/token?key=" + API_KEY, HTTPClient.METHOD_POST, body, PackedStringArray(["Content-Type: application/x-www-form-urlencoded"]))
		if r.ok and r.data is Dictionary:
			id_token = r.data.get("id_token", "")
			refresh_token = r.data.get("refresh_token", refresh_token)
			uid = r.data.get("user_id", uid)
			token_expiry = now + float(r.data.get("expires_in", "3600"))
			_save()
			return id_token != ""
	var r2 := await _request("https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KEY, HTTPClient.METHOD_POST, JSON.stringify({"returnSecureToken": true}))
	if r2.ok and r2.data is Dictionary:
		id_token = r2.data.get("idToken", "")
		refresh_token = r2.data.get("refreshToken", "")
		uid = r2.data.get("localId", "")
		token_expiry = now + float(r2.data.get("expiresIn", "3600"))
		_save()
		return id_token != ""
	return false

# ---------------------------------------------------------------- skorlar

static func score_of(stats: Dictionary) -> int:
	# önce dalga, eşitlikte öldürme sayısı
	return int(stats.waves) * 100000 + mini(int(stats.kills), 99999)

func submit_score(nm: String, stats: Dictionary) -> bool:
	player_name = nm
	_save()
	if not await _ensure_auth():
		return false
	var entry := {
		"name": nm,
		"uid": uid,
		"hero": stats.hero,
		"waves": stats.waves,
		"seconds": stats.seconds,
		"kills": stats.kills,
		"slaves": stats.slaves,
		"score": score_of(stats),
		"version": AppVersion.NAME,
		"at": {".sv": "timestamp"},
	}
	var r := await _request(DB_URL + "/scores.json?auth=" + id_token, HTTPClient.METHOD_POST, JSON.stringify(entry))
	return r.ok

func fetch_scores(limit := 20) -> Array:
	var url := DB_URL + "/scores.json?orderBy=%22score%22&limitToLast=" + str(limit)
	var r := await _request(url)
	var out: Array = []
	if r.ok and r.data is Dictionary:
		for k in r.data:
			out.append(r.data[k])
		out.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	return out
