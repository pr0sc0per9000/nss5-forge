' TBall.SetUp  (KIND=Function -- static, no Self)
' VA 0x004C78C0   1074 bytes   sig ()i
' byte-identical vs NSS5.exe (1074/1074, original length from Ghidra's inventory, mode=reloc)
' w16_S2. GLOBAL NAMES: g_img_ball/g_img_ballshadow are the established names from
' TBall.RenderReplay; g_ball_channel/g_ball_sound are the established names from
' TBall.CheckAdHoardings (0x00C5A510/0x00C5A51C). g_img_ballmarker, g_img_tenyards,
' g_ball_soundbounce, g_ball_soundkick are OURS (first body to touch those addresses).
' g_ball_float01..16 and g_ball_int02 are the established globals_final.tsv names.
'
' Loads the four ball sprites/markers, reads 16 physics constants from Engine.ini via
' ReadSettingFloat, then lazily allocates an audio channel and three ball SFX -- each
' guarded by `If Not g_x Then g_x = ...` so a second call (e.g. re-entering a match) does
' not reload. `If Not g` / assign-to-Global is the codegen that matches: an intermediate
' Local here costs 6 bytes per guard (extra reload of the Global for the null test) and the
' wrong inc/copy order costs another 3 bytes per guard (codegen-patterns 10.3).
'!Global g_img_ball:TImage
'!Global g_img_ballshadow:TImage
'!Global g_img_ballmarker:TImage
'!Global g_img_tenyards:TImage
'!Global g_ball_int02:Int
'!Global g_ball_float01:Float
'!Global g_ball_float02:Float
'!Global g_ball_float03:Float
'!Global g_ball_float04:Float
'!Global g_ball_float05:Float
'!Global g_ball_float06:Float
'!Global g_ball_float07:Float
'!Global g_ball_float08:Float
'!Global g_ball_float09:Float
'!Global g_ball_float10:Float
'!Global g_ball_float11:Float
'!Global g_ball_float12:Float
'!Global g_ball_float13:Float
'!Global g_ball_float14:Float
'!Global g_ball_float15:Float
'!Global g_ball_float16:Float
'!Global g_ball_channel:TChannel
'!Global g_ball_soundbounce:TSound
'!Global g_ball_soundkick:TSound
'!Global g_ball_sound:TSound
g_img_ball = LoadAnimImageChecked("EngineMedia/Match/Ball/Ball.png", 20, 20, 0, 12, -1)
SetImageHandle(g_img_ball, 10.0, 17.0)
g_img_ballshadow = LoadImageChecked("EngineMedia/Match/Ball/Shadow.png", -1)
SetImageHandle(g_img_ballshadow, 10.0, 5.0)
g_img_ballmarker = LoadImageChecked("EngineMedia/Match/Ball/Marker.png", -1)
MidHandleImage(g_img_ballmarker)
g_img_tenyards = LoadImageChecked("EngineMedia/Match/Ball/TenYards.png", -1)
MidHandleImage(g_img_tenyards)
g_ball_int02 = Int(ReadSettingFloat("incbin::Inc/Engine.ini", "ballradius", 0, 100.0))
g_ball_float01 = ReadSettingFloat("incbin::Inc/Engine.ini", "fricGrass", 0, 100.0)
g_ball_float02 = ReadSettingFloat("incbin::Inc/Engine.ini", "fricAir", 0, 100.0)
g_ball_float03 = ReadSettingFloat("incbin::Inc/Engine.ini", "gravity", 0, 100.0)
g_ball_float04 = ReadSettingFloat("incbin::Inc/Engine.ini", "bounce", 0, 100.0)
g_ball_float05 = ReadSettingFloat("incbin::Inc/Engine.ini", "passcheckradius", 0, 10.0)
g_ball_float06 = ReadSettingFloat("incbin::Inc/Engine.ini", "kickpow_pass", 0, 1000.0)
g_ball_float07 = ReadSettingFloat("incbin::Inc/Engine.ini", "kickheight_pass", 0, 1000.0)
g_ball_float08 = ReadSettingFloat("incbin::Inc/Engine.ini", "kickpow_shoot", 0, 1000.0)
g_ball_float09 = ReadSettingFloat("incbin::Inc/Engine.ini", "kickheight_shoot", 0, 1000.0)
g_ball_float10 = ReadSettingFloat("incbin::Inc/Engine.ini", "kickpow_lob", 0, 1000.0)
g_ball_float11 = ReadSettingFloat("incbin::Inc/Engine.ini", "kickheight_lob", 0, 1000.0)
g_ball_float12 = ReadSettingFloat("incbin::Inc/Engine.ini", "kickpow_head", 0, 1000.0)
g_ball_float13 = ReadSettingFloat("incbin::Inc/Engine.ini", "kickheight_head", 0, 1000.0)
g_ball_float14 = ReadSettingFloat("incbin::Inc/Engine.ini", "aftertouchtime", 0, 5000.0)
g_ball_float15 = ReadSettingFloat("incbin::Inc/Engine.ini", "curlinc", 0, 1000.0)
g_ball_float16 = ReadSettingFloat("incbin::Inc/Engine.ini", "curlmax", 0, 1000.0)
If Not g_ball_channel Then g_ball_channel = AllocChannel()
If Not g_ball_soundbounce Then g_ball_soundbounce = LoadSoundChecked("EngineMedia/Match/Sounds/Bounce.ogg", 0)
If Not g_ball_soundkick Then g_ball_soundkick = LoadSoundChecked("EngineMedia/Match/Sounds/Kick.ogg", 0)
If Not g_ball_sound Then g_ball_sound = LoadSoundChecked("EngineMedia/Match/Sounds/Post.ogg", 0)
Return 0
