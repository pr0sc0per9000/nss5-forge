' TTraining.SetUpTraining_Dribbling
' VA 0x0057CD1F   3119 bytes   KIND=Function (static, no implicit Self)   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (3119/3119, original length from Ghidra inventory, mode=reloc)
' Body-only format: statements only.
'
' THE ONE NON-OBVIOUS SOURCE FACT:
'   the cone branch reuses ONE angle variable. `a` is Rand(90,1) for the cone offset and is
'   then RE-ASSIGNED Rand(180,1) inside the pole loop -- it is not two Locals `a` and `b`.
'   Two separate Locals give a body that is 3119/3119 with an identical instruction stream
'   and still MISMATCHes: the shorter live range lets the angle colour to ebx instead of
'   esi, and the knock-on spill order transposes x/y (-0x4c/-0x50) and cx/cy (-0x64/-0x68).
'   19 instructions, 19 bytes.
'
' Select has 20 Cases and NO Default (pattern 10.2): every compare is emitted back to back.
' `g_training_int04 = g_profile.dribbling * 2 + 10` then `:/ 10` are TWO statements -- the
' Global is stored before the idiv and re-loaded.
'
' Global types are assumptions; 0x00C6CFA4/A8/AC carry full retain/release traffic and are
' Strings, contradicting globals_final.tsv which calls all three Int (pattern 11.2).
'   0x00C6CF94 int04  0x00C6CF9C int06  0x00C6CFA4 int08$  0x00C6CFA8 int09$
'   0x00C6CFAC int10$ 0x00C6CFB8 TLabel
' The two zones are g_object811/g_object812, not names local to this file. The store order
' at 0x0057D539 / 0x0057D58A is 0x00C6CFC8 then 0x00C6CFCC, so 0x00C6CFC8 is the near green
' zone ("00FF00" at 0xC6E904) and 0x00C6CFCC the far red one ("FF0000" at 0xC725EC). Those
' are the names TTraining.UpdateDribbling/UpdatePace read the same two slots under, and the
' reader is what turns the far zone green and completes the drill -- naming them anything
' else here splits each slot in two and the reader never sees what this function wrote.
'   0x00C6CFC8 g_object811:TTrainingZone (start)  0x00C6CFCC g_object812:TTrainingZone (end)
'   0x00C6CFD0 int11  0x00C6CFD4 int12  0x00C6CFF0 int19  0x00C6CFF4 int20
'   0x00C5D634 g_player_int16 (Int)      0x00C6F028 TProfile
' g_training_int04's original data-section value is 1 (read from NSS5.exe at
' 0x00C6CF94 -- codegen-patterns 21.1/21.3).
'!Global g_training_int04:Int = 1
'!Global g_training_int06:Int
'!Global g_training_int08:String
'!Global g_training_int09:String
'!Global g_training_int10:String
'!Global g_training_int11:Int
'!Global g_training_int12:Int
'!Global g_training_int19:Int
'!Global g_training_int20:Int
'!Global g_traininglabel_msg:TLabel
'!Global g_object811:TTrainingZone
'!Global g_object812:TTrainingZone
'!Global g_player_int16:Int
'!Global g_profile:TProfile
LogLine("SetUpTraining_Dribbling")
g_training_int04 = g_profile.dribbling * 2 + 10
g_training_int04 :/ 10
ClampInt(Varptr g_training_int04, 1, 20)
g_training_int08 = GetText("Dribbling Training")
g_training_int09 = GetText("Level") + " " + g_training_int04
g_training_int10 = GetText("CTRAINING_DRIBBLING1")
If g_training_int04 = 1 And g_profile.contractwage = 0
	g_traininglabel_msg.SetText(GetText("CMESSAGE_TRIALDRIBBLING"), "", -1, -1)
End If
Local gap:Int = 10
Local wobble:Int = 0
Select g_training_int04
	Case 1
		g_training_int19 = 0
		gap = 8
		g_training_int06 = 60
		g_training_int20 = 3
		wobble = 0
	Case 2
		g_training_int19 = 2
		gap = 10
		g_training_int06 = 20
		g_training_int20 = 0
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
	Case 3
		g_training_int19 = 0
		gap = 7
		g_training_int06 = 20
		g_training_int20 = 4
		wobble = 1
	Case 4
		g_training_int19 = 3
		gap = 10
		g_training_int06 = 20
		g_training_int20 = 0
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
	Case 5
		g_training_int19 = 0
		gap = 6
		g_training_int06 = 20
		g_training_int20 = 5
		wobble = 2
	Case 6
		g_training_int19 = 4
		gap = 10
		g_training_int06 = 20
		g_training_int20 = 0
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
	Case 7
		g_training_int19 = 0
		gap = 5
		g_training_int06 = 20
		g_training_int20 = 6
		wobble = 2
	Case 8
		g_training_int19 = 5
		gap = 9
		g_training_int06 = 20
		g_training_int20 = 0
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
	Case 9
		g_training_int19 = 0
		gap = 4
		g_training_int06 = 20
		g_training_int20 = 7
		wobble = 2
	Case 10
		g_training_int19 = 5
		gap = 8
		g_training_int06 = 20
		g_training_int20 = 1
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
	Case 11
		g_training_int19 = 0
		gap = 4
		g_training_int06 = 18
		g_training_int20 = 8
		wobble = 2
	Case 12
		g_training_int19 = 6
		gap = 7
		g_training_int06 = 18
		g_training_int20 = 1
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
	Case 13
		g_training_int19 = 0
		gap = 4
		g_training_int06 = 16
		g_training_int20 = 9
		wobble = 2
	Case 14
		g_training_int19 = 7
		gap = 7
		g_training_int06 = 16
		g_training_int20 = 1
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
	Case 15
		g_training_int19 = 0
		gap = 4
		g_training_int06 = 14
		g_training_int20 = 10
		wobble = 2
	Case 16
		g_training_int19 = 8
		gap = 7
		g_training_int06 = 14
		g_training_int20 = 1
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
	Case 17
		g_training_int19 = 0
		gap = 4
		g_training_int06 = 12
		g_training_int20 = 10
		wobble = 2
	Case 18
		g_training_int19 = 9
		gap = 7
		g_training_int06 = 12
		g_training_int20 = 1
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
	Case 19
		g_training_int19 = 0
		gap = 4
		g_training_int06 = 10
		g_training_int20 = 10
		wobble = 2
	Case 20
		g_training_int19 = 10
		gap = 7
		g_training_int06 = 12
		g_training_int20 = 1
		g_training_int10 = GetText("CTRAINING_DRIBBLING2")
End Select
gap = Int(TPitch.YardsToPixels(gap))
g_training_int11 = Int(-g_player_int16 + TPitch.YardsToPixels(5.0))
g_training_int12 = Int(TPitch.YardsToPixels(-20.0))
If g_training_int19 <> 0
	g_object811 = TTrainingZone.Create(g_training_int11, g_training_int12, 2.0, "00FF00", "")
	g_object812 = TTrainingZone.Create(g_training_int11 + (g_training_int19 + 1) * gap, g_training_int12, 2.0, "FF0000", "")
	For Local i:Int = 1 To g_training_int19
		Local x:Int = g_training_int11 + i * gap
		Local y:Int = g_training_int12
		TCone.Create(x, y, 1)
		Local a:Int = Rand(90, 1)
		Local cx:Int = Int(x + Cos(a) * TPitch.YardsToPixels(5.0))
		Local cy:Int = Int(y + Sin(a) * TPitch.YardsToPixels(5.0))
		TCone.Create(cx, cy, 1)
		For Local j:Int = 1 To g_training_int20
			a = Rand(180, 1)
			Local d:Int = Rand(1, 4)
			Local px:Int = Int(x + Cos(a) * TPitch.YardsToPixels(d))
			Local py:Int = Int(y + Sin(a) * TPitch.YardsToPixels(d))
			TPole.Create(px, py, "FFFF00")
		Next
		TTrainingLine.Create(x, y, cx, cy, "00FF00")
	Next
Else
	g_object811 = TTrainingZone.Create(g_training_int11, g_training_int12, 2.0, "00FF00", "")
	g_object812 = TTrainingZone.Create(g_training_int11 + (g_training_int20 + 1) * gap, g_training_int12, 2.0, "FF0000", "")
	Local lastx:Int = 0
	Local lasty:Int = 0
	For Local i:Int = 1 To g_training_int20
		Local x:Int = g_training_int11 + i * gap
		Local y:Int = Int(g_training_int12 + TPitch.YardsToPixels(Rand(-wobble, wobble)))
		TPole.Create(x, y, "FFFF00")
		If i > 1
			TTrainingLine.Create(x, y, lastx, lasty, "00FF00")
		End If
		lastx = x
		lasty = y
	Next
End If
TTrainingLine.ActivateNextLine()
TBall.CreateBall(g_training_int11 + 15, g_training_int12, 0)
