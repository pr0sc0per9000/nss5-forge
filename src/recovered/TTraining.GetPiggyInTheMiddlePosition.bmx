' TTraining.GetPiggyInTheMiddlePosition  -- KIND=Function (TYPE=TTraining, no Self; a0 = team:TTeam)
' VA 0x00582b53   291 bytes   vtable slot 0xc0   sig (:TTeam)i
' byte-identical vs NSS5.exe (291/291, original length from Ghidra's inventory, mode=reloc)
'
' ASSUMPTIONS
'   Fields (from extracted/object_model.json): TTeam +0x1c squad:TList;
'     TPlayer +0x8 newstar:Int, +0x7c desx:Float, +0x80 desy:Float, +0xbc selectionno:Int.
'   Calls resolved: TList.Count() slot 0x70, .ObjectEnumerator() slot 0x8c (EachIn on
'     a0.squad); downcast class table 0x00c5f94c = TPlayer; 0x00c5d998 = TPitch+0x6c =
'     YardsToPixels (f)f; 0x004a1f10 = _bbCos, 0x004a1f00 = _bbSin (runtime_helpers.tsv).
'     0x41300000 is the Float literal 11.0 (YardsToPixels radius argument).
'
' Shape note: the newstar<>0 case must be written as an early `Continue`, not an If/Else
' cascade -- both give the same length everywhere else in the body, but the guard form
' changes which of {count, the EachIn enumerator} the allocator keeps in a register
' (unconditional per-iteration use beats a use gated behind a branch; see codegen-patterns
' section 18.4). The If/Else form is 1 byte short (290) with `count` in a register and the
' enumerator spilled to [ebp-0x14]; the original has it the other way round.
Local count:Int = a0.squad.Count()
For Local p:TPlayer = EachIn a0.squad
	If p.newstar <> 0
		p.desx = 0
		p.desy = 0
		Continue
	End If
	p.desx = Cos(p.selectionno * (360 / count)) * TPitch.YardsToPixels(11.0)
	p.desy = Sin(p.selectionno * (360 / count)) * TPitch.YardsToPixels(11.0)
Next
