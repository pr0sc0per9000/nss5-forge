' TCompetition.DoPromotionPlaces
' VA 0x0050F0D0   1905 bytes   vtable slot 0x124   sig ()i
' byte-identical vs NSS5.exe (1905/1905, mode=reloc, 53 relocations masked, original length
' from Ghidra's inventory)
'
' Two nested loops over Self.teampool (a []:TTeamPool field -- iteration auto-skips Null
' array slots, no explicit guard needed in source):
'   1) For each TTeamPool, resort its table by a comptype/townregion-selected key
'      (Select comptype [0..5], comptype=5 sub-selects on townregion [1..4]; comptype=1 and
'      any unmatched combination do nothing -- ORIGINAL BUG/no-op, reproduced faithfully).
'   2) For each TTeamPool, for each TPromotionPlace in lpromotionplaces: resolve (and cache,
'      across BOTH loop levels) the destination TCompetition by promotiontoid, then dispatch
'      on pp.place. place holds either one of 9 special codes 100-108 (source:
'      docs/specs/06-binary-string-subsystem-map.md line 1005 -- 100 AllTeams,
'      101 TeamsNotInCnt, 102 HighestNotInCnt, 103 AllWinningTeams, 104 AllLosingTeams,
'      105 WinTeamElseLosing, 106 WinTeamElseLeague, 107 TeamsInContinental,
'      108 LoseTeamElseLeague) or an ordinary 1-based table position handled by the
'      Default arm. Codes 100, 101, 102 and 107 are empty Cases -- promotion for those is
'      evidently handled elsewhere; reproduced as no-ops, not "fixed" into something that
'      does work (law 3).
'
' Slot/Function resolution used throughout (all already corroborated in the corpus):
'   0x00C6160C = TCompetition class table + 0x4C = TCompetition.SelectById(i):TCompetition
'                (qualified Function call from inside a Method emits this class-table-literal
'                 indirect call form, not a plain E8)
'   0x00C59E0C = TClub class table + 0x60      = TClub.SelectById(i):TClub
'   slot 0x128 on the destination TCompetition = TCompetition.PromoteToMe(:TTableData,
'                :TCompetition)i -- the very next declared method after DoPromotionPlaces
'                (0x0050F841, immediately following this body in the vtable).
'   LogLine (module Function, already in src/recovered_module/LogLine.bmx) = the 0x00505B91
'                debug sink.
'   Notify(msg$, error) = BRL builtin (_brl_system_Notify, 0x005B4C68).
'
' CODEGEN FINDING (new): an Object "= Null" / "<> Null" test that must be MATERIALISED into
' a 0/1 value (i.e. used as an operand of Or/And, not as a lone If's condition) compiles
' differently depending on whether the source used "Not x" or "x = Null":
'   "Not x", solo If condition            -> ONE setne+movzx+cmp+jne          (section 10.3)
'   "x = Null", solo If condition         -> direct cmp+je                    (section 10.3)
'   "Not x", embedded in Or (materialised)     -> setne+movzx+cmp THEN sete+movzx+cmp (double)
'   "x = Null"/plain, embedded in Or (materialised) -> ONE sete+movzx+cmp (single)
' Confirmed by direct A/B compile against this body: the solo check after SelectById needed
' "If Not nextComp Then" (single form) while the first Or-term needed "Not nextComp Or ..."
' i.e. it ALSO reads as "Not", but the embedded position costs it the extra inversion step
' the solo form saves by folding into branch sense instead. Recorded for the next large body
' with a cached-lookup-then-Or-refresh shape.
	Method DoPromotionPlaces:Int()
		LogLine("DoPromotionPlaces:" + id + " " + name)

		For Local t:TTeamPool = EachIn teampool
			Select comptype
				Case 0
					t.SortTableBy(4)
				Case 1
				Case 2
					t.SortTableBy($10)
				Case 3
					t.SortTableBy($10)
				Case 4
					t.SortTableBy(4)
				Case 5
					Select townregion
						Case 1
							t.SortTableBy($18)
						Case 2
							t.SortTableBy($19)
						Case 3
							t.SortTableBy($18)
						Case 4
							t.SortTableBy($19)
					End Select
			End Select
		Next

		Local nextComp:TCompetition = Null

		For Local t:TTeamPool = EachIn teampool
			For Local pp:TPromotionPlace = EachIn lpromotionplaces
				If Not nextComp Or pp.promotiontoid <> nextComp.id Then
					nextComp = TCompetition.SelectById(pp.promotiontoid)
					If Not nextComp Then
						Notify("Could not promote to competition! Comp: " + name + " Place: " + pp.place + " PromotionToId:" + pp.promotiontoid, False)
					End If
				End If

				LogLine("Promoting to:" + nextComp.id + " " + nextComp.name)

				Select pp.place
					Case 100
					Case 101
					Case 102
					Case 103
						For Local fx:TFixture = EachIn lfixturelist
							If legs < 2 Or fx.leg = 2 Then
								Local winId:Int = fx.GetWinningTeamTableId()
								If winId <> 0 Then
									nextComp.PromoteToMe(t.GetItemById(winId), Self)
								End If
							End If
						Next
					Case 104
						For Local fx:TFixture = EachIn lfixturelist
							If legs < 2 Or fx.leg = 2 Then
								Local loseId:Int = fx.GetLosingTeamTableId()
								If loseId <> 0 Then
									nextComp.PromoteToMe(t.GetItemById(loseId), Self)
								End If
							End If
						Next
					Case 105
						For Local fx:TFixture = EachIn lfixturelist
							If legs < 2 Or fx.leg = 2 Then
								Local winId:Int = fx.GetWinningTeamTableId()
								If winId <> 0 Then
									Local club:TClub = TClub.SelectById(t.GetItemById(winId).teamid)
									If club.continentalcompid = 0 Then
										nextComp.PromoteToMe(t.GetItemById(winId), Self)
									Else
										Local loseId:Int = fx.GetLosingTeamTableId()
										If loseId <> 0 Then
											nextComp.PromoteToMe(t.GetItemById(loseId), Self)
										End If
									End If
								End If
							End If
						Next
					Case 106
						For Local fx:TFixture = EachIn lfixturelist
							If legs < 2 Or fx.leg = 2 Then
								Local winId:Int = fx.GetWinningTeamTableId()
								If winId <> 0 Then
									nextComp.PromoteToMe(t.GetItemById(winId), Self)
								End If
							End If
						Next
					Case 107
					Case 108
						For Local fx:TFixture = EachIn lfixturelist
							If legs < 2 Or fx.leg = 2 Then
								Local loseId:Int = fx.GetLosingTeamTableId()
								If loseId <> 0 Then
									nextComp.PromoteToMe(t.GetItemById(loseId), Self)
								End If
							End If
						Next
					Default
						Local pos:Int = 1
						For Local td:TTableData = EachIn t.list
							If pos = pp.place Then
								nextComp.PromoteToMe(td, Self)
								Exit
							Else
								pos :+ 1
							End If
						Next
				End Select
			Next
		Next

		Return 0
	End Method
