' TProfile.GetStringContractExpires
' VA 0x005692FF   42 bytes   vtable slot 0x84   sig ()$
' byte-identical vs NSS5.exe (42/42, original length from Ghidra's inventory)
' no assumptions: TMyDate.Create is class-table slot 0x30, TMyDate.GetString slot 0x5c
	Method GetStringContractExpires:String()
		Return TMyDate.Create(contractexpires,1,1).GetString("YYYY-WWW")
	End Method
