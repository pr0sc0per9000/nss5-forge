' TScreen_ContractOffer.HideNewContract
' VA 0x005541EF   42 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (42/42, original length from Ghidra's inventory)
' ASSUMPTION: module Globals at 0x00C67B24 and 0x00C67B54 declared :TGadget (slots 0x58=Show, 0x54=Hide).
' harness mode=reloc.

	Function HideNewContract:Int()
		'!Global g_co_g1:TGadget
		'!Global g_co_g2:TGadget
		g_co_g1.Show()
		g_co_g2.Hide()
	End Function
