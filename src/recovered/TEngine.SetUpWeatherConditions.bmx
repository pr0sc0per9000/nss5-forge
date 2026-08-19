' TEngine.SetUpWeatherConditions
' VA 0x004cf2be   947 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (947/947, original length from Ghidra's inventory)
' assumes module global:  Global g_fixture:TFixture              (0x00c5b22c)
' assumes module global:  Global g_Object17:TTeam                 (0x00c5b218)
' assumes module global:  Global g_training_int03:Int             (0x00c6cf90)
' assumes module global:  Global g_contractoffer_tplayer:TProfile (0x00c6f028)

	Function SetUpWeatherConditions:Int()
		'!Global g_fixture:TFixture
		'!Global g_Object17:TTeam
		'!Global g_training_int03:Int
		'!Global g_profile:TProfile
		LogLine("SetUpWeatherConditions")
		Local wind:Int = 0
		Local chance:Int = 0
		Local dt:TMyDate = TMyDate.Create(g_fixture.sdate,1,1)
		Local wk:Int = dt.GetWeek()
		Local season:Int
		If wk < 9 Or wk > 47
			season = 1
		ElseIf wk > 32 And wk < 34
			season = 2
		Else
			season = 0
		EndIf
		Local nat:TNation
		If g_training_int03 <> 0
			nat = TNation.SelectById(g_profile.myclub.nationid)
		Else
			Local comp:TCompetition = TCompetition.SelectById(g_fixture.compid)
			Select g_fixture.level
			Case 0
				nat = TNation.SelectById(TClub.SelectById(g_Object17.id).nationid)
				If comp.locale = 1 And comp.comptype = 1 And comp.IsCupFinal()
					nat = TNation.SelectById(comp.GetBasedNationId(dt.GetYear()))
				EndIf
			Case 1
				nat = TNation.SelectById(g_Object17.id)
				If comp.locale = 2 Or comp.compstatus = 1
					nat = TNation.SelectById(comp.GetBasedNationId(dt.GetYear()))
				EndIf
			End Select
		EndIf
		Select nat.climate
		Case 0
			Select season
			Case 0
				wind = 0
				chance = 4
			Case 1
				wind = 0
				chance = 8
			Case 2
				Select Rand(2)
				Case 1
					wind = 0
				Case 2
					wind = 1
				End Select
				chance = 2
			End Select
		Case 1
			Select season
			Case 0
				wind = 0
				chance = 4
			Case 1
				wind = 0
				chance = 8
			Case 2
				wind = 1
				chance = 1
			End Select
		Case 2
			wind = 0
			Select season
			Case 0
				chance = 8
			Case 1
				chance = 10
			Case 2
				chance = 4
			End Select
		Case 3
			wind = 0
			Select season
			Case 0
				chance = 0
			Case 1
				chance = 0
			Case 2
				chance = 10
			End Select
		End Select
		LogLine("weatherchance=" + chance)
		If chance = 0
			TWeather.SetWeatherTimes(250,0,wind)
		ElseIf chance = 1
			TWeather.SetWeatherTimes(-10,Rand(30,200),wind)
		Else
			If Rand(chance) = 1
				TWeather.SetWeatherTimes(Rand(-30,90),Rand(30,200),wind)
			Else
				TWeather.SetWeatherTimes(250,0,wind)
			EndIf
		EndIf
	End Function
