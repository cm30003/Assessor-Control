extends Node

enum Bus{
	MASTER,
	BGM,
	SFX,
}
const Music_BUS="BGM"
const SFX_BUS="SFX"

##音乐播放器配置
##音乐播放器的个数
var music_audio_player_count:int = 2
##当前播放音乐的播放器的序号，默认为0
var current_music_player_index:int=0
##音乐播放器存放的数组，方便调用
var music_players:Array[AudioStreamPlayer]
##音效播放器的个数
var sfx_audio_player_count:int = 6
##音效播放器存放的数组，方便调用
var sfx_players:Array[AudioStreamPlayer]

func _ready() -> void:
	_ensure_buses_exist()
	init_music_audio_manager()
	init_sfx_audio_manager()

##确保音频总线存在（Master / BGM / SFX）
func _ensure_buses_exist()->void:
	if AudioServer.get_bus_index(Music_BUS)==-1:
		AudioServer.add_bus()
		var idx:=AudioServer.bus_count-1
		AudioServer.set_bus_name(idx,Music_BUS)
		AudioServer.set_bus_volume_db(idx,linear_to_db(0.5))
	if AudioServer.get_bus_index(SFX_BUS)==-1:
		AudioServer.add_bus()
		var idx:=AudioServer.bus_count-1
		AudioServer.set_bus_name(idx,SFX_BUS)
		AudioServer.set_bus_volume_db(idx,linear_to_db(0.5))

##初始化音乐播放器
func init_music_audio_manager() ->void:
	print("声音管理器：实例化完毕")
	for i in music_audio_player_count:
		var audio_player:=AudioStreamPlayer.new()
		audio_player.process_mode=Node.PROCESS_MODE_ALWAYS
		audio_player.bus=Music_BUS
		add_child(audio_player)
		music_players.append(audio_player)

##播放指定音乐
func play_music(_audio:AudioStream)->void:
	var current_audio_player:=music_players[current_music_player_index]
	if current_audio_player.stream==_audio:
		return
	var empty_audio_player_index= 0 if current_music_player_index== 1 else 0
	var empty_audio_player:=music_players[empty_audio_player_index]
	current_audio_player.stop()
	current_audio_player.stream=null
	empty_audio_player.stream=_audio
	empty_audio_player.play()
	current_music_player_index=empty_audio_player_index

##初始化音效播放器
func init_sfx_audio_manager() ->void:
	print("音效管理器：实例化完毕")
	for i in sfx_audio_player_count:
		var audio_player:=AudioStreamPlayer.new()
		audio_player.bus=SFX_BUS
		add_child(audio_player)
		sfx_players.append(audio_player)

##播放制定音效
func play_sfx(_audio:AudioStream)->void:
	for i in sfx_audio_player_count:
		var sfx_audio_player:=sfx_players[i]
		if not sfx_audio_player.playing:
			sfx_audio_player.stream=_audio
			sfx_audio_player.play()
			break
##设定/修改音量
func set_volume(bus_index:Bus,v:float)->void:
	var db=linear_to_db(v)
	AudioServer.set_bus_volume_db(bus_index,db)
