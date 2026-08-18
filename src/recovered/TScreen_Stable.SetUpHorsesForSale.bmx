' TScreen_Stable.SetUpHorsesForSale
' VA 0x00588370   147 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory)
' assumptions: module Global at 0x00C6E294 declared :TList (the horse list -- the
' 0x8c/0x30/0x34 slot triple is TList.ObjectEnumerator / TListEnum.HasNext / NextObject).
' Downcast class table 0x00C6E788 is THorse + 0, so the loop variable is :THorse.
' Field +0x50 = THorse.owned:Int (object_model.json).
' 0x00505B91 = recovered module Function LogLine (function-entry tracer, literal is
' this function's own name). 0x0059F089 = _brl_random_Rand.
	Function SetUpHorsesForSale:Int()
		'!Global g_horselist:TList
		LogLine("SetUpHorsesForSale")
		For Local h:THorse = EachIn g_horselist
			If h.owned < 1
				If Rand(5, 1) = 1
					h.owned = -1
				Else
					h.owned = 0
				EndIf
			EndIf
		Next
	End Function
