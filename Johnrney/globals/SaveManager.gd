extends Node

# Caminho para o arquivo que armazenará as configurações do usuário
var settings_path := "user://user_settings.cfg"
# Caminho para o arquivo que armazenará o progresso do jogador
var progress_path := "user://user_progress.cfg"

# Dicionário que mantém as configurações do jogo na memória com valores padrão
var settings = {
	"music_on": true,          # Música ligada ou desligada
	"music_volume": 1.0,       # Volume da música (0.0 a 1.0)
	"sfx_volume": 1.0,         # Volume dos efeitos sonoros (SFX)
	"master_volume": 1.0,      # Volume geral do áudio
	"resolution": "1280x720"   # Resolução da tela
}

# Dicionário que mantém o progresso do jogador (pontuações e erros)
var progress = {
	"scores": {   # Acertos totais por operação
		"add": 0,
		"sub": 0,
		"mul": 0,
		"div": 0,
		"all": 0
	},
	"errors": {   # Erros totais por operação
		"add": 0,
		"sub": 0,
		"mul": 0,
		"div": 0,
		"all": 0
	},
	"high_scores": []  # Lista dos 5 melhores jogos. Cada item é um dicionário com detalhes do jogo
}

func _ready():
	# Carrega as configurações salvas
	load_settings()
	# Aplica as configurações de áudio carregadas
	apply_audio_settings()
	# Carrega o progresso salvo
	load_progress()

	# Exibe no console os caminhos dos arquivos para debug
	print("============================================")
	print("🗂️ Caminho dos arquivos de configuração:")
	print("- Configurações:", ProjectSettings.globalize_path(settings_path))
	print("- Progresso:", ProjectSettings.globalize_path(progress_path))
	print("============================================")

	# Se existir um node do tipo Label chamado "path_label", atualiza seu texto com os caminhos
	var label = get_node_or_null("path_label")
	if label:
		label.text = "Settings path:\n" + ProjectSettings.globalize_path(settings_path) + "\n\n" + \
		"Progress path:\n" + ProjectSettings.globalize_path(progress_path)

# ============================================ #
# ================= SETTINGS ================= #
# ============================================ #

# Função para carregar as configurações do arquivo .cfg para o dicionário settings
func load_settings():
	var cfg = ConfigFile.new()
	var err = cfg.load(settings_path)  # Tenta carregar o arquivo
	if err == OK:
		# Se o arquivo existe, lê os valores e atualiza o dicionário
		settings["music_on"] = cfg.get_value("audio", "music_on", true)       # CORRIGIDO: usar [] para acessar dicionário
		settings["music_volume"] = cfg.get_value("audio", "music_volume", 1.0)
		settings["sfx_volume"] = cfg.get_value("audio", "sfx_volume", 1.0)
		settings["master_volume"] = cfg.get_value("audio", "master_volume", 1.0)
		settings["resolution"] = cfg.get_value("display", "resolution", "1280x720")
		print("✅ Configurações carregadas com sucesso.")
	else:
		# Se o arquivo não existir, cria um novo com valores padrão
		print("⚠️ Arquivo de configurações não encontrado. Criando novo com valores padrão.")
		save_settings()

# Função para salvar as configurações do dicionário settings no arquivo .cfg
func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "music_on", settings["music_on"])                  # CORRIGIDO: usar [] para acessar dicionário
	cfg.set_value("audio", "music_volume", settings["music_volume"])
	cfg.set_value("audio", "sfx_volume", settings["sfx_volume"])              # Salva volume dos efeitos sonoros
	cfg.set_value("audio", "master_volume", settings["master_volume"])        # Salva volume master
	cfg.set_value("display", "resolution", settings["resolution"])
	
	var err = cfg.save(settings_path)  # Tenta salvar o arquivo
	if err == OK:
		print("💾 Configurações salvas com sucesso em:", ProjectSettings.globalize_path(settings_path))
	else:
		print("❌ Erro ao salvar configurações:", err)

# ============================================ #
# ================= PROGRESS ================= #
# ============================================ #

