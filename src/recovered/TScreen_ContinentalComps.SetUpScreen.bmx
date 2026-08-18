' TScreen_ContinentalComps.SetUpScreen
' VA 0x00533C42   710 bytes   byte-identical vs NSS5.exe (modulo the four masks)
' KIND=Function (static method on the Type, no implicit Self), SIG=()i, class-table slot 0x34
' ORACLE 710/710 under NSS5_NO_LEARN=1.
'
' ASSUMPTIONS / RESOLUTIONS
'  * Globals declared here (names are OURS; the TYPES are load-bearing because they select
'    the vtable slots):
'      g_cc_combocontinent:TCombo  at 0x00C65A28 (0xB8 CountItems, 0x90 AddItem($,$,$,i))
'      g_continents:TList          at 0x00C6080C (0x8C ObjectEnumerator; elements downcast
'                                                 to ClassTable_TContinent 0x00C60958)
'      g_cc_tableplaces:TTable     at 0x00C65A48 (0x9C ClearItems, 0x94 AddItem([]$,$,$),
'                                                 0xA0 SetColumnHeading(i,$)).  NOTE this is
'                                                 a DIFFERENT Global from g_cc_table
'                                                 (0x00C65A4C) used by RefreshQualifiers.
'      g_cc_continent:TContinent   at 0x00C65A20 (tested for Null only)
'      g_cc_comp:TCompetition      at 0x00C65A24 (+0x68 lplacesthatpromotetome, 0xA4
'                                                 GetNoofTeamsInRound)
'      g_promotionplace_max:Int    at 0x00C64600 (bare dword store of 19, no refcount)
'  * Static calls resolved through class_tables/vtable_map:
'      [0x00C61C88] = TScreen + 0x5C          -> TScreen.SetActive($,$)
'      [0x00C6160C] = TCompetition + 0x4C     -> TCompetition.SelectById(i)
'      [0x00C59A20] = TNation + 0x58          -> TNation.SelectById(i)
'      [0x00C65C4C] / [0x00C65C60] are THIS Type's own class table (+0x44 / +0x58), so they
'      are written unprefixed: RefreshQualifiers() / RefreshClubCombo().
'      0x004C5549 = GetText (ONE argument), 0x004A7AC0 = _bbStringFromInt,
'      0x004A7C20 = _bbStringConcat, 0x004A7C90 = _bbStringSlice,
'      0x004A63D0 = _bbArrayNew1D (the String[] literal, descriptor 0x00C59058).
'  * `.Sort()` emits `push _brl_linkedlist_CompareObjects / push 1` -- those are TList.Sort's
'    DEFAULT arguments, not written in source.
'  * The opening guard is `If Not a Or Not b Then Return 0`: the doubled
'    setne/movzx + sete/movzx pair is the object truth test followed by an explicit Not,
'    and the `cmp eax,0 / jne` between them is the Or's short circuit.
'    `If comp <> Null` inside the loop is the COMPACT `cmp/je` form instead (guide 10.3).
'  * `Local n:TNation = TNation.SelectById(comp.based)` is load-bearing (guide 16.2): written
'    inline, bcc pushes the concat operands BEFORE calling SelectById and the body is 710
'    bytes with two 12-byte gaps.  The Local forces SelectById to be called first.
'  * Field offsets: TCompetition id=+0x08 name=+0x0C tla=+0x10 locale=+0x18 based=+0x20;
'    TNation extends TBase_Team so name=+0x10; TPromotionPlace parentid=+0x08.
'  * String literal CONTENT is not byte-observable (their addresses are masked); every
'    literal below was read out of NSS5.exe with harness.read_string.
'!Global g_cc_combocontinent:TCombo
'!Global g_continents:TList
'!Global g_cc_tableplaces:TTable
'!Global g_cc_continent:TContinent
'!Global g_cc_comp:TCompetition
'!Global g_promotionplace_max:Int
	Function SetUpScreen()
		TScreen.SetActive("continentalcomps", "")
		If g_cc_combocontinent.CountItems() = 0
			For Local c:TContinent = EachIn g_continents
				g_cc_combocontinent.AddItem(c.name, "FFFFFF", "FFFFFF", c.id)
			Next
		End If
		g_cc_tableplaces.ClearItems()
		If Not g_cc_continent Or Not g_cc_comp Then Return 0
		g_promotionplace_max = 19
		g_cc_comp.lplacesthatpromotetome.Sort()
		For Local pp:TPromotionPlace = EachIn g_cc_comp.lplacesthatpromotetome
			Local comp:TCompetition = TCompetition.SelectById(pp.parentid)
			If comp <> Null
				Local s1:String = String(comp.id)
				Local s2:String = comp.tla + ":" + comp.name
				If comp.locale = 0
					Local n:TNation = TNation.SelectById(comp.based)
					s2 = n.name[..6] + ":" + comp.name
				End If
				g_cc_tableplaces.AddItem([s1, s2, pp.GetStringPlace()], "000000", "FFFFFF")
			End If
		Next
		g_cc_tableplaces.SetColumnHeading(2, GetText("Place") + " (" + String(g_cc_comp.GetNoofTeamsInRound()) + ")")
		RefreshQualifiers()
		RefreshClubCombo()
	End Function
