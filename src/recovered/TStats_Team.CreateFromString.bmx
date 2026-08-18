' TStats_Team.CreateFromString
' VA 0x0056EF96   978 bytes  mode=reloc  byte-identical vs NSS5.exe (978/978)
' KIND=Function, SIG ($):TStats_Team, slot 0x3C
' ASSUMPTIONS
'   Field names/offsets from extracted/object_model.json; the 17 NextFieldInt calls land on
'     statlevel(0x08) .. manofthematch(0x48) in declaration order, and form is []i at 0x4C.
'   0x00C59097 is the BBArray element-type descriptor for Int (first byte 0x69 = 'i'), so
'     the _bbArraySlice is an Int[] resize.
'   STATEMENT ORDER IS BYTE-OBSERVABLE: `Local s:String = a0` is emitted BEFORE
'     `New TStats_Team`.  With them the other way round the length is still 978 but the
'     bodies diverge at byte 9 (mov eax,[ebp+8] / mov [ebp-4],eax before the bbObjectNew).
	Function CreateFromString:TStats_Team(a0:String)
		Local s:String = a0
		Local st:TStats_Team = New TStats_Team
		st.statlevel = NextFieldInt(s, "~t")
		st.teamid = NextFieldInt(s, "~t")
		st.year = NextFieldInt(s, "~t")
		st.appearances = NextFieldInt(s, "~t")
		st.subs = NextFieldInt(s, "~t")
		st.shots = NextFieldInt(s, "~t")
		st.goals = NextFieldInt(s, "~t")
		st.hattricks = NextFieldInt(s, "~t")
		st.passes = NextFieldInt(s, "~t")
		st.assists = NextFieldInt(s, "~t")
		st.headers = NextFieldInt(s, "~t")
		st.tackles = NextFieldInt(s, "~t")
		st.fouls = NextFieldInt(s, "~t")
		st.yellowcards = NextFieldInt(s, "~t")
		st.redcards = NextFieldInt(s, "~t")
		st.distance = NextFieldInt(s, "~t")
		st.manofthematch = NextFieldInt(s, "~t")
		While s <> ""
			st.form = st.form[..st.form.Length + 1]
			st.form[st.form.Length - 1] = NextFieldInt(s, "~t")
		Wend
		Return st
	End Function
