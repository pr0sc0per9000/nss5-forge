' TScreen_EditClubs.UpdateClub
' VA 0x0052e986   884 bytes   vtable slot 0x44   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (884/884, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=71), verified with NSS5_NO_LEARN=1.
'
' Writes the edit-screen gadgets back into the club record at 0x00C653C4, then re-runs
' TScreen_EditClubs.SetUpScreen on it. Global names are ours; the TYPES are load-bearing:
'   0x00C653C4 TClub   0x00C653D8/DC/E0/E4/E8 TInputBox   0x00C653EC..0x00C65404 TCombo
'   0x00C65408/0C/10/14 TInputBox
' Field names from object_model.json (TClub extends TBase_Team, fields +0x08..+0x5c).
' ClampInt is the recovered module Function at 0x00505F6D.

'!Global g_ec_club:TClub
'!Global g_ec_ib_name:TInputBox
'!Global g_ec_ib_short:TInputBox
'!Global g_ec_ib_tla:TInputBox
'!Global g_ec_ib_nick:TInputBox
'!Global g_ec_ib_strength:TInputBox
'!Global g_ec_cmb_nation:TCombo
'!Global g_ec_cmb_rival1:TCombo
'!Global g_ec_cmb_rival2:TCombo
'!Global g_ec_cmb_rival3:TCombo
'!Global g_ec_cmb_league:TCombo
'!Global g_ec_cmb_contcomp:TCombo
'!Global g_ec_cmb_bteam:TCombo
'!Global g_ec_ib_stadium:TInputBox
'!Global g_ec_ib_capacity:TInputBox
'!Global g_ec_ib_long:TInputBox
'!Global g_ec_ib_lat:TInputBox
g_ec_club.name = g_ec_ib_name.GetText()
g_ec_club.shortname = g_ec_ib_short.GetText()
g_ec_club.tla = g_ec_ib_tla.GetText()
g_ec_club.nickname = g_ec_ib_nick.GetText()
Local st:Int = Int(g_ec_ib_strength.GetText())
ClampInt(Varptr st, 1, 100)
g_ec_club.strength = st
Local n:TNation = TNation.SelectById(g_ec_cmb_nation.GetSelectedItemId())
Local nid:Int = 0
If n <> Null Then nid = n.id
g_ec_club.nationid = nid
g_ec_club.rivalid1 = 0
g_ec_club.rivalid2 = 0
g_ec_club.rivalid3 = 0
g_ec_club.leagueid = 0
g_ec_club.continentalcompid = 0
g_ec_club.bteamofid = 0
Local c:TClub = TClub.SelectById(g_ec_cmb_rival1.GetSelectedItemId())
If c <> Null Then g_ec_club.rivalid1 = c.id
c = TClub.SelectById(g_ec_cmb_rival2.GetSelectedItemId())
If c <> Null Then g_ec_club.rivalid2 = c.id
c = TClub.SelectById(g_ec_cmb_rival3.GetSelectedItemId())
If c <> Null Then g_ec_club.rivalid3 = c.id
Local cp:TCompetition = TCompetition.SelectByBasedAndName(nid, g_ec_cmb_league.GetSelectedText())
If cp <> Null Then g_ec_club.leagueid = cp.id
Local cid:Int = 0
If n <> Null Then cid = n.continent
cp = TCompetition.SelectByBasedAndName(cid, g_ec_cmb_contcomp.GetSelectedText())
If cp <> Null Then g_ec_club.continentalcompid = cp.id
c = TClub.SelectById(g_ec_cmb_bteam.GetSelectedItemId())
If c <> Null Then g_ec_club.bteamofid = c.id
g_ec_club.stadiumname = g_ec_ib_stadium.GetText()
g_ec_club.stadiumcapacity = Int(g_ec_ib_capacity.GetText())
g_ec_club.stadiumlongitude = Float(g_ec_ib_long.GetText())
g_ec_club.stadiumlatitude = Float(g_ec_ib_lat.GetText())
TScreen_EditClubs.SetUpScreen(g_ec_club.id, "")
