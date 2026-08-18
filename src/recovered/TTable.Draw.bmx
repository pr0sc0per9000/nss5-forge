' TTable.Draw
' VA 0x00516D22   2792 bytes   mode=reloc   byte-identical vs NSS5.exe (2792/2792)
' KIND=Method, SIG ()i, slot 0x44
' A TGadget.Draw override for the game's table widget. Two independent For..EachIn
' passes: (1) header row (only if Self.showheadings) over Self.columns, drawing each
' heading's background box plus its text; (2) data rows over Self.items, skipping
' Self.itemoffset rows, then for each visible row iterating Self.columns again to draw
' the cell background/selection highlight/overlay image and either the row's text
' (row.fields[colidx]) or an icon (row.icons[colidx]), plus small "more items
' above/below" arrow indicators on column 0 when Self.activated. Stops early via Exit
' once displayrow > Self.numdisplayitems. Finishes by restoring the full-screen
' viewport and calling Self.HighlightItem() when this table is the active one
' (g_Object108 = Self) and Self.activated.
'
' ASSUMPTIONS
'  * Globals (names are ours; only the declared types are load-bearing):
'      g_screen_float01/02:Float, g_Object108:TGadget, g_Object109/110/111:TImage,
'      g_table_int03:Int, g_engine_int162/163:Int.
'      g_Object108 is compared to Self by pointer only -- declared type doesn't reach
'      codegen. g_Object109/110/111 are forced TImage by DrawImage/DrawImageRect.
'  * TColumn (class table 0x00C62CB4) and TRow (0x00C62D6C) confirmed via
'    extracted/class_tables.tsv. TColumn.w/bgcolour/txtcolour/heading/alignx and
'    TRow.bgcolour/txtcolour/fields/icons from object_model.json.
'  * harness.read_string(0x00C7DFC0) == "I" -- the text-height sample string used by
'    both loops' vertical-centring calculation.
'  * The header loop's `col.w < 1` guard is `If col.w < 1 Then Continue` (single far
'    inverted conditional jump, 10 bytes) -- a bare one-sided If costs one byte more.
'  * The row-inner loop's `col.w < 1` guard is ALSO an early-Continue form
'    (`If col.w < 1 Then colidx :+ 1; Continue`), NOT an If/Else with the drawing body
'    nested in the Else and colidx incremented at the end of each branch -- both forms
'    are 2792 bytes total and byte-identical except for SIX bytes: the two hidden
'    EachIn enumerator temps (header loop's and this loop's) land in swapped stack
'    slots ([ebp-0x20]/[ebp-0x24]) under the If/Else shape. The Continue form changes
'    the enumerator's live-range block structure (an early back-edge jump instead of a
'    body nested inside Else) enough to match the original's allocator decision. This is
'    the fix that closed it.
'  * `colidx < row.fields.Length And row.fields[colidx].Length` and
'    `colidx < row.icons.Length And row.icons[colidx] <> Null` are genuine compound
'    `And` conditions used directly as the If's test (setl/movzx tell), not a Local
'    computed then tested separately.
'  * The final `g_Object108 = Self` / `Self.activated` guard is two NESTED plain Ifs
'    (no setcc emitted for the first term), not a compound `And`.
'!Global g_screen_float01:Float
'!Global g_screen_float02:Float
'!Global g_Object108:TGadget
'!Global g_Object109:TImage
'!Global g_Object110:TImage
' g_table_int03's original data-section value is 1 (read from NSS5.exe at
' 0x00C625F0 -- codegen-patterns 21.1/21.3).
'!Global g_table_int03:Int = 1
'!Global g_Object111:TImage
'!Global g_engine_int162:Int
'!Global g_engine_int163:Int
If Self.hidden Then Return 0
Self.SetFontSize(Self.fntSize)
SetAlpha(Self.alph)
Local hx:Int = Int(Self.x)
If Self.showheadings
	For Local col:TColumn = EachIn Self.columns
		If col.w < 1 Then Continue
		SetViewport(Int(g_screen_float01 + hx), Int(g_screen_float02 + Self.y), col.w, Self.ih)
		If col.bgcolour.Length
			SetColourHex(ShiftColourHex(col.bgcolour, -128))
			DrawRect(hx, Self.y, col.w, Self.ih)
			SetColourHex(ShiftColourHex(col.bgcolour, -64))
			DrawRect(hx + 1, Self.y + 1.0, col.w - 2, Self.ih - 2)
			If g_Object111 <> Null
				SetColor(255, 255, 255)
				SetAlpha(0.2)
				DrawImageRect(g_Object111, hx, Self.y, col.w, Self.ih, 0)
				SetAlpha(1.0)
			End If
		End If
		SetColourHex(col.txtcolour)
		Local ty:Int = Int(Self.y + Self.ih / 2 - TextHeight("I") / 2)
		Select col.alignx
			Case 0
				DrawText(col.heading, hx + 2, ty)
			Case 1
				DrawText(col.heading, hx + col.w / 2 - TextWidth(col.heading) / 2, ty)
			Case 2
				DrawText(col.heading, hx - 2 + col.w - TextWidth(col.heading), ty)
		End Select
		hx :+ col.w + g_table_int03
	Next
End If
Local off:Int = Self.itemoffset
Local yy:Int = Int(Self.y)
If Self.showheadings Then yy :+ Self.ih + g_table_int03
Local displayrow:Int = 1
For Local row:TRow = EachIn Self.items
	If off > 0
		off :- 1
	Else
		Local colidx:Int = 0
		Local xx:Int = Int(Self.x)
		For Local col:TColumn = EachIn Self.columns
			If col.w < 1
				colidx :+ 1
				Continue
			End If
			SetViewport(Int(g_screen_float01 + xx), Int(g_screen_float02 + yy), col.w, Self.ih)
			Local bg:String = row.bgcolour
			If Not bg.Length Then bg = col.bgcolour
			If bg.Length
				SetColourHex(bg)
				DrawRect(xx, yy, col.w, Self.ih)
			End If
			If Self.alive And Self.activated = 0 And displayrow = Self.selecteditem
				SetColourHex(Self.highlightcol)
				DrawRect(xx, yy, col.w, Self.ih)
			End If
			If g_Object111 <> Null
				SetColor(255, 255, 255)
				SetAlpha(0.2)
				DrawImageRect(g_Object111, xx, yy, col.w, Self.ih, 0)
				SetAlpha(1.0)
			End If
			Local tc:String = row.txtcolour
			If Not tc.Length Then tc = col.txtcolour
			SetColourHex(tc)
			Local ty:Int = yy + Self.ih / 2 - TextHeight("I") / 2
			If colidx < row.fields.Length And row.fields[colidx].Length
				Select col.alignx
					Case 0
						DrawText(row.fields[colidx], xx + 2, ty)
					Case 1
						DrawText(row.fields[colidx], xx + col.w / 2 - TextWidth(row.fields[colidx]) / 2, ty)
					Case 2
						DrawText(row.fields[colidx], xx - 2 + col.w - TextWidth(row.fields[colidx]), ty)
				End Select
			Else
				If colidx < row.icons.Length And row.icons[colidx] <> Null
					SetColor(255, 255, 255)
					Select col.alignx
						Case 0
							DrawImage(row.icons[colidx], xx + 2 + ImageWidth(row.icons[colidx]) / 2, yy + Self.ih / 2, 0)
						Case 1
							DrawImage(row.icons[colidx], xx + col.w / 2, yy + Self.ih / 2, 0)
						Case 2
							DrawImage(row.icons[colidx], xx - 2 + col.w - ImageWidth(row.icons[colidx]) / 2, yy + Self.ih / 2, 0)
					End Select
				End If
			End If
			If Self.activated
				If colidx = 0 And displayrow = 1 And Self.itemoffset > 0
					DrawImage(g_Object109, xx + 12, yy + 8, 0)
				End If
				If colidx = 0 And displayrow = Self.numdisplayitems And displayrow + Self.itemoffset < Self.items.Count()
					DrawImage(g_Object110, xx + 12, yy + Self.ih - 8, 0)
				End If
			End If
			xx :+ col.w + g_table_int03
			colidx :+ 1
		Next
		yy :+ Self.ih + g_table_int03
		displayrow :+ 1
		If displayrow > Self.numdisplayitems Then Exit
	End If
Next
SetViewport(0, 0, g_engine_int162, g_engine_int163)
If g_Object108 = Self
	If Self.activated Then Self.HighlightItem()
End If
