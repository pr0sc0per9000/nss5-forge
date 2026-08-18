' TAchievement.Compare
' VA 0x0058D5DA   435 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (435/435, original length from Ghidra's inventory)
' globals: g_achievement_int:Int (0x00C6E80C) - the sort mode;
'          g_profile:TProfile (0x00C6F028)
' ASSUMPTION: 0x00C6F028 is typed TProfile here, not the TPlayer that globals_named.tsv
' guesses - the access is +0x1BC read as Int[], which is TProfile.achievements; TPlayer has
' no field at that offset. Only the field offset/type matter for codegen (no virtual call).
' module globals this body declares:
'   Global g_achievement_int:Int
'   Global g_profile:TProfile
	Method Compare:Int(a0:Object)
		'!Global g_achievement_int:Int
		'!Global g_profile:TProfile
		If a0 = Self Then Return 0
		Select g_achievement_int
			Case 1
				If id > TAchievement(a0).id Then Return 1
				If id < TAchievement(a0).id Then Return -1
			Case 32
				If TAchievement(a0).index < index Then Return 1
				If TAchievement(a0).index > index Then Return -1
			Case 17
				Local d1:Int = g_profile.achievements[TAchievement(a0).id - 1]
				Local d2:Int = g_profile.achievements[id - 1]
				If d1 = 0 Then d1 = 99999999
				If d2 = 0 Then d2 = 99999999
				If d1 < d2 Then Return 1
				If d1 > d2 Then Return -1
				If TAchievement(a0).index < index Then Return 1
				If TAchievement(a0).index > index Then Return -1
				If id > TAchievement(a0).id Then Return 1
				If id < TAchievement(a0).id Then Return -1
		End Select
		Return Super.Compare(a0)
	End Method
