' TScreen_NewPlayer.RefreshKit
' VA 0x005248fa   117 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (117/117, original length from Ghidra's inventory, mode=reloc)
' assumes module Globals (names ours, types load-bearing):
'   Global g_np_btnkit:TButton  (0x00C64244, slot 0x90 = TButton.SetIcon(:TImage))
'   Global g_profile:TProfile (0x00C6F028, typed from its construction site)
' PTR_FUN_00C5C4B8 = TKit class table + 0x38 -> TKit.CreateKit(:TKitStrings,$):TKit
' slot 0x3C on TKit = GetPaintedPlayer($,i,i,$):TPixmap; FUN_005AE256 = LoadImage.
' The two Locals are load-bearing: as one expression bcc loads g_np_btnkit into ebx FIRST
'   (first_diff at byte 4) and evaluates `New TKitStrings` after pushing the path string.
' HARNESS: needs harness.MODULE_TYPES patched with TImage -> BRL.Max2D and
'   TPixmap -> BRL.Pixmap (see report).
'!Global g_np_btnkit:TButton
'!Global g_profile:TProfile
' Renamed g_np_profile -> g_profile. Third name found for 0x00C6F028 (with
' g_contractoffer_tplayer and g_profile); one slot must be declared once. Type unchanged.

	Function RefreshKit:Int()
		Local ks:TKitStrings = New TKitStrings
		Local px:TPixmap = TKit.CreateKit(ks,"GameMedia/Images/Interface/Player.png").GetPaintedPlayer("444444", g_profile.playercols.skin, g_profile.playercols.hair, "444444")
		g_np_btnkit.SetIcon(LoadImage(px, -1))
	End Function
