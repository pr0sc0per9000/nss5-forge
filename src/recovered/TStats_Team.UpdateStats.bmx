' TStats_Team.UpdateStats
' VA 0x0056EB20   407 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
Self.appearances :+ 1
If a0.subbedontime > -1
	Self.subs :+ 1
End If
Local g:Int = 0
For Local st:TStat = EachIn a0.list
	Select st.stype
		Case 5
			g :+ 1
		Case 2
			Self.shots :+ 1
		Case 3
			Self.passes :+ 1
		Case 4
			Self.assists :+ 1
		Case 6
			Self.headers :+ 1
		Case 7
			Self.tackles :+ 1
		Case 8
			Self.tackles :+ 1
		Case 11
			Self.fouls :+ 1
		Case 9
			Self.yellowcards :+ 1
			Self.fouls :+ 1
		Case 10
			Self.redcards :+ 1
			Self.fouls :+ 1
	End Select
Next
Self.goals :+ g
Self.hattricks :+ g / 3
Local d:Float = Self.distance
d :+ TPitch.PixelsToYards(a0.distance)
Self.distance = Int(d)
Self.manofthematch :+ a0.motm
Self.form = Self.form[0..Self.form.Length + 1]
Self.form[Self.form.Length - 1] = a0.rating
