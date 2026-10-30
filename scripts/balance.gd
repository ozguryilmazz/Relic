extends Node
## Oyun matematiği. Bütün denge sayıları burada; oynadıkça buradan değiştir.

# --- Dalgalar ---
const MAX_WAVE := 100
const PREP_TIME := 10.0            # dalgalar arası hazırlık (sn)
const SPAWN_INTERVAL := 1.0        # aynı dalgada iki düşman arası (sn)
const ENEMY_TRAVEL_TIME := 24.0    # düşmanın yolun tamamını yürüme süresi (sn)
const WAVE_LINGER := 20.0          # son asker çıktıktan sonra en fazla bu kadar beklenir, sonra sıradaki dalga hazırlanır
const RANGED_PATIENCE := 12.0      # hedefi olmayan menzilli birlik bu kadar bekler, sonra geri çekilir

# --- Kaynak toplama (tıklama başına) ---
const YIELD := {
	"odun": 1.0,
	"tas": 0.75,
	"kemik": 0.5,
	"cali": 1.0,   # çalı: diken ya da şifa
}
const BUSH_HEAL_CHANCE := 0.40     # çalıdan şifa çıkma ihtimali, kalanı diken
const MAX_FINGERS := 2

# --- Kale (kaynak başına savunma) ---
const START_CASTLE := 100.0
const CASTLE_VALUE := {"odun": 1.0, "tas": 2.0, "kemik": 4.0}

# --- Barikat (kaynak başına can) ---
const BARRICADE_VALUE := {"tas": 5.0, "kemik": 15.0}

# --- Diken ---
const THORN_DAMAGE := 4.0          # bir dikenin hasarı
const THORNS_EATEN_PER_SEC := 2.0  # bölgedeki her düşmanın saniyede tükettiği diken

# --- Şifa ---
const HERB_COOLDOWN_CUT := 1.0     # bir bitki kalan cooldown'dan kaç sn düşer
const HERB_EAT_INTERVAL := 0.08    # basılı tutunca bitki yeme aralığı
const HERB_MAX_CUT := 0.5          # bir bekleme süresinin en fazla bu kadarı şifayla kısaltılabilir

# --- Korku ve köleler ---
const FEAR_PER_KILL := 1
const SLAVE_BASE_COST := 10
const SLAVE_COST_GROWTH := 1.2    # her kölede fiyat %20 artar
const SLAVE_TAPS_PER_SEC := 0.5    # bir kölenin saniyedeki tıklaması

func wave_scale(wave: int) -> float:
	return pow(1.045, wave - 1)

func enemy_count(wave: int) -> int:
	return 5 + int(wave / 2.0)

func enemy_hp(wave: int) -> float:
	return 20.0 * wave_scale(wave)

func enemy_dps(wave: int) -> float:
	# barikata saniyede verdiği hasar
	return 3.0 * wave_scale(wave)

# --- Kahraman vuruşu (düşmana dokununca) ---
const HERO_STRIKE := 4.0           # bir dokunuşun temel hasarı
const STRIKE_SCALE_POW := 0.6      # vuruş dalgayla düşmanlardan yavaş güçlenir (wave_scale ^ 0.6)
const STRIKE_RADIUS := 55.0        # düşmanın etrafında dokunuşun sayıldığı alan

# --- Kombo ---
const COMBO_WINDOW := 0.7          # iki dokunuş arası en fazla bu kadar olursa kombo sürer (sn)
const COMBO_STEP := 20             # her 20 dokunuşta çarpan +1
const COMBO_MAX_MULT := 3          # en yüksek çarpan (relikle artar)

# --- Altın kaynak ---
const GOLDEN_EVERY := Vector2(15.0, 25.0)   # iki altın kaynak arası (sn, rastgele)
const GOLDEN_DURATION := 5.0
const GOLDEN_MULT := 10.0

# --- Boss ---
const BOSS_EVERY := 10
const BOSS_HP_MULT := 25.0         # sopalı askerin kaç katı can
const BOSS_MELEE_MULT := 6.0

