' TFixture.GetWinningTeamId
' VA 0x004C4F91  60 bytes  vtable slot 0x68
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method GetWinningTeamId:Int()
		Local t:Int=GetWinningTeamTableId()
		If t=hometeam Then Return GetHomeTeamId()
		If t=awayteam Then Return GetAwayTeamId()
		Return 0
	End Method
