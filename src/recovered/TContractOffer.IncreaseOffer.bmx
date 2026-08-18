' TContractOffer.IncreaseOffer
' VA 0x00571d0a   129 bytes   vtable slot 0x44   sig (i)i
' byte-identical vs NSS5.exe (129/129, original length from Ghidra's inventory)
	Method IncreaseOffer:Int(a0:Int)
		negotiationsuccess = 1
		wage :+ (wage/100)*a0
		goalbonus :+ (goalbonus/100)*a0
		assistbonus :+ (assistbonus/100)*a0
		cleanbonus :+ (cleanbonus/100)*a0
		signingfee :+ (signingfee/100)*a0
		TScreen_ContractOffer.UpdateOfferDetails(0,1)
	End Method
