' TScreen_Negotiate.ButtonAccept
' VA 0x0057ACFA   93 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory), harness mode=reloc
' Assumptions (module Globals -- names are ours, declared types are load-bearing):
'   * 0x00C6CC3C : TContractOffer.  globals_final types it only as `Object` (usage, low),
'     but the indirect call is slot 0x44 with one Int argument, and
'     TContractOffer.IncreaseOffer(i)i is the only slot-0x44 entry in vtable_map.tsv that
'     fits a TScreen_Negotiate.
'   * 0x00C6CC40 : Int (globals_final, medium).
'   * 0x00C61C88 resolves to class table TScreen + 0x5C = TScreen.SetActive($,$):TScreen.
'   * literals: 0x00C8984C='contractoffer', 0x00C5D284=''.
' SHAPE (measured): Ghidra prints the guard as one unsigned compare (`0x28 < uVar1`); the
'   original really evaluates two signed booleans and ORs them (setl / setg), i.e.
'   `v < 0 Or v > 40`. Writing the single signed `> 40` test gives 70 bytes, not 93.
	'!Global g_contractoffer:TContractOffer
	'!Global g_neg02:Int
	Function ButtonAccept:Int()
		Local v:Int = (g_neg02 - 1) * 10
		If v < 0 Or v > 40 Then v = 0
		g_contractoffer.IncreaseOffer(v)
		TScreen.SetActive("contractoffer", "")
	End Function
