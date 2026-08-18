' TProfile.GetSkillRating
' VA 0x00569d19   62 bytes   vtable slot 0xa4   sig ()i
' byte-identical vs NSS5.exe (62/62, original length from Ghidra's inventory)
' the temporary is required: writing it as one expression puts mov ecx,7 BEFORE the adds

	Method GetSkillRating:Int()
		Local r:Int = pace + dribbling + tackling + passing + heading + shooting + flair
		Return r / 7
	End Method
