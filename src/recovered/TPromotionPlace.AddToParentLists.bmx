' TPromotionPlace.AddToParentLists
' VA 0x00526273   120 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (120/120, original length from Ghidra's inventory)
' assumptions: 0x00C6160C = TCompetition class table + 0x4c = SelectById(i):TCompetition.
' Fields from object_model.json: TPromotionPlace.parentid +0x8, .promotiontoid +0x10;
' TCompetition.lpromotionplaces +0x64, .lplacesthatpromotetome +0x68 (both :TList),
' TList slot 0x44 = AddLast.
' The explicit `Else Return 0` is load-bearing: it is the 9 bytes (jmp over else +
' mov eax,0 / jmp) that separate 111 from 120.
	Method AddToParentLists:Int()
		Local c1:TCompetition = TCompetition.SelectById(parentid)
		Local c2:TCompetition = TCompetition.SelectById(promotiontoid)
		If c1 <> Null And c2 <> Null
			c1.lpromotionplaces.AddLast(Self)
			c2.lplacesthatpromotetome.AddLast(Self)
		Else
			Return 0
		EndIf
	End Method
