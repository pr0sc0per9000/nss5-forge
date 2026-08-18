' TTeam.PaintSquad
' VA 0x004DDD04   358 bytes   vtable slot 0x54   sig (i)i   KIND=Method
' byte-identical vs NSS5.exe (358/358, original length from Ghidra's inventory, mode=reloc)
' Assumption: 0x00C5B210 is an Int flag suppressing the progress bar (bare dword compare).
' The float operands 100.0 / 0.0 / 1.0 / 2.0 / 51.0 are .rdata literals read out of
' NSS5.exe, not Globals.
' The imgPlayer test is the `If Not x` emission (setne/movzx/cmp/jne), not `If x = Null`.
' "00FF00" is a literal here -- the original does NOT call the ColourGreen helper.
' NOTE: the Local cannot be called `step`; bcc reserves it (For..Step).
	Method PaintSquad:Int(a0:Int)
		'!Global g_noProgress:Int
		Local stp:Float = 100.0 / Self.squad.Count()
		Local pos:Float = 0.0
		For Local p:TPlayer = EachIn Self.squad
			If Not p.imgPlayer
				If p.selectionno = 0
					p.PaintPlayer(Self.kitkeeper)
				ElseIf p.selectionno < 11
					p.PaintPlayer(Self.kitplayer)
				End If
				pos = pos + stp
				If g_noProgress = 0
					If a0 = 1
						TScreen.DoProgressBar(1.0 + pos/2.0, GetText("Create Players"), "00FF00", -1)
					Else
						TScreen.DoProgressBar(51.0 + pos/2.0, GetText("Create Players"), "00FF00", -1)
					End If
				End If
			End If
		Next
	End Method
