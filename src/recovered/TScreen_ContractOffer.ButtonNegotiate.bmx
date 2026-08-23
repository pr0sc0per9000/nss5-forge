' TScreen_ContractOffer.ButtonNegotiate
' VA 0x00554270   39 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory, mode=reloc)
' Assumes two module Globals (original names unrecoverable):
'   0x00C67B88 g_co_offer:TContractOffer -- type fixed by vtable slot 0x40 = DoNegotiation.
'                                    Spelled g_co_offer because that is the name used by the
'                                    slot's only writer, TScreen_ContractOffer.SetUpScreen
'                                    (`mov [0xc67b88],ebx` at 0x00553802). Do not spell it
'                                    g_contractoffer here: the alias tables bind that name to
'                                    0x00C6CC3C, the NEGOTIATE screen's own offer, which is
'                                    written only once that screen has been opened and so is
'                                    Null while a first contract is on the table.
'   0x00C67B8C g_co_fn1:Int()                 -- function-pointer Global, set by SetUpScreen's
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
		'!Global g_co_offer:TContractOffer
		'!Global g_co_fn1:Int()
		If g_co_offer.DoNegotiation() = 0 Then g_co_fn1()
	End Function