# Função para carregar o progresso salvo do jogador
func load_progress():
	var cfg = ConfigFile.new()
	var err = cfg.load(progress_path)
	if err == OK:
		for mode in progress["scores"].keys():
			progress["scores"][mode] = int(cfg.get_value("scores", mode, 0))   # CORRIGIDO: usar [] para acessar dicionário
			progress["errors"][mode] = int(cfg.get_value("errors", mode, 0))
		# Carrega o top 5
		progress["high_scores"] = cfg.get_value("high_scores", "list", [])
		print("✅ Progresso carregado com sucesso.")
	else:
		print("⚠️ Arquivo de progresso não encontrado. Criando novo com valores padrão.")
		save_progress()

func save_progress():
	var cfg = ConfigFile.new()
	for mode in progress["scores"].keys():                                        # CORRIGIDO: usar [] para acessar dicionário
		cfg.set_value("scores", mode, progress["scores"][mode])
		cfg.set_value("errors", mode, progress["errors"][mode])
	cfg.set_value("high_scores", "list", progress["high_scores"])
	
	var err = cfg.save(progress_path)
	if err == OK:
		print("💾 Progresso salvo com sucesso.")
	else:
		print("❌ Erro ao salvar progresso:", err)

# ============================================ #
# ========== MÉTODOS DE ATUALIZAÇÃO ========== #
# ============================================ #

# Adiciona uma pontuação para um modo específico e salva o progresso
func add_score(mode: String, amount: int = 1):
	if progress["scores"].has(mode):
		progress["scores"][mode] += amount
		print("➕ Pontuação adicionada em ", mode, " Novo valor: ", progress["scores"][mode])
		save_progress()
	else:
		print("❌ Modo de pontuação inválido:", mode)

# Adiciona um erro ao contador e salva o progresso
func add_error(mode: String):
	if progress["errors"].has(mode):
		progress["errors"][mode] += 1
		print("❌ Erro adicionado no modo ", mode, " Total: ", progress["errors"][mode])
		save_progress()
	else:
		print("❌ Modo inválido para erro:", mode)

func add_high_score(score: int, errors: int, mode: String):
	if score <= 0:
		print("⚠️ High score não registrado porque score é 0.")
		return

	var dt = Time.get_datetime_dict_from_system(false)
	var formatted_date = "%04d-%02d-%02d %02d:%02d:%02d" % [
		dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second
	]

	var game_data = {
		"score": score,
		"errors": errors,
		"mode": mode,
		"timestamp": formatted_date
	}

	progress["high_scores"].append(game_data)   # CORRIGIDO: usar [] para acessar dicionário

	# Filtra só os registros desse modo
	var filtered: Array = progress["high_scores"].filter(func(r): return r["mode"] == mode)

	# Ordena:
	# 1. Maior score
	# 2. Menor erro
	# 3. Mais recente
	filtered.sort_custom(func(a, b):
		if a["score"] != b["score"]:
			return b["score"] - a["score"]
		if a["errors"] != b["errors"]:
			return a["errors"] - b["errors"]
		var time_a = Time.get_unix_time_from_datetime_string(a.get("timestamp", "1970-01-01 00:00:00"))
		var time_b = Time.get_unix_time_from_datetime_string(b.get("timestamp", "1970-01-01 00:00:00"))
		return int(time_b - time_a)  # Mais recente primeiro
	)

	# Mantém só os 5 melhores desse modo
	if filtered.size() > 5:
		filtered.resize(5)

	# Remove todos os registros desse modo do high_scores atual
	progress["high_scores"] = progress["high_scores"].filter(func(r): return r["mode"] != mode)

	# Junta os registros desse modo (filtrados) com os dos outros modos
	progress["high_scores"] += filtered

	save_progress()
	print("🏆 Novo high score registrado:", game_data)

# ============================================ #
# ============ APLICAR CONFIGURAÇÕES ========= #
# ============================================ #

