' TTeam.NewLocalPlayer
' VA 0x004de470   166 bytes   vtable slot 0xf4   sig (:TPlayer)i
' byte-identical vs NSS5.exe (166/166, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c6efd4 declared :Int (stored into lastchangeplayer).
' The guard is an early return, not a wrapping If: `If controller <> 1 Then Return 0`
' produces the original's `je` skip; the `If controller = 1 ... EndIf` form is 10 bytes short.
	Method NewLocalPlayer(a0:TPlayer)
		'!Global g_time:Int
		If controller <> 1 Then Return 0
		lastchangeplayer = g_time
		Local last:TPlayer = Null
		For Local p:TPlayer = EachIn squad
			If p.controller = 1 Then last = p
			p.controller = 0
		Next
		a0.controller = 1
		If a0 <> last Then a0.CheckHoldingKick()
	End Method
