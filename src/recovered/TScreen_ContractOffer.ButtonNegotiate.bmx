' TScreen_ContractOffer.ButtonNegotiate
' VA 0x00554270   39 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory, mode=reloc)
' Assumes two module Globals (original names unrecoverable):
'   g_contractoffer:TContractOffer  (0x00C67B88) -- type fixed by vtable slot 0x40 = DoNegotiation
'   g_fnNegotiate:Int()             (0x00C67B8C) -- function-pointer Global, set by SetUpScreen's param 2
	Function ButtonNegotiate:Int()
		'!Global g_contractoffer:TContractOffer
		'!Global g_fnNegotiate:Int()
		If g_contractoffer.DoNegotiation() = 0 Then g_fnNegotiate()
	End Function
