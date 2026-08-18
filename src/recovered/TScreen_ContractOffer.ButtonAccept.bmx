' TScreen_ContractOffer.ButtonAccept
' VA 0x00554297   34 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
' Assumes two module Globals (original names unrecoverable):
'   g_contractoffer:TContractOffer  (0x00c67b88) -- type fixed by vtable slot 0x6c = SignForNewClub
'   g_fnAccept:Int()                (0x00c67b90) -- a function-pointer Global, called with no args
	Function ButtonAccept:Int()
		'!Global g_contractoffer:TContractOffer
		'!Global g_fnAccept:Int()
		g_contractoffer.SignForNewClub()
		g_fnAccept()
	End Function