# --- Relikler ---
# rarity: "common" her dalga sonu, "legend" boss yenilince. max: kaç kez alınabilir.
const RELICS := {
	"diken_hasar":  {"name": "Zehirli Dikenler", "desc": "Diken hasarı +%25", "max": 5, "rarity": "common"},
	"diken_hiz":    {"name": "Sivri Dikenler", "desc": "Düşmanlar saniyede +1 diken daha yer", "max": 3, "rarity": "common"},
	"cali_verim":   {"name": "Bereketli Çalılar", "desc": "Çalı başına +1 diken/şifa", "max": 3, "rarity": "common"},
	"odun_verim":   {"name": "Keskin Balta", "desc": "Odun başına +1", "max": 3, "rarity": "common"},
	"tas_verim":    {"name": "Demir Kazma", "desc": "Taş başına +0,5", "max": 3, "rarity": "common"},
	"kemik_verim":  {"name": "Kemik Avcısı", "desc": "Kemik başına +0,5", "max": 3, "rarity": "common"},
	"kale_deger":   {"name": "Usta Duvarcı", "desc": "Kaleye eklenen kaynaklar +%50 savunma", "max": 4, "rarity": "common"},
	"barikat_deger": {"name": "Sağlam Temel", "desc": "Barikata eklenen kaynaklar +%50 can", "max": 4, "rarity": "common"},
	"barikat_diken": {"name": "Dikenli Barikat", "desc": "Barikata vuranlar verdikleri hasarın %50'sini alır", "max": 3, "rarity": "common"},
	"kole_hiz":     {"name": "Kırbaç", "desc": "Köleler %25 daha hızlı toplar", "max": 3, "rarity": "common"},
	"kole_ucuz":    {"name": "Esir Pazarı", "desc": "Köle fiyatı -%25", "max": 2, "rarity": "common"},
	"korku":        {"name": "Dehşet Saçan", "desc": "Öldürmelerden +%50 korku", "max": 3, "rarity": "common"},
	"ulti_cd":      {"name": "Kadim Ruh", "desc": "Ulti bekleme süreleri -%15", "max": 3, "rarity": "common"},
	"vurus":        {"name": "Keskin Pençe", "desc": "Kahraman vuruşu +%25", "max": 5, "rarity": "common"},
	"kombo":        {"name": "Savaş Davulu", "desc": "En yüksek kombo çarpanı +1", "max": 3, "rarity": "common"},
	"altin":        {"name": "Altın Göz", "desc": "Altın kaynaklar daha sık çıkar", "max": 2, "rarity": "common"},
	"les":          {"name": "Leş Yiyici", "desc": "Her öldürmede %25 ihtimalle 1 şifa", "max": 3, "rarity": "common"},
	"kurt":         {"name": "Kurt Sürüsü", "desc": "Her 5 dalgada 1 bedava köle", "max": 1, "rarity": "common"},
	# efsanevi
	"kizil_elma":   {"name": "Kızıl Elma", "desc": "Tüm kaynak toplama +1", "max": 1, "rarity": "legend"},
	"ergenekon":    {"name": "Ergenekon", "desc": "Kale savunması anında 2 katına çıkar", "max": 1, "rarity": "legend"},
	"bozkurt":      {"name": "Bozkurt", "desc": "Ulti bekleme süreleri yarıya iner", "max": 1, "rarity": "legend"},
	"tengri":       {"name": "Tengri'nin Gazabı", "desc": "Kahraman vuruşu 2 katı, yakındakilere de vurur", "max": 1, "rarity": "legend"},
	"umay":         {"name": "Umay'ın Kalkanı", "desc": "Kaleye gelen hasar -%35", "max": 1, "rarity": "legend"},
	"ak_ana":       {"name": "Ak Ana", "desc": "+5 köle, köleler %50 daha hızlı", "max": 1, "rarity": "legend"},
}

