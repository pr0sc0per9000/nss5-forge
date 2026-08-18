' TCompetition.GetStringTeamPosition  (i)$   slot 0x9c
' VA 0x0050CB18   length 213   oracle: MATCH mode=reloc 213/213 reloc_masked=7
'
' Assumptions:
'   Self.comptype   TCompetition +0x24 Int
'   Self.teampool   TCompetition +0x6c []:TTeamPool  (array EachIn: data at +0x18, end via +0x10)
'   TTeamPool.list  +0x08 :TList
'   TTableData.teamid +0x0c Int
'   inner call resolves to TTeamPool.GetStringTeamPosition, slot 0x54 on TTeamPool
'   no Globals used
Method GetStringTeamPosition:String(a0:Int)
	If Self.comptype <> 1
		Local tp:TTeamPool = Null
		For Local p:TTeamPool = EachIn Self.teampool
			For Local td:TTableData = EachIn p.list
				If td.teamid = a0
					tp = p
					Exit
				EndIf
			Next
		Next
		If tp <> Null Then Return tp.GetStringTeamPosition(a0)
	EndIf
	Return ""
End Method
