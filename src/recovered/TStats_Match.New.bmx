' TStats_Match.New
' VA 0x0056D4C3   783 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, class-table slot 0x10
' ASSUMPTIONS
'   subbedontime / subbedofftime are declared `Field ... = -1`; every other field default is
'     zero/Null and therefore compiler-generated (codegen-patterns 3d). Expressed with the
'     harness's '!Field pragma.
'   0x00C6A658/65C/660/664 g_Object711..714 typed :TImage -- each is the result of
'     LoadImageChecked (declared :TImage) and is then passed to MidHandleImage.
'   0x00C6A628 g_stats_match_int01:Int, 0x00C6A62C..654 g_stats_match_float01..11:Float.
'   The guard is `If Not g_Object711`, NOT `= Null`: the original emits the 21-byte
'     setne/movzx form (codegen-patterns 10.3); `= Null` is 9 bytes shorter.
'   0x005B40BF is the CreateList member of its alias set -- the result is stored straight
'     into the :TList field (codegen-patterns 10.8).
'   Float immediates: 9.0 (SetImageHandle y-handle), -1.0/1.0 for ratingperminute,
'     -25.0/25.0 for the other ten ReadSettingFloat ranges.
'   All 16 string literals read out of NSS5.exe with harness.read_string.
' Body-only format: statements only; parameters are a0, a1, ...
'!Field subbedontime:Int = -1
'!Field subbedofftime:Int = -1
'!Global g_Object711:TImage
'!Global g_Object712:TImage
'!Global g_Object713:TImage
'!Global g_Object714:TImage
'!Global g_stats_match_int01:Int
' g_stats_match_float01-11 original data-section values, read directly from
' NSS5.exe (0x00C6A62C..654): -0.25, 3.0, 3.0, 1.0, 17.0, 10.0, 5.0, 5.0, -5.0, -8.0,
' -22.0. See codegen-patterns 21.1/21.3.
'!Global g_stats_match_float01:Float = -0.25
'!Global g_stats_match_float02:Float = 3.0
'!Global g_stats_match_float03:Float = 3.0
'!Global g_stats_match_float04:Float = 1.0
'!Global g_stats_match_float05:Float = 17.0
'!Global g_stats_match_float06:Float = 10.0
'!Global g_stats_match_float07:Float = 5.0
'!Global g_stats_match_float08:Float = 5.0
'!Global g_stats_match_float09:Float = -5.0
'!Global g_stats_match_float10:Float = -8.0
'!Global g_stats_match_float11:Float = -22.0
If Not g_Object711 Then
	g_Object711 = LoadImageChecked("GameMedia/Images/Interface/StatsPitch.png", -1)
	MidHandleImage(g_Object711)
	g_Object712 = LoadImageChecked("GameMedia/Images/Interface/Blob.png", -1)
	MidHandleImage(g_Object712)
	g_Object713 = LoadImageChecked("GameMedia/Images/Interface/Arrow.png", -1)
	SetImageHandle(g_Object713, 0, 9.0)
	g_Object714 = LoadImageChecked("GameMedia/Images/Interface/Heatmap.png", -1)
	MidHandleImage(g_Object714)
	g_stats_match_float01 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingperminute", -1.0, 1.0)
	g_stats_match_float02 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingpasses", -25.0, 25.0)
	g_stats_match_float03 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingdefensiveheaders", -25.0, 25.0)
	g_stats_match_float04 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingshots", -25.0, 25.0)
	g_stats_match_float05 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratinggoals", -25.0, 25.0)
	g_stats_match_float06 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingassists", -25.0, 25.0)
	g_stats_match_float07 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingsaves", -25.0, 25.0)
	g_stats_match_float08 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingtackles", -25.0, 25.0)
	g_stats_match_float09 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingfouls", -25.0, 25.0)
	g_stats_match_float10 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingyellows", -25.0, 25.0)
	g_stats_match_float11 = ReadSettingFloat("incbin::Inc/Engine.ini", "ratingreds", -25.0, 25.0)
End If
Self.list = CreateList()
g_stats_match_int01 = 1
