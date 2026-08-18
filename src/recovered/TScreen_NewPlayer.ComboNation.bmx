' TScreen_NewPlayer.ComboNation
' VA 0x00524783   69 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (69/69, original length from Ghidra's inventory, mode=reloc)
' assumes module Globals (names ours, types load-bearing):
'   Global g_np_cmbnation:TCombo  (0x00C64220, typed from its construction site)
'   Global g_np_btnflag:TButton   (0x00C64224, typed from its construction site)
' slots: TCombo+0xC0 = GetSelectedItemId, TButton+0x8C = SetImage(:TImage)
' PTR_FUN_00C59A20 = TNation class table + 0x58 -> TNation.SelectById(i):TNation
'!Global g_np_cmbnation:TCombo
'!Global g_np_btnflag:TButton

	Function ComboNation:Int()
		Local n:TNation = TNation.SelectById(g_np_cmbnation.GetSelectedItemId())
		If n <> Null Then g_np_btnflag.SetImage(n.imgFlagSmall)
	End Function
