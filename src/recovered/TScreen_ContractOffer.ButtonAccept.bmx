' TScreen_ContractOffer.ButtonAccept
' VA 0x00554297   34 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (34/34, original length from Ghidra's inventory)
' Assumes two module Globals (original names unrecoverable):
'   0x00C67B88 g_co_offer:TContractOffer -- type fixed by vtable slot 0x6c = SignForNewClub.
'     Spelled g_co_offer because that is the name its only writer uses:
'     TScreen_ContractOffer.SetUpScreen stores the offer here (`mov [0xc67b88],ebx` at
'     0x00553802).  Do not spell it g_contractoffer here: the alias tables bind that name
'     to 0x00C6CC3C, the NEGOTIATE screen's own offer, so Accept would sign through a
'     variable nothing on this screen ever writes.
'   0x00C67B90 g_fnAccept:Int() -- a function-pointer Global, called with no args
	Function ButtonAccept:Int()
		'!Global g_co_offer:TContractOffer
		'!Global g_fnAccept:Int()
		g_co_offer.SignForNewClub()
		g_fnAccept()
	End Function
