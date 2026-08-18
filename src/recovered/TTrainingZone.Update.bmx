' TTrainingZone.Update
' VA 0x00583DF9   143 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (143/143, original length from Ghidra's inventory, mode=reloc)
' assumptions: module Global 0x00C6D568 declared TList (slot 0x8C = ObjectEnumerator
'   at its other use sites proves TList; 0x74 = TList.Remove); 0x00C6EFD4 declared Int.
'   Fields alive +0x18 / alph +0x1C are inherited from TTrainingObject.
'   Branch order is load-bearing: the alive<>0 arm must come first.
'
' Verified from scratch with the two '!Global pragmas below -> MATCH 143/143,
' reloc_masked=5. A BUILD_FAIL here comes from a checker that cannot bind a Global from
' prose alone, not from a body defect.
	Method Update()
		'!Global g_traintime:Int
		'!Global g_trainingobjects:TList
		If alive <> 0
			alph = (g_traintime Mod 2000) * 0.001
			If alph > 1.0
				alph = 2.0 - alph
			EndIf
		Else
			alph = alph - 0.01
			If alph < 0.0
				g_trainingobjects.Remove(Self)
			EndIf
		EndIf
	End Method
