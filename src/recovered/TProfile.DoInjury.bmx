' TProfile.DoInjury
' VA 0x0056bb58   419 bytes   vtable slot 0x114   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (419/419, original length from Ghidra's inventory)
'
' The last statement has to be `:+`, not `=`. `x = x + ' ' + y` emits concat(concat(x,' '),y);
' the original emits concat(x, concat(' ', y)), which is what `x :+ ' ' + y` produces.
' Two attempts: the `=` form was 419/419 in length with first_diff at 354.
' Rand(3) lowers to Rand(3,1) -- the pushed 1 is BRL's default maxValue, not a second argument.
	Method DoInjury:Int()
		LogLine("DoInjury")
		Self.injury = Rand(3)
		If Rand(5) = 1
			Self.injury = Rand(3, 5)
		EndIf
		If Self.takenpainkillers
			Self.injury = Rand(5, 7)
		EndIf
		If Self.injury = 1
			Self.physioreport = GetText("CREPORT_PHYSIO1")
		Else
			Self.physioreport = GetText("CREPORT_PHYSIO2").Replace("$num", String(Self.injury))
		EndIf
		Local s:String = ""
		If Self.injury > 5
			s = Self.LoseRandomSkillPoint(3)
		ElseIf Self.injury > 3
			s = Self.LoseRandomSkillPoint(2)
		ElseIf Self.injury > 1
			s = Self.LoseRandomSkillPoint(1)
		EndIf
		If s <> ""
			Self.physioreport :+ " " + GetText("CREPORT_PHYSIO3").Replace("$skillslost", s)
		EndIf
		Self.injury = Self.injury + 1
	End Method
