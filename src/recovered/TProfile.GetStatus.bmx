' TProfile.GetStatus
' VA 0x0056A8D0   133 bytes   vtable slot 0xBC   sig ()f
' byte-identical vs NSS5.exe (133/133, original length from Ghidra's inventory)
' assumptions: own-vtable slots 0x14C GetAchievements, 0xA4 GetSkillRating,
'   0xF4 GetLifestyle, 0xF8 GetFame, 0xC4 GetHappiness.
'   The five Float Locals are load-bearing -- inlining the calls into one
'   expression is 153 bytes; the original spills four to Float slots and keeps
'   the fifth on the x87 stack, which only the Local form reproduces.
	Method GetStatus:Float()
		Local ach:Float = GetAchievements()
		Local skl:Float = GetSkillRating()
		Local lif:Float = GetLifestyle()
		Local fam:Float = GetFame()
		Local hap:Float = GetHappiness()
		Return (ach + skl + lif + fam + hap) / 5.0
	End Method
