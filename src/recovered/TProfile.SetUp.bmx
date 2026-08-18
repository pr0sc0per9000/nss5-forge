' TProfile.SetUp
' VA 0x00562D5D   357 bytes   vtable slot 0x30   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (357/357, mode=reloc, reloc_masked=42)
'
' No module Globals. Every indirect call is a class-table + slot static call:
'   0x00C6E8E0 TAchievement.LoadData    0x00C6098C TContinent.LoadData
'   0x00C59A10 TNation.LoadData         0x00C59DFC TClub.LoadData
'   0x00C615FC TCompetition.LoadData    0x00C6478C TPromotionPlace.LoadData
'   0x00C6E240 TScreen_Stable.LoadData  0x00C61CD8 TScreen.DoProgressBar(f,$,$,i)
' The percentages are the .rdata float immediates 0x41700000 .. 0x42BE0000, and the two
' string literals are read out of NSS5.exe at 0x00C73AA4 ("Loading") / 0x00C6E904.

	Function SetUp:Int()
		TAchievement.LoadData(Null)
		TScreen.DoProgressBar(15.0,GetText("Loading"),"00FF00",0)
		TContinent.LoadData(Null)
		TScreen.DoProgressBar(25.0,GetText("Loading"),"00FF00",0)
		TNation.LoadData(Null)
		TScreen.DoProgressBar(35.0,GetText("Loading"),"00FF00",0)
		TClub.LoadData(Null)
		TScreen.DoProgressBar(65.0,GetText("Loading"),"00FF00",0)
		TCompetition.LoadData(Null)
		TScreen.DoProgressBar(75.0,GetText("Loading"),"00FF00",0)
		TPromotionPlace.LoadData(Null)
		TScreen.DoProgressBar(85.0,GetText("Loading"),"00FF00",0)
		TScreen_Stable.LoadData(Null)
		TScreen.DoProgressBar(95.0,GetText("Loading"),"00FF00",0)
	End Function
