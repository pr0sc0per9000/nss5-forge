' TPlayer.GetOppKeeper
' VA 0x004fbc98   115 bytes   vtable slot 0x188   sig ():TPlayer
' byte-identical vs NSS5.exe (115/115, original length from Ghidra's inventory)
' Assumptions: module Globals at 0x00c5b218 / 0x00c5b21c declared TTeam (names ours; the
' declared type is load-bearing -- it fixes .id at +0x08 and .squad at +0x1c).
' Note: the second read must be t.id, not g_team1.id -- bcc does no CSE, so reloading the
' Global there costs 5 bytes the original does not spend.
	Method GetOppKeeper:TPlayer()
		'!Global g_team1:TTeam
		'!Global g_team2:TTeam
		Local t:TTeam = g_team1
		If teamid = t.id Then t = g_team2
		For Local p:TPlayer = EachIn t.squad
			If p.selectionno = 0 Then Return p
		Next
		Return Null
	End Method
