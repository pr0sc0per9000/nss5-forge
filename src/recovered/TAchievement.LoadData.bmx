' TAchievement.LoadData
' VA 0x0058D1A5   814 bytes   vtable slot 0x30   sig (:TStream)i
' byte-identical vs NSS5.exe (814/814, original length from Ghidra's inventory, mode=reloc)
' assumes module globals: Global g_achievements:TList (0x00c6e808, see TAchievement.New),
' Global g_promotionplace_int05:String (0x00c6e950), Global g_profile:TProfile (0x00c6f028,
' corpus-wide name for this address -- see TCompetition.PlayFixtures etc., NOT the
' g_profile the annotation layer used for the same VA). Uses the
' recovered module Function NextFieldInt.
'
' Control-flow note: the "//" sentinel line is not a plain loop break. It is the Then-arm
' of `If ln = "//" Then <count/backfill code>; Return 0 Else <record parsing>` INSIDE the
' While body -- reaching it skips CloseStream(s) entirely (never called on that path). This
' is reproduced faithfully, not "fixed": ORIGINAL BUG (or deliberate shortcut) at VA
' 0x0058D1A5 -- the stream is left open when the CSV ends with a "//" line.
' `Local bOK:Int = ln.Length > 0` (not `bOK = False` then a later assignment) is
' load-bearing -- it must MATERIALISE the boolean immediately (setg/movzx), not test the
' condition directly, or the byte count is 6 short.
' TList slot 0x34 = Clear(), slot 0x74 = Remove(:Object), slot 0x70 = Count(), slot 0x8c =
' ObjectEnumerator() (project-wide knowledge, codegen-patterns.md 3f/10.8).
' `g_profile.achievements` is TProfile+0x1bc, an Int[] (object_model.json).
' Both Null-checks on the TStream parameter use the "If Not x" 21-byte form, not "= Null".
'
' Runtime helpers used here that were NOT yet in extracted/runtime_helpers.tsv and were
' added after independent verification (byte pattern + brl.mod C source, not
' self-referential learning): 0x004A4620 = _bbEnd (`void bbEnd(){exit(0);}`,
' blitz_app.c) for the `End` statement.
	Function LoadData:Int(a0:TStream)
		'!Global g_achievements:TList
		'!Global g_promotionplace_int05:String
		'!Global g_profile:TProfile
		If g_achievements <> Null Then g_achievements.Clear()
		If Not a0 Then a0 = ReadFile("utf8::" + g_promotionplace_int05 + "GameMedia/Data/Achievements.csv")
		If Not a0
			Notify("Could not load GameMedia/Data/Achievements.csv", 0)
			End
		EndIf
		LogLine("TAchievement.LoadData")
		ReadLine(a0)
		While Not Eof(a0)
			Local ln:String = ReadLine(a0)
			If ln = "//"
				Local n:Int = g_achievements.Count()
				LogLine("Achievements:" + String(n))
				If n < 100
					For Local i:Int = 1 To 10
						Local found:Int = False
						For Local a2:TAchievement = EachIn g_achievements
							If a2.id = i
								found = True
								Exit
							EndIf
						Next
						If Not found
							Local a3:TAchievement = New TAchievement
							a3.id = i
							a3.index = i
							a3.txt = GetText("CACHIEVEMENT_" + String(i))
						EndIf
					Next
				EndIf
				Return 0
			Else
				Local a:TAchievement = New TAchievement
				a.id = NextFieldInt(ln, "~t")
				If a.id = 0
					g_achievements.Remove(a)
				Else
					a.index = NextFieldInt(ln, "~t")
					a.txt = GetText("CACHIEVEMENT_" + String(a.id))
					Local bOK:Int = ln.Length > 0
					If bOK
						bOK = a.id <= g_profile.achievements.Length
					EndIf
					If bOK
						g_profile.achievements[a.id - 1] = NextFieldInt(ln, "~t")
					EndIf
				EndIf
			EndIf
		Wend
		CloseStream(a0)
		Return 0
	End Function
