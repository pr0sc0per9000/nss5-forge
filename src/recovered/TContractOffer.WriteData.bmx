' TContractOffer.WriteData
' VA 0x00571030   484 bytes   vtable slot 0x34   sig (:TStream)i   KIND=Function (static)
' byte-identical vs NSS5.exe (484/484, original length from Ghidra's inventory, mode=reloc)
' Assumption: 0x00C6B428 g_offers:TList.
' 0x005B8307 is the alias set TGadget.ItemState|WriteLine; WriteLine is the member that fits.
' CODEGEN NOTE -- the compound-assign form is load-bearing and was measured against the
' alternative. Per field the original emits concat("~t", String(f)) followed by
' concat(acc, that), which is exactly `s :+ "~t" + String(f)`. The single-expression
' spelling String(id) + ("~t"+String(f)) + ... comes out 460 bytes. Note also that the
' String Local carries NO refcount traffic in this shape.
	Function WriteData(a0:TStream)
		'!Global g_offers:TList
		WriteLine(a0, "offerclubid~twage~tlength~tgoalbonus~tcleanbonus~tsigningfee~tnewbossrel")
		If g_offers <> Null
			For Local o:TContractOffer = EachIn g_offers
				Local s:String = String(o.club.id)
				s:+ "~t" + String(o.wage)
				s:+ "~t" + String(o.length)
				s:+ "~t" + String(o.goalbonus)
				s:+ "~t" + String(o.assistbonus)
				s:+ "~t" + String(o.cleanbonus)
				s:+ "~t" + String(o.signingfee)
				s:+ "~t" + String(o.newbossrel)
				s:+ "~t" + String(o.negotiationsuccess)
				WriteLine(a0, s)
			Next
		End If
		WriteLine(a0, "//")
	End Function