# Aplica os volumes configurados às respectivas buses de áudio do Godot
func apply_audio_settings():
	# Ajusta volume e mute da bus "Master"
	var master_index = AudioServer.get_bus_index("Master")
	if master_index != -1:
		AudioServer.set_bus_volume_db(master_index, linear_to_db(settings["master_volume"]))  # CORRIGIDO: usar [] para acessar dicionário
		AudioServer.set_bus_mute(master_index, settings["master_volume"] <= 0.01)
		print("🔊 Volume Master aplicado:", settings["master_volume"])
	else:
		print("❌ Bus 'Master' não encontrado!")

	# Ajusta volume e mute da bus "music"
	var music_index = AudioServer.get_bus_index("music")
	if music_index != -1:
		AudioServer.set_bus_volume_db(music_index, linear_to_db(settings["music_volume"]))
		AudioServer.set_bus_mute(music_index, settings["music_volume"] <= 0.01)
		print("🎶 Volume music aplicado:", settings["music_volume"])
	else:
		print("❌ Bus 'music' não encontrado!")

	# Ajusta volume e mute da bus "sfx"
	var sfx_index = AudioServer.get_bus_index("sfx")
	if sfx_index != -1:
		AudioServer.set_bus_volume_db(sfx_index, linear_to_db(settings["sfx_volume"]))
		AudioServer.set_bus_mute(sfx_index, settings["sfx_volume"] <= 0.01)
		print("🔊 Volume sfx aplicado:", settings["sfx_volume"])
	else:
		print("❌ Bus 'sfx' não encontrado!")

func get_best_score_for_mode(mode: String) -> int:
	var best_score = 0
	for record in progress["high_scores"]:
		if record.has("mode") and record["mode"] == mode:
			if record.has("score") and record["score"] > best_score:
				best_score = record["score"]
	return best_score
	
func parse_date_to_timestamp(date_str: String) -> int:
	# Tenta reconhecer os dois formatos e converter para unix timestamp
	if date_str.find("/") != -1:
		# Formato DD/MM/YYYY HH:MM:SS
		var parts = date_str.split(" ")
		if parts.size() < 2:
			return 0
		var date_parts = parts[0].split("/")
		var time_parts = parts[1].split(":")
		if date_parts.size() != 3 or time_parts.size() != 3:
			return 0
		var day = int(date_parts[0])
		var month = int(date_parts[1])
		var year = int(date_parts[2])
		var hour = int(time_parts[0])
		var minute = int(time_parts[1])
		var second = int(time_parts[2])
		var formatted = "%04d-%02d-%02d %02d:%02d:%02d" % [year, month, day, hour, minute, second]
		return Time.get_unix_time_from_datetime_string(formatted)
	else:
		# Formato esperado YYYY-MM-DD HH:MM:SS
		return Time.get_unix_time_from_datetime_string(date_str)


func get_top_scores_for_mode(mode: String) -> Array:
	var top_scores := []
	for record in progress["high_scores"]:
		if record.get("mode", "") == mode:
			top_scores.append(record)
	top_scores.sort_custom(func(a, b):
		if a["score"] != b["score"]:
			return 1 if b["score"] > a["score"] else -1
		if a["errors"] != b["errors"]:
			return -1 if a["errors"] < b["errors"] else 1
		var time_a = parse_date_to_timestamp(a.get("timestamp", "1970-01-01 00:00:00"))
		var time_b = parse_date_to_timestamp(b.get("timestamp", "1970-01-01 00:00:00"))
		return 1 if time_b > time_a else -1
)

	if top_scores.size() > 5:
		top_scores.resize(5)

	# PRINT dos maiores acertos na ordem
	print("🏅 Top scores para o modo: ", mode)
	for i in range(top_scores.size()):
		var r = top_scores[i]
		print("%dº Lugar - Score: %d, Erros: %d, Data: %s" % [i+1, r["score"], r["errors"], r["timestamp"]])

	return top_scores



func clear_high_scores():
	progress["high_scores"] = []
	
	# Zera os scores e erros de todos os modos
	for mode in progress["scores"].keys():
		progress["scores"][mode] = 0
		progress["errors"][mode] = 0
	
	save_progress()
	print("🗑️ Todos os recordes, acertos e erros foram apagados.")
