' TFixture.GetLosingTeamTableId
' VA 0x004C4F61  48 bytes  vtable slot 0x64
' byte-identical vs NSS5.exe
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.

	Method GetLosingTeamTableId:Int()
		Local t:Int=GetWinningTeamTableId()
		If t=hometeam Then Return awayteam
		If t=awayteam Then Return hometeam
		Return 0
	End Method
