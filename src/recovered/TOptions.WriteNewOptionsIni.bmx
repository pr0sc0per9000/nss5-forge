' TOptions.WriteNewOptionsIni
' VA 0x004E2FAD   820 bytes  mode=reloc  byte-identical vs NSS5.exe (820/820)
' KIND=Function, SIG ()i, slot 0x44
' ASSUMPTIONS
'   0x00C6E9A8 is a String Global (it is _bbStringConcat's first argument, so no Int->String
'     conversion is emitted) -- the writable user directory; named g_userpath here.
'   0x005B8307 resolved as _brl_stream_WriteLine and 0x005B812B as _brl_stream_CloseStream:
'     both are alias sets in brl_functions.tsv, and TStream is the only reading that fits.
'   The Null test is `If Not s Then Return 0` -- setne/movzx/cmp/jne, the 21-byte form of
'     section 10.3, NOT `If s <> Null` (which is 12 bytes and comes out 15 short overall).
'   Literal text read out of NSS5.exe with harness.read_string, not invented.
	Function WriteNewOptionsIni:Int()
		'!Global g_userpath:String
		LogLine("WriteNewOptionsIni")
		Local s:TStream = WriteFile(g_userpath + "Settings/Options.ini")
		If Not s Then Return 0
		WriteLine(s, "j_Control=0")
		WriteLine(s, "j_Scheme=0")
		WriteLine(s, "k_Up=38")
		WriteLine(s, "k_Down=40")
		WriteLine(s, "k_Left=37")
		WriteLine(s, "k_Right=39")
		WriteLine(s, "k_Button=90")
		WriteLine(s, "k_Button2=88")
		WriteLine(s, "k_Button3=67")
		WriteLine(s, "k_Button4=32")
		WriteLine(s, "k_Pause=27")
		WriteLine(s, "k_Replay=112")
		WriteLine(s, "j_Up=-3")
		WriteLine(s, "j_Down=-4")
		WriteLine(s, "j_Left=-1")
		WriteLine(s, "j_Right=-2")
		WriteLine(s, "j_Button=2")
		WriteLine(s, "j_Button2=0")
		WriteLine(s, "j_Button3=1")
		WriteLine(s, "j_Button4=3")
		WriteLine(s, "j_Pause=7")
		WriteLine(s, "j_Replay=6")
		WriteLine(s, "soundfx=100")
		WriteLine(s, "music=100")
		WriteLine(s, "difficulty=2")
		WriteLine(s, "radar=0")
		WriteLine(s, "matchlength=5")
		WriteLine(s, "matchscale=2")
		WriteLine(s, "replayscale=2")
		WriteLine(s, "displayinitials=1")
		WriteLine(s, "screen=" + FindRes800600())
		WriteLine(s, "window=1")
		WriteLine(s, "playercam=2")
		WriteLine(s, "matchfx=1")
		WriteLine(s, "distance=0")
		WriteLine(s, "leaderboardfindme=1")
		WriteLine(s, "leaderboardmyage=0")
		WriteLine(s, "leaderboardmyclub=0")
		WriteLine(s, "leaderboardmynation=0")
		WriteLine(s, "matchspeed=2")
		WriteLine(s, "tooltips=1")
		WriteLine(s, "highlightball=1")
		WriteLine(s, "showenergy=0")
		WriteLine(s, "currency=1")
		WriteLine(s, "requestfreekicks=0")
		WriteLine(s, "requestcorners=0")
		WriteLine(s, "leaderboardview=1")
		WriteLine(s, "language=0")
		WriteLine(s, "fixkick=1")
		WriteLine(s, "bossoff=0")
		CloseStream(s)
	End Function
