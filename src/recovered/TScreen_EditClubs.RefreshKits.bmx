' TScreen_EditClubs.RefreshKits
' VA 0x0052ECFA   631 bytes   class-table slot 0x48   KIND=Function (static)   sig ()i
' byte-identical vs NSS5.exe (631/631, original length from Ghidra's inventory, mode=reloc)
' Body-only format: statements only, no parameters.
'
' ASSUMPTIONS / RESOLUTIONS
'  * Globals (names ours; types are from globals_final.tsv type_source=construction and
'    are corroborated by every slot used through them):
'      0x00C653C4 TClub    0x00C6542C/30/34/38 TKit    0x00C6541C/20/24/28 TButton
'  * Class-table function pointers resolved via globals_final.tsv's classtable-slot rows:
'      [0x00C5C4B8] = TKit+0x38   = TKit.CreateKit(:TKitStrings,$):TKit
'      [0x00C59A20] = TNation+0x58 = TNation.SelectById(i):TNation
'  * Virtual slots: TKitStrings 0x40 = GetFileName()$, TKit 0x3C = GetPaintedPlayer,
'    TButton 0x90 = SetIcon(:TImage)i.
'  * TClub's kit fields live in its Super TBase_Team: kitcolsHome/Away/Third/Keeper at
'    +0x44/+0x48/+0x4C/+0x50 (walked through class_tables.tsv: TClub extends TBase_Team).
'  * 0x005AE256 = _brl_max2d_LoadImage; the argument is the TPixmap from GetPaintedPlayer.
'  * String literals read out of NSS5.exe: 0x00C831E0 is the image path prefix,
'    0x00C752AC is "444444" (used for BOTH the first and last GetPaintedPlayer argument).
'  * The club Global is RE-READ for the CreateKit argument after the GetFileName call --
'    that is bcc's normal Global handling, not a Local.
'!Global g_editclubs_club:TClub
'!Global g_editclubs_kit1:TKit
'!Global g_editclubs_kit2:TKit
'!Global g_editclubs_kit3:TKit
'!Global g_editclubs_kit4:TKit
'!Global g_editclubs_btn1:TButton
'!Global g_editclubs_btn2:TButton
'!Global g_editclubs_btn3:TButton
'!Global g_editclubs_btn4:TButton
g_editclubs_kit1 = TKit.CreateKit(g_editclubs_club.kitcolsHome, "GameMedia/Images/Interface/s" + g_editclubs_club.kitcolsHome.GetFileName())
g_editclubs_kit2 = TKit.CreateKit(g_editclubs_club.kitcolsAway, "GameMedia/Images/Interface/s" + g_editclubs_club.kitcolsAway.GetFileName())
g_editclubs_kit3 = TKit.CreateKit(g_editclubs_club.kitcolsThird, "GameMedia/Images/Interface/s" + g_editclubs_club.kitcolsThird.GetFileName())
g_editclubs_kit4 = TKit.CreateKit(g_editclubs_club.kitcolsKeeper, "GameMedia/Images/Interface/s" + g_editclubs_club.kitcolsKeeper.GetFileName())
Local skin1:Int = 0
Local skin2:Int = 0
Local nat:TNation = TNation.SelectById(g_editclubs_club.nationid)
If nat <> Null
	skin1 = nat.primaryskin + 1
	skin2 = nat.secondaryskin + 1
EndIf
Local pix1:TPixmap = g_editclubs_kit1.GetPaintedPlayer("444444", skin1, -1, "444444")
Local pix2:TPixmap = g_editclubs_kit2.GetPaintedPlayer("444444", skin1, -1, "444444")
Local pix3:TPixmap = g_editclubs_kit3.GetPaintedPlayer("444444", skin2, -1, "444444")
Local pix4:TPixmap = g_editclubs_kit4.GetPaintedPlayer("444444", skin2, -1, "444444")
g_editclubs_btn1.SetIcon(LoadImage(pix1, -1))
g_editclubs_btn2.SetIcon(LoadImage(pix2, -1))
g_editclubs_btn3.SetIcon(LoadImage(pix3, -1))
g_editclubs_btn4.SetIcon(LoadImage(pix4, -1))
