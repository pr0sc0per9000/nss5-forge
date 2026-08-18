' TScreen_EditNations.UpdateNat
' VA 0x0052AFF4   601 bytes   mode=reloc   MATCH 601/601
' KIND=Function (static method on TScreen_EditNations), SIG ()i, class-table slot 0x44.
' Body-only format: statements only, parameters are a0, a1, ...
' Writes the editor's widget values back into the nation being edited.
'
' ASSUMPTIONS (Global addresses -> declared type; all names are ours)
'   0x00C65034 TNation    the nation under edit. globals_final.tsv has it as bare "Object"
'                         (init=bbNullObject, no call-site typing); TNation is forced by the
'                         field offsets written: 0x10/0x14/0x18 ($), 0x24/0x28/0x2c/0x30 (i)
'                         are TBase_Team's, and 0x60 ($) / 0x64 / 0x68 / 0x6c / 0x70 are
'                         exactly TNation's own five fields.
'   0x00C6504C TInputBox  name            0x00C65050 TInputBox  shortname
'   0x00C65054 TInputBox  tla             0x00C65058 TInputBox  nationality
'   0x00C6505C TInputBox  strength
'   0x00C65060 TCombo     continent       0x00C65064 TCombo     rival 1
'   0x00C65068 TCombo     rival 2         0x00C6506C TCombo     rival 3
'   0x00C65070 TCombo     climate         0x00C65074 TCombo     primary skin
'   0x00C65078 TCombo     secondary skin
' (all TInputBox/TCombo rows are construction-site typed in globals_final.tsv)
'
' SLOTS RESOLVED (vtable_map.tsv)
'   TInputBox 0x94 = GetText()$      TCombo 0xC0 = GetSelectedItemId()i
'   TCombo    0xBC = GetSelectedItem()i
'   PTR_FUN_00C59A20 is a class-table interior, not a Global: TNation+0x58 =
'     SelectById(i):TNation -- written as the ordinary static call TNation.SelectById().
'   PTR_FUN_00C65228 is likewise TScreen_EditNations+0x50 = RefreshKits()i, i.e. a sibling
'     Function of this one, so it is called bare with no Type prefix (guide section 3d).
'
' OTHER
'  * 0x004A7130 = _bbStringToInt, i.e. the Int(...) around the strength text.
'  * 0x00505F6D = ClampInt and 0x00505B91 = LogLine, both from src/recovered_module/.
'    ClampInt's first parameter is a Var in the original; the recovered spelling is Int Ptr,
'    hence Varptr here.
'  * If n1 / If n2 / If n3 are plain object truth tests (12-byte cmp/je form, not the
'    21-byte If Not shape).
'!Global g_editnat_nation:TNation
'!Global g_editnat_ibName:TInputBox
'!Global g_editnat_ibShortName:TInputBox
'!Global g_editnat_ibTla:TInputBox
'!Global g_editnat_ibNationality:TInputBox
'!Global g_editnat_ibStrength:TInputBox
'!Global g_editnat_cmbContinent:TCombo
'!Global g_editnat_cmbRival1:TCombo
'!Global g_editnat_cmbRival2:TCombo
'!Global g_editnat_cmbRival3:TCombo
'!Global g_editnat_cmbClimate:TCombo
'!Global g_editnat_cmbSkin1:TCombo
'!Global g_editnat_cmbSkin2:TCombo
g_editnat_nation.name = g_editnat_ibName.GetText()
g_editnat_nation.shortname = g_editnat_ibShortName.GetText()
g_editnat_nation.tla = g_editnat_ibTla.GetText()
g_editnat_nation.nationality = g_editnat_ibNationality.GetText()
Local s:Int = Int(g_editnat_ibStrength.GetText())
ClampInt(Varptr s, 10, 100)
g_editnat_nation.strength = s
g_editnat_nation.rivalid1 = 0
g_editnat_nation.rivalid2 = 0
g_editnat_nation.rivalid3 = 0
Local n1:TNation = TNation.SelectById(g_editnat_cmbRival1.GetSelectedItemId())
If n1 Then
	g_editnat_nation.rivalid1 = n1.id
	LogLine(n1.name)
EndIf
Local n2:TNation = TNation.SelectById(g_editnat_cmbRival2.GetSelectedItemId())
If n2 Then
	g_editnat_nation.rivalid2 = n2.id
	LogLine(n2.name)
EndIf
Local n3:TNation = TNation.SelectById(g_editnat_cmbRival3.GetSelectedItemId())
If n3 Then
	g_editnat_nation.rivalid3 = n3.id
	LogLine(n3.name)
EndIf
g_editnat_nation.continent = g_editnat_cmbContinent.GetSelectedItem()
g_editnat_nation.climate = g_editnat_cmbClimate.GetSelectedItem()
g_editnat_nation.primaryskin = g_editnat_cmbSkin1.GetSelectedItem()
g_editnat_nation.secondaryskin = g_editnat_cmbSkin2.GetSelectedItem()
RefreshKits()
