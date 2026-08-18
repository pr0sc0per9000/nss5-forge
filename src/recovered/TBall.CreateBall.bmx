' TBall.CreateBall  (KIND=Function -- static; a0/a1/a2 are x,y,z, NOT Self)
' VA 0x004C7CF2   345 bytes   sig (i,i,i):TBall
' byte-identical vs NSS5.exe (345/345, original length from Ghidra's inventory, mode=reloc)
' GLOBAL NAMES ARE OURS.
' `DAT_00c72590 = DAT_00c72590 + 1` in the decompilation is the retain half of the
' "FF9900" assignment (0x00C7258C + 4), not a counter -- see codegen-patterns 10.6.
' The x87 compare is `seta`: the ORIGINAL puts the weather amount on the left.
' Writing `snowthreshold < amount` gives setb and misses at byte 277 with the right length.
'!Global g_ball_nextid:Int
'!Global g_weather_type:Int
' g_ball_snowthreshold's original data-section value is 0.5 (read from NSS5.exe
' at 0x00C72588). Never stored to anywhere in the corpus -- see codegen-patterns 21.1.
'!Global g_ball_snowthreshold:Float = 0.5
'!Global g_weather_amount:Float
g_ball_nextid = g_ball_nextid + 1
LogLine("CreateBall:" + g_ball_nextid)
Local b:TBall = New TBall
b.id = g_ball_nextid
b.x = a0
b.y = a1
b.z = a2
b.oldx = a0
b.oldy = a1
b.oldz = a2
b.replayframes = CreateList()
b.colour = "FFFFFF"
If g_weather_type = 1 And g_weather_amount > g_ball_snowthreshold
	b.colour = "FF9900"
EndIf
TBall.SetActive(b)
Return b
