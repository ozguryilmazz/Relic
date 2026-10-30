extends Node
## Oyun matematiği. Bütün denge sayıları burada; oynadıkça buradan değiştir.

# --- Dalgalar ---
const MAX_WAVE := 100
const PREP_TIME := 10.0            # dalgalar arası hazırlık (sn)
const SPAWN_INTERVAL := 1.0        # aynı dalgada iki düşman arası (sn)
const ENEMY_TRAVEL_TIME := 24.0    # düşmanın yolun tamamını yürüme süresi (sn)

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

# --- Korku ve köleler ---
const FEAR_PER_KILL := 1
const SLAVE_BASE_COST := 10
const SLAVE_COST_STEP := 5
const SLAVE_TAPS_PER_SEC := 0.5    # bir kölenin saniyedeki tıklaması

func wave_scale(wave: int) -> float:
	return pow(1.04, wave - 1)

func enemy_count(wave: int) -> int:
	return 5 + int(wave / 2.0)

func enemy_hp(wave: int) -> float:
	return 20.0 * wave_scale(wave)

func enemy_dps(wave: int) -> float:
	# barikata saniyede verdiği hasar
	return 3.0 * wave_scale(wave)

func slave_cost(owned: int) -> int:
	return SLAVE_BASE_COST + SLAVE_COST_STEP * owned

# --- Kahramanlar ---
# kind: ultinin ne yaptığı (game.gd içinde uygulanır)
const HEROES := [
	{
		"id": "tepegoz",
		"name": "Tepegöz",
		"desc": "Alnının ortasında tek gözü olan, insan etiyle beslenen dev.",
		"color": Color(0.55, 0.42, 0.3),
		"ultis": [
			{"kind": "smash", "name": "Ezici Darbe", "info": "Öndeki düşmanların üstüne atlar, büyük alan hasarı verir.", "cooldown": 45.0, "radius": 260.0, "damage_mult": 2.0},
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
