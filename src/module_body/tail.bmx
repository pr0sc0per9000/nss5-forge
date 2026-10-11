' __bb_main, the module body: what assemble.py emits as the main file's top level
' VA 0x004BA034   7933 bytes   the main module's body
' byte-identical vs NSS5.exe (7933/7933, mode=reloc, compare_module_body.py under NSS5_NO_LEARN=1)
' The body is the whole main file's top level: the Imports in INIT_CHAIN order, the 11
' Incbins, every Type with its own Globals (src/module_body/type_globals.tsv) and this
' file. assemble.py puts them together; this file is the part written as statements.
' ============================================================================
' NSS5 module body: THE REAL PROGRAM. __bb_main body offset +5552..+7933, VA
' 0x004BB5E4..0x004BBF31. What runs at start-up, ending in GameMain().
'
' Written statement for statement from the original's own bytes; the offset on each
' line is where that statement starts in __bb_main. `Global x:T = expr` is a guarded
' module Global (#65..#93): bcc evaluates it in place, under its own init bit, and the
' bit numbers are fixed by the order, so every one of them has to be declared here and
' nowhere else. src/recovered_unverified/ModuleBody_RealProgram.bmx carries the older
' per-call evidence.
'
' The declarations before AppTitle have constant initialisers and emit no code: the
' exe holds each value as static data. The install root is "" as in the original, so
' every asset and Settings path is relative to the exe's directory, which BlitzMax makes
' the working directory at start-up.
' ============================================================================
Global g_promotionplace_int05:String = ""         ' 0x00C6E950, the install root
Global g_replay_div:Int = 25                      ' 0x00C6F02C, the fixed timestep in ms
Global g_logstream:TStream                        ' 0x00C6EFF0
Global g_forgotpwurl:String = "http://www.newstarsoccer.com/forgottenpassword.php?msg=Enter your player name and click reset to change your password..."   ' 0x00C6EF10
Global g_version:String = "1.15"                  ' 0x00C6E900
Global g_col_highlight:String = "00FF00"          ' 0x00C6E91C
Global g_locale_lang:String = "en"                ' 0x00C5A33C

AppTitle = "New Star Soccer 5"                                                    ' +5552
Global g_userpath:String = Trim(ReadSettingString(g_promotionplace_int05 + "Settings/Settings.txt", "saveloc")).ToUpper()   ' +5585 #65
If Right(g_userpath, 1) <> "/" And Right(g_userpath, 1) <> "\"                  ' +5664
	g_userpath = g_userpath + "/"
EndIf
If g_userpath.length < 3                                                          ' +5801
	g_userpath = Fn_0059812E() + "/New Star Soccer 5/"                            ' BaH.Volumes GetUserDocumentsDir
EndIf
CreateDir(g_userpath, False)                                                      ' +5861
CreateDir(g_userpath + "Settings/", False)
CreateDir(g_userpath + "Save/", False)
CreateDir(g_userpath + "Replays/", False)
g_forgotpwurl.Replace(" ", "%20")                                                 ' +5967, result discarded
Global g_engine_int161:Int = Int(ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "debug", 0.0, 2.0))          ' +5991 #66
Global g_club_int07:Int = Int(ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "fullnames", 0.0, 1.0))         ' +6070 #67
Global g_misc_int62:Int = Int(ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "nettimeout", 3.0, 99.0))       ' +6149 #68
Global g_misc_int63:Int = Int(ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "port", 0.0, 100000000.0))      ' +6231 #69
Global g_misc_int64:String = ReadSettingString(g_promotionplace_int05 + "Settings/Settings.txt", "proxy")                       ' +6310 #70
Global g_pausedms:Int = MilliSecs()                                               ' +6371 #71
SeedRnd(g_pausedms)                                                               ' +6406
Global g_engine_int164:Int = JoyCount()                                           ' +6420 #72
If g_engine_int161                                                                ' +6455
	g_logstream = WriteFile(g_promotionplace_int05 + "log.txt")
EndIf
LogLine("Debug=" + g_engine_int161)                                               ' +6522
Global g_profile:TProfile = New TProfile                                          ' +6559 #73
Global g_frameaccum:Int = g_replay_div                                            ' +6605 #74, one full tick
LogLine(GetGraphicsDriver().ToString())                                           ' +6640
If ReadSettingFloat(g_promotionplace_int05 + "Settings/Settings.txt", "opengl", 0.0, 1.0) = 1.0    ' +6663
	SetGraphicsDriver(GLMax2DDriver(), 2)
Else
	If Not D3D9Max2DDriver()                                                      ' +6741
		SetGraphicsDriver(D3D7Max2DDriver(), 2)
	EndIf
EndIf
EnableOpenALAudio()                                                               ' +6778
If Not SetAudioDriver("OpenAL")                                                   ' +6783
	SetAudioDriver("FreeAudio")
	LogLine("FreeAudio")
EndIf
Global g_object857:TChannel = AllocChannel()                                      ' +6827 #75
Global g_musicchannel:TChannel = AllocChannel()                                   ' +6865 #76
Global g_object859:TChannel = AllocChannel()                                      ' +6903 #77
Global g_object860:TSound = LoadSoundChecked("GameMedia/Sounds/Cash.ogg", 0)       ' +6941 #78
Global g_object861:TSound = LoadSoundChecked("GameMedia/Sounds/Achievement.ogg", 0)    ' +6989 #79
Global g_tracks:TSound[6]                                                         ' +7037 #80
SetMaskColor(8, 132, 107)                                                         ' +7085
AutoMidHandle(False)                                                              ' +7102
Global g_iconpath:String = g_promotionplace_int05 + "GameMedia/Images/Icons/"     ' +7112 #81
Global g_object862:TImage = LoadImageChecked(g_iconpath + "ArrowL.png", -1)       ' +7164 #82
Global g_object863:TImage = LoadImageChecked(g_iconpath + "ArrowR.png", -1)       ' #83
Global g_object864:TImage = LoadImageChecked(g_iconpath + "ArrowU.png", -1)       ' #84
Global g_object865:TImage = LoadImageChecked(g_iconpath + "ArrowD_Red.png", -1)   ' #85
Global g_object866:TImage = LoadImageChecked(g_iconpath + "Refresh.png", -1)      ' #86
Global g_object867:TImage = LoadImageChecked(g_iconpath + "Cross.png", -1)        ' #87
Global g_object868:TImage = LoadImageChecked(g_iconpath + "Tick.png", -1)         ' #88
Global g_object869:TImage = LoadImageChecked(g_iconpath + "CrossSmall.png", -1)   ' #89
Global g_object870:TImage = LoadImageChecked(g_iconpath + "TickSmall.png", -1)    ' #90
Global g_object871:TImage = LoadImageChecked(g_iconpath + "Help.png", -1)         ' #91
Global g_object872:TImage = LoadImageChecked("GameMedia\Images\Interface\MessageBg.png", -1)    ' +7794 #92
Global g_object873:TImage = LoadImageChecked("GameMedia\Images\Interface\MessageLine.png", 1)   ' +7842 #93
GameMain()                                                                        ' +7890
If g_logstream Then CloseFile g_logstream                                          ' +7895
