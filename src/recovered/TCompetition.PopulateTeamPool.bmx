' TCompetition.PopulateTeamPool
' VA 0x0050ABFB   2085 bytes   vtable slot 0x64   sig ()i
' byte-identical vs NSS5.exe (2085/2085, original length from Ghidra's inventory, mode=reloc)
'
' Dispatches on comptype (League=0, KO=1; LeagueCont=4, BestPlaced=2, Pool=3,
' RegionalSort=5 are all empty Cases here -- confirmed against the comptype value map
' recovered in TCompetition.GetStringCompType.bmx). Case 0 further dispatches on
' level/locale to decide whether the pool is built from continent-mates (TNation) or
' from clubs in Self's own league / continental competition. Case 1 (Knockout) fills
' teampool[0] from Self's continental-competition clubs, then tops up from promotion
' places (TPromotionPlace.place is compared against nine literal values 100..108, of
' which only 100, 101, 103, 104, 107 and 108 do anything -- 102, 105, 106 are empty
' Cases in every branch), finishing with a ShuffleIds() call that only Case 1 reaches;
' every other path returns 0 without shuffling.
'
' FIELD CORRECTION FOUND BY THE ORACLE, NOT BY READING C: every "c.???" comparison
' inside this method that is NOT a call into the already-verified SelectListByLeagueId/
' SelectListByNationId Functions reads TClub+0x6C, which is `continentalcompid`
' (offset 108), not `leagueid` (offset 104, +0x68). A first draft using leagueid
' compiled to the right length (2085/2085) but mismatched at one byte (a 0x68 vs 0x6C
' displacement) -- semantically it makes sense too: this method is filling a
' CONTINENTAL competition's pool, so it filters by continental-competition membership,
' not domestic league membership.
'
' Globals: 0x00C59A44 g_clubs:TList (all clubs, same address TClub.SelectListByLeagueId
' and TClub.SortListBy already use); 0x00C59A48 g_club_sortby:Int (TClub.Compare's sort-
' key selector, same address as TClub.SortListBy's g_club_sortby -- set to 11, Compare's
' strength Case); 0x00C596F4 g_nation_sortby:Int (TNation.Compare's sort-key selector,
' same address TNation.Compare itself declares -- set to 15, Compare's fuzzy-strength
' Case). 0x005B3516 is the default TList.Sort comparator (_brl_linkedlist_CompareObjects).
' 0x00505B91 is module Function LogLine; the literal "PopulateTeamPool:" read with
' harness.read_string() at 0x00C7CD4C.
	Method PopulateTeamPool:Int()
		'!Global g_clubs:TList
		'!Global g_club_sortby:Int
		'!Global g_nation_sortby:Int
		LogLine("PopulateTeamPool:" + name)
		Select comptype
			Case 0
				Select level
					Case 1
						Select locale
							Case 1
								Local list:TList = TNation.SelectListByContinent(based)
								For Local n:TNation = EachIn list
									n.randno = Rand(9999)
								Next
								g_nation_sortby = 15
								list.Sort(True)
								Local i:Int = 0
								For Local n:TNation = EachIn list
									teampool[i].AddItem(n.id, n.labelshortname, n.strength)
									i :+ 1
									If i >= groups Then i = 0
								Next
							Case 2
						End Select
					Case 0
						Select locale
							Case 0
								Local list:TList = TClub.SelectListByLeagueId(id)
								For Local c:TClub = EachIn list
									teampool[0].AddItem(c.id, c.labelshortname, c.strength)
								Next
							Case 1
								Local newlist:TList = CreateList()
								For Local c:TClub = EachIn g_clubs
									If c.continentalcompid = id Then newlist.AddLast(c)
								Next
								g_club_sortby = 11
								newlist.Sort(False)
								Local i:Int = 0
								For Local c:TClub = EachIn newlist
									teampool[i].AddItem(c.id, c.labelname, c.strength)
									i :+ 1
									If i >= groups Then i = 0
								Next
						End Select
				End Select
			Case 4
			Case 2
			Case 3
			Case 5
			Case 1
				If level = 0 And locale = 1
					Local x0:Int = GetNoofTeamsInRound()
					For Local c:TClub = EachIn g_clubs
						If c.continentalcompid = id And teampool[0].list.Count() < x0 Then teampool[0].AddItem(c.id, c.labelname, c.strength)
					Next
					If startyear = 1 And teampool[0].list.Count() < x0
						For Local pp:TPromotionPlace = EachIn lplacesthatpromotetome
							Local ok:Int = 1
							Select pp.place
								Case 100
									ok = 0
								Case 101
								Case 102
								Case 103
									ok = 0
								Case 104
									ok = 0
								Case 105
								Case 106
								Case 107
									ok = 0
								Case 108
							End Select
							If ok <> 0
								Local p2:TCompetition = TCompetition.SelectById(pp.parentid)
								If p2 <> Null And p2.locale = 0
									Local newlist2:TList = TClub.SelectListByNationId(p2.based)
									g_club_sortby = 11
									newlist2.Sort(False)
									For Local c:TClub = EachIn newlist2
										If c.continentalcompid = 0
											c.continentalcompid = id
											teampool[0].AddItem(c.id, c.labelname, c.strength)
											Exit
										EndIf
									Next
								EndIf
							EndIf
							If teampool[0].list.Count() >= x0 Then Exit
						Next
					EndIf
				Else
					For Local pp:TPromotionPlace = EachIn lplacesthatpromotetome
						Select pp.place
							Case 100
								For Local c:TClub = EachIn TClub.SelectListByLeagueId(pp.parentid)
									teampool[0].AddItem(c.id, c.labelshortname, c.strength)
								Next
							Case 101
								For Local c:TClub = EachIn TClub.SelectListByLeagueId(pp.parentid)
									If c.continentalcompid = 0 Then teampool[0].AddItem(c.id, c.labelshortname, c.strength)
								Next
							Case 102
							Case 103
							Case 104
							Case 105
							Case 106
							Case 107
								For Local c:TClub = EachIn TClub.SelectListByLeagueId(pp.parentid)
									If c.continentalcompid > 0 Then teampool[0].AddItem(c.id, c.labelshortname, c.strength)
								Next
							Case 108
						End Select
					Next
				EndIf
				teampool[0].ShuffleIds()
		End Select
		Return 0
	End Method
