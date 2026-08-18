' TScreen_EditNations.RefreshKits
' VA 0x0052B2D5   629 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static method on the Type, no implicit Self), SIG=()i, class-table slot 0x50
' ORACLE 629/629 reloc_masked=56, first attempt.
'
' ASSUMPTIONS / RESOLUTIONS
'   Globals (names are OURS; the TYPES are load-bearing):
'     0x00C65034 -> g_en_nation:TNation   (globals_final has it as a bare Object. The code
'       reads +0x44/+0x48/+0x4C/+0x50 and dispatches slot 0x40 on each; those are
'       TBase_Team.kitcolsHome/Away/Third/Keeper:TKitStrings and TKitStrings slot 0x40 is
'       GetFileName()$. +0x6C/+0x70 are TNation.primaryskin / secondaryskin.)
'     0x00C6509C/A0/A4/A8 -> g_en_btn1..4:TButton   (slot 0x90 = TButton.SetIcon(:TImage))
'     0x00C650AC/B0/B4/B8 -> g_en_kit1..4:TKit
'   Calls: 0x004A7C20 = _bbStringConcat, 0x004A8590 = _bbGCFree (inlined BBRELEASE of the
'     old Global), 0x005AE256 = _brl_max2d_LoadImage,
'     [0x00C5C4B8] = TKit + 0x38 = CreateKit(:TKitStrings,$):TKit,
'     TKit slot 0x3C = GetPaintedPlayer($,i,i,$):TPixmap.
'   String literals read out of NSS5.exe: 0x00C831E0
'     "GameMedia/Images/Interface/s", 0x00C752AC "444444".
'
' CODEGEN NOTE
'   The four GetPaintedPlayer calls all happen BEFORE the first LoadImage, so their results
'   are four Locals; inlining each into its LoadImage would interleave them.
'   LoadImage's first parameter is Object, which is how a TPixmap is passed straight in.
	Function RefreshKits:Int()
		'!Global g_en_nation:TNation
		'!Global g_en_btn1:TButton
		'!Global g_en_btn2:TButton
		'!Global g_en_btn3:TButton
		'!Global g_en_btn4:TButton
		'!Global g_en_kit1:TKit
		'!Global g_en_kit2:TKit
		'!Global g_en_kit3:TKit
		'!Global g_en_kit4:TKit
		g_en_kit1 = TKit.CreateKit(g_en_nation.kitcolsHome, "GameMedia/Images/Interface/s" + g_en_nation.kitcolsHome.GetFileName())
		g_en_kit2 = TKit.CreateKit(g_en_nation.kitcolsAway, "GameMedia/Images/Interface/s" + g_en_nation.kitcolsAway.GetFileName())
		g_en_kit3 = TKit.CreateKit(g_en_nation.kitcolsThird, "GameMedia/Images/Interface/s" + g_en_nation.kitcolsThird.GetFileName())
		g_en_kit4 = TKit.CreateKit(g_en_nation.kitcolsKeeper, "GameMedia/Images/Interface/s" + g_en_nation.kitcolsKeeper.GetFileName())
		Local px1:TPixmap = g_en_kit1.GetPaintedPlayer("444444", g_en_nation.primaryskin + 1, -1, "444444")
		Local px2:TPixmap = g_en_kit2.GetPaintedPlayer("444444", g_en_nation.primaryskin + 1, -1, "444444")
		Local px3:TPixmap = g_en_kit3.GetPaintedPlayer("444444", g_en_nation.secondaryskin + 1, -1, "444444")
		Local px4:TPixmap = g_en_kit4.GetPaintedPlayer("444444", g_en_nation.secondaryskin + 1, -1, "444444")
		g_en_btn1.SetIcon(LoadImage(px1, -1))
		g_en_btn2.SetIcon(LoadImage(px2, -1))
		g_en_btn3.SetIcon(LoadImage(px3, -1))
		g_en_btn4.SetIcon(LoadImage(px4, -1))
	End Function
