' TCompetition.GetCupLastRound
' VA 0x0050DA54  34 bytes  vtable slot 0xe8
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method GetCupLastRound:TCompetition()
		Local c:TCompetition=Self
		Local p:TCompetition
		Repeat
			p=c
			c=c.GetCupNextRound()
		Until c=p
		Return p
	End Method
