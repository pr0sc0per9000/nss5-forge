' TScreen_Achievements.SetUpScreen
' VA 0x00559566   744 bytes  mode=reloc  byte-identical vs NSS5.exe (744/744)
' KIND=Function, SIG ()i, slot 0x34
' ASSUMPTIONS
'   0x00C6E808 g_achievements:TList (slots 0x88 Sort / 0x70 Count / 0x8C ObjectEnumerator,
'     downcast to ClassTable_TAchievement), 0x00C68324 :TTable, 0x00C68328 :TProgressBar
'     (construction sites), 0x00C6E80C :Int, 0x00C68309/0x00C6831C :TImage (they are the
'     single element of the TImage[] passed to TTable.SetItemIcons (i,[]:TImage)i).
'   0x00C6F028 g_profile:TProfile; achievements []i at 0x1BC and helppages []i at 0x1C8,
'     so [base+0x34] is element 7 (data starts at +0x18).  Slot 0x14C = GetAchievements()i.
'   Both TTable.AddItem row arrays and both SetItemIcons arrays are ARRAY LITERALS -- the
'     element stores carry a retain but no BBRELEASE of the old value.
'   `If a.id = 80 Then Continue` (jne +5 / jmp) -- section 10.9's Continue shape.  As
'     `If a.id <> 80 <block>` it is one byte short (a single je).
'   `If d.sdate > best`, not `If best < d.sdate`: the original loads best into eax and
'     compares `cmp [esi+8],eax / jle`.  Same length, different bytes at +578.
	Function SetUpScreen:Int()
		'!Global g_profile:TProfile
		'!Global g_achievements:TList
		'!Global g_ach_table:TTable
		'!Global g_ach_progress:TProgressBar
		'!Global g_ach_int:Int
		'!Global g_img_ach_done:TImage
		'!Global g_img_ach_locked:TImage
		TScreen.SetActive("achievements", "")
		g_ach_table.ClearItems()
		g_ach_int = 17
		g_achievements.Sort()
		LogLine("Achievements:" + g_achievements.Count())
		Local bestrow:Int = 0
		Local best:Int = 0
		Local row:Int = 1
		For Local a:TAchievement = EachIn g_achievements
			If a.id = 80 Then Continue
			If g_profile.achievements[a.id - 1] = 0
				g_ach_table.AddItem(["", a.txt, "-"], "", "")
				g_ach_table.SetItemIcons(row, [g_img_ach_locked])
			Else
				Local d:TMyDate = TMyDate.Create(g_profile.achievements[a.id - 1], 1, 1)
				g_ach_table.AddItem(["", a.txt, d.GetString("YYY-WWW")], "", "")
				g_ach_table.SetItemIcons(row, [g_img_ach_done])
				If d.sdate > best
					best = d.sdate
					bestrow = row
				End If
			End If
			row = row + 1
		Next
		g_ach_table.SelectItemByRow(bestrow)
		g_ach_progress.SetPercent(g_profile.GetAchievements(), 1)
		If g_profile.helppages[7] = 0
			TScreen.Tutorial()
			g_profile.helppages[7] = 1
		End If
	End Function
