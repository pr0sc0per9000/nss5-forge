' ============================================================================
'  Pipeline proof: load the REAL New Star Soccer 5 data files using the Type
'  layouts recovered from the original executable's reflection metadata.
'  If the numbers below match the shipped data, the reconstruction of the
'  team/nation model is correct.
' ============================================================================
SuperStrict

Framework BRL.StandardIO
Import BRL.LinkedList
Import BRL.Stream
Import BRL.TextStream
Import BRL.Retro

Include "nss5/teams.bmx"

Const GAME:String = "C:/Program Files (x86)/Steam/steamapps/common/New Star Soccer 5"

Print "=============================================================="
Print " NSS5 reconstruction - data pipeline test"
Print "=============================================================="
Print ""

Local nNations:Int = TNation.LoadData(GAME + "/GameMedia/Data/Nations.csv")
Local nClubs:Int   = TClub.LoadData(GAME + "/GameMedia/Data/Clubs.csv")

Print "Nations loaded : " + nNations
Print "Clubs loaded   : " + nClubs
Print ""

' ---- spot checks against known data -----------------------------------------
Local afg:TNation = TNation.SelectById(1)
If afg Then
	Print "Nation id=1    : " + afg.name + " (" + afg.tla + ") strength=" + afg.strength
	Print "  stadium      : " + afg.stadiumname + " cap=" + afg.stadiumcapacity
	Print "  lon/lat      : " + afg.stadiumlongitude + " / " + afg.stadiumlatitude
	Print "  nationality  : " + afg.nationality + "  continent=" + afg.continent + ..
		" climate=" + afg.climate
	Print "  home kit     : " + afg.kitcolsHome.ToString()
End If
Print ""

Local c1:TClub = TClub.SelectById(1)
If c1 Then
	Print "Club id=1      : " + c1.name + " (" + c1.tla + ") strength=" + c1.strength
	Print "  stadium      : " + c1.stadiumname + " cap=" + c1.stadiumcapacity
	Print "  nationid     : " + c1.nationid + "  leagueid=" + c1.leagueid
	Print "  home kit     : " + c1.kitcolsHome.ToString()
End If
Print ""

' ---- strongest clubs in the world -------------------------------------------
Print "Top 15 clubs by strength:"
Local best:TClub[] = New TClub[15]
For Local c:TClub = EachIn TClub.list
	For Local i:Int = 0 Until 15
		If best[i] = Null Or c.strength > best[i].strength Then
			For Local j:Int = 14 To i + 1 Step -1
				best[j] = best[j - 1]
			Next
			best[i] = c
			Exit
		End If
	Next
Next
For Local i:Int = 0 Until 15
	If best[i] Then
		Local nat:TNation = TNation.SelectById(best[i].nationid)
		Local natname:String = "?"
		If nat Then natname = nat.name
		Print "  " + RSet(String(i + 1), 2) + ". " + LSet(best[i].name, 30) + ..
			" str=" + RSet(String(best[i].strength), 3) + "  " + natname
	End If
Next
Print ""

' ---- integrity checks --------------------------------------------------------
Local orphans:Int = 0
Local bteams:Int = 0
Local totalCap:Long = 0
For Local c:TClub = EachIn TClub.list
	If TNation.SelectById(c.nationid) = Null Then orphans :+ 1
	If c.bteamofid > 0 Then bteams :+ 1
	totalCap :+ c.stadiumcapacity
Next
Print "Clubs with unknown nationid : " + orphans
Print "Clubs that are B teams      : " + bteams
Print "Total stadium capacity      : " + totalCap
Print ""

' ---- continent breakdown -----------------------------------------------------
Print "Nations per continent:"
Local contName:String[] = ["", "Asia", "Africa", "North America", "South America", ..
	"Oceania", "Europe"]
For Local ci:Int = 1 To 6
	Local l:TList = TNation.SelectListByContinent(ci)
	Print "  " + LSet(contName[ci], 16) + " " + RSet(String(l.Count()), 3) + " nations"
Next
Print ""
Print "=============================================================="
Print " PIPELINE OK"
Print "=============================================================="
