' TContractOffer.GetStringLength
' VA 0x00571d8b   62 bytes   vtable slot 0x48   sig ()$
' byte-identical vs NSS5.exe (62/62, original length from Ghidra's inventory)
' assumptions: field +0x10 is the Int `length` (extracted/object_model.json);
' 0x004A7AC0 = _bbStringFromInt, 0x004A7C20 = _bbStringConcat (runtime_helpers.tsv);
' 0x004C5549 = recovered module Function GetText. String literal contents are not
' load-bearing (their addresses relocate and are masked).
	Method GetStringLength:String()
		Return length + " " + GetText("Years")
	End Method
