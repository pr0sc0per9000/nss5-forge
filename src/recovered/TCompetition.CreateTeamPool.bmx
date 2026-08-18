' TCompetition.CreateTeamPool
' VA 0x0050AAE0   283 bytes   vtable slot 0x60   sig ()i
' byte-identical vs NSS5.exe (283/283, original length from Ghidra's inventory, mode=reloc)
' assumptions: none beyond the object model -- teampool is Field teampool:TTeamPool[] at
' +0x6C, slot 0x44 on TTeamPool is Clear(), 0x00C64940 is the TTeamPool class table.
' 0x00505B91 is module Function LogLine; 0x004A6480 is bbArraySlice, which is what
' `arr = arr[..n]` lowers to (the pushed ":TTeamPool" C string is its type argument).
'
' `If Self.teampool`, NOT `If Self.teampool.Length` -- the test is `cmp dword [eax+0x10],0`,
' the BBArray `size` field, which is the bare truth test (11.1). `.Length` reads [eax+0x14].
' The `Return 0` inside the If is a real early return (mov eax,0 / jmp epilogue).
	Method CreateTeamPool:Int()
		LogLine("CreateTeamPool: " + Self.name)
		If Self.teampool
			For Local tp:TTeamPool = EachIn Self.teampool
				tp.Clear()
			Next
			Return 0
		EndIf
		If Self.groups > 1
			Self.teampool = Self.teampool[..Self.groups]
		Else
			Self.teampool = Self.teampool[..1]
		EndIf
		For Local i:Int = 0 To Self.groups - 1
			Self.teampool[i] = New TTeamPool
		Next
	End Method