func relic_choices(owned: Dictionary, rarity: String, count: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = []
	for id in RELICS:
		var r: Dictionary = RELICS[id]
		if r.rarity == rarity and int(owned.get(id, 0)) < int(r.max):
			pool.append(id)
	# karıştır
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	return pool.slice(0, mini(count, pool.size()))

# --- Düşman tipleri ---
# hp/speed/melee: temel değerin çarpanı. fear: öldürünce verdiği korku.
# ranged: menzilli tipler diken bölgesinin "stand" piksel önünde durur ve ateş eder.
#   target: "barricade" (barikat yoksa yürür), "barricade_castle" (barikat yoksa kaleye),
#   "castle" (doğrudan kale).
#   after: cephane bitince / hedef kalmayınca ne yapar: "retreat" geri çekilir (dikenlere hiç girmez),
#   "advance" yürüyerek ilerler (dikenlerden geçer, barikata saldırır).
#   shot: bir atışın hasarı = shot × 3 × wave_scale
const ENEMY_TYPES := {
	"koylu":   {"name": "Köylüler", "hp": 0.8, "speed": 1.0, "melee": 0.8, "fear": 1},
	"sopali":  {"name": "Sopalı askerler", "hp": 1.0, "speed": 1.0, "melee": 1.0, "fear": 1},
	"okcu":    {"name": "Okçular", "hp": 0.6, "speed": 1.0, "melee": 0.5, "fear": 1,
		"ranged": {"target": "barricade", "stand": 110.0, "ammo": 8, "interval": 1.2, "shot": 1.0, "proj": "arrow", "after": "retreat"}},
	"atli":    {"name": "Atlılar", "hp": 1.5, "speed": 1.8, "melee": 1.5, "fear": 2},
	"topcu":   {"name": "Topçular", "hp": 1.2, "speed": 0.8, "melee": 0.5, "fear": 2,
		"ranged": {"target": "barricade_castle", "stand": 230.0, "ammo": 4, "interval": 2.5, "shot": 5.0, "proj": "ball", "after": "advance"}},
	"araba":   {"name": "Atlı arabalar", "hp": 4.0, "speed": 0.7, "melee": 3.0, "fear": 3, "drops": 2},
	"mancinik": {"name": "Mancınıklar", "hp": 3.0, "speed": 0.5, "melee": 1.0, "fear": 5,
		"ranged": {"target": "castle", "stand": 480.0, "ammo": 3, "interval": 4.0, "shot": 15.0, "proj": "rock", "after": "retreat"}},
	"boss":    {"name": "Dev Bahadır", "hp": BOSS_HP_MULT, "speed": 0.55, "melee": BOSS_MELEE_MULT, "fear": 25, "boss": true},
}

## Dalganın tip karışımı: [[tip, ağırlık], ...]
func wave_mix(wave: int) -> Array:
	if wave <= 5:
		return [["koylu", 1.0]]
	if wave <= 10:
		return [["sopali", 1.0]]
	if wave <= 15:
		return [["sopali", 0.7], ["okcu", 0.3]]
	if wave <= 25:
		return [["sopali", 0.5], ["okcu", 0.25], ["atli", 0.25]]
	if wave <= 30:
		return [["sopali", 0.4], ["okcu", 0.2], ["atli", 0.25], ["topcu", 0.15]]
	if wave <= 35:
		return [["sopali", 0.3], ["okcu", 0.2], ["atli", 0.2], ["topcu", 0.15], ["araba", 0.15]]
	return [["sopali", 0.25], ["okcu", 0.2], ["atli", 0.2], ["topcu", 0.12], ["araba", 0.13], ["mancinik", 0.1]]

## Dalganın asker listesi (karışık sırada). Yeni tipin ilk dalgasında en az 1 tane olur.
func wave_roster(wave: int, rng: RandomNumberGenerator) -> Array:
	var count := enemy_count(wave)
	var mix := wave_mix(wave)
	var out: Array = []
	for pair in mix:
		var n := int(round(count * float(pair[1])))
		if n == 0:
			n = 1
		for i in n:
			out.append(pair[0])
	# sayıyı tam tut
	while out.size() > count:
		out.remove_at(out.find(mix[0][0]))
	while out.size() < count:
		out.append(mix[0][0])
	# karıştır (rng ile, tekrar edilebilir olsun)
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	# boss dalgası: boss en son çıkar (liste sondan tüketiliyor)
	if wave % BOSS_EVERY == 0:
		out.insert(0, "boss")
	return out

## Bu dalgada ilk kez görülen tipler
func new_types(wave: int) -> Array:
	if wave <= 1:
		return []
	var prev := {}
	for pair in wave_mix(wave - 1):
		prev[pair[0]] = true
	var out: Array = []
	for pair in wave_mix(wave):
		if not prev.has(pair[0]):
			out.append(pair[0])
	return out

func slave_cost(owned: int) -> int:
	return int(round(SLAVE_BASE_COST * pow(SLAVE_COST_GROWTH, owned)))

# --- Kahramanlar ---
# kind: ultinin ne yaptığı (game.gd içinde uygulanır)
const HEROES := [
	{
		"id": "tepegoz",
		"name": "Tepegöz",
		"desc": "Alnının ortasında tek gözü olan, insan etiyle beslenen dev.",
		"color": Color(0.55, 0.42, 0.3),
		"ultis": [
			{"kind": "smash", "name": "Ezici Darbe", "info": "Öndeki düşmanların üstüne atlar, büyük alan hasarı verir.", "cooldown": 45.0, "radius": 220.0, "damage_mult": 1.2},
			{"kind": "gather", "name": "Açlık", "info": "7 sn boyunca kaynak toplama 2 katı.", "cooldown": 45.0, "duration": 7.0, "mult": 2.0},
		],
	},
	{
		"id": "sahmeran",
		"name": "Şahmeran",
		"desc": "Belden yukarısı kadın, aşağısı yılan. Yılanların kraliçesi, şifanın kaynağı.",
		"color": Color(0.3, 0.6, 0.35),
		"ultis": [
			{"kind": "poison", "name": "Zehir", "info": "7 sn boyunca dikenlerin zehir gücü 2 katı.", "cooldown": 60.0, "duration": 7.0, "mult": 2.0},
			{"kind": "heal", "name": "Şifa", "info": "3 sn boyunca kale, barikat ve dikenleri iyileştirir.", "cooldown": 60.0, "duration": 3.0, "castle_per_sec": 10.0, "barricade_per_sec": 10.0, "thorns_per_sec": 5.0},
		],
	},
	{
		"id": "alkarasi",
		"name": "Alkarası",
		"desc": "Lohusaları ve yeni doğanları kollayan, korku salan karanlık ruh.",
		"color": Color(0.45, 0.3, 0.55),
		"ultis": [
			{"kind": "slow", "name": "Kâbus", "info": "5 sn boyunca düşmanların hareket hızı %50 düşer.", "cooldown": 60.0, "duration": 5.0, "mult": 0.5},
			{"kind": "fear", "name": "Dehşet", "info": "Düşmanların %20'si geldikleri yöne kaçar.", "cooldown": 60.0, "ratio": 0.2},
		],
	},
]
