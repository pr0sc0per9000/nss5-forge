' TScreen_ContractOffer.ButtonNegotiate
' VA 0x00554270   39 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory, mode=reloc)
' Assumes two module Globals (original names unrecoverable):
'   g_contractoffer:TContractOffer  (0x00C67B88) -- type fixed by vtable slot 0x40 = DoNegotiation
'   g_co_fn1:Int()                  (0x00C67B8C) -- function-pointer Global, set by SetUpScreen's
'                                    param 2 (`g_co_fn1 = a1`, TScreen_ContractOffer.SetUpScreen.bmx
'                                    line 65). Both bodies' own headers independently derive
'                                    0x00C67B8C for this slot, and extracted/decomp confirms it from
'                                    the original machine code on both ends (ButtonNegotiate@00554270.c
'                                    line 16: `(*(code *)PTR_FUN_00c67b8c)()`; SetUpScreen@005537bc.c
'                                    line 17: `PTR_FUN_00c67b8c = param_2;`). g_co_fn1 is the only name
'                                    this slot is ever written under in the corpus; the sibling slot
'                                    g_fnaccept/g_co_fn2 at 0x00C67B90 carries the identical
'                                    adjudication in extracted/global_alias_overrides.tsv.
	Function ButtonNegotiate:Int()
		'!Global g_contractoffer:TContractOffer
		'!Global g_co_fn1:Int()
		If g_contractoffer.DoNegotiation() = 0 Then g_co_fn1()
	End Function
