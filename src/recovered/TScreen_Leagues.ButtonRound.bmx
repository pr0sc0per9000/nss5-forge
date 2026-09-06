' TScreen_Leagues.ButtonRound
' VA 0x005462d4   108 bytes   vtable slot 0x5c   sig ()i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' the comptype guard must be a Select with an empty 'Case 1' and the work in Default:
' a plain nested If is 6 bytes short (Select loads the field into a register, emits the
' dispatch jmp, and emits the empty case body). Two module Globals assumed:
' 0x00c66f5c:TCompetition (declared type IS pinned - GetPrevRound/GetNextRound are slots
' 0xc8/0xcc), and 0x00c66f40:Int.
'
' `call dword ptr [0x00c671a4]` IS NOT A GLOBAL FUNCTION POINTER. 0x00C671A4 is bcc's
' class table for TScreen_Leagues (base 0x00C67154) at slot 0x50, and the .data image
' holds 0x00545C5D there -- the VA of TScreen_Leagues.SetUpLeagueFixtures exactly. The
' neighbouring slots in the same table are this very Type's own Functions and confirm the
' base: 0x54=0x005461E9 ButtonFixturesFirst, 0x58=0x0054625B ButtonFixturesLeft,
' 0x5C=0x005462D4 ButtonRound (this body), 0x60=0x00546340 ButtonFixturesRight,
' 0x64=0x005463B9 ButtonFixturesLast. A static Function call inside its own Type is
' compiled by bcc to exactly this `call dword ptr [classtable+slot]` form, which decompiles
' as an indirect call through a data address and reads like a Global.
'
' This body previously modelled those two calls as `g_league_setround(...)`, a Global of
' function type. assemble.py then emitted `Global g_league_setround:Int(a:Int)`, which
' nothing in the program ever assigns, and BlitzMax initialises an unassigned function
' value to the runtime's NullFunctionError thrower rather than to 0 -- so the call threw
' "Attempt to call uninitialized function pointer" the moment the Leagues screen was set
' up (TScreen_GameMenu.ButtonCompetitions -> TScreen_Leagues.SetUpScreen -> ComboLeague ->
' ButtonRound). The five byte-identical siblings that call the same slot -- the four
' ButtonFixtures* handlers and ComboLeague -- all write the direct `SetUpLeagueFixtures(n)`
' form, so byte-identity for this shape is already demonstrated.
' extracted/global_alias_overrides.tsv carries the same adjudication and prescribes this
' repair.
	Function ButtonRound:Int()
		'!Global g_league_comp:TCompetition
		'!Global g_league_prevmode:Int
		If g_league_comp <> Null
			Select g_league_comp.comptype
				Case 1
				Default
					If g_league_prevmode <> 0
						SetUpLeagueFixtures(g_league_comp.GetPrevRound())
					Else
						SetUpLeagueFixtures(g_league_comp.GetNextRound())
					EndIf
			End Select
		EndIf
	End Function
