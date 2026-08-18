' ############################################################################
' # PLACEHOLDER -- NOT a reconstruction. NOT byte-exact. NOT verified.       #
' # Delete this file to restore the empty-stub behaviour exactly.            #
' ############################################################################
'
' Real function: TKit.GetPaintedPlayer @ 0x004DB0DD, 1,729 bytes, never opened by anyone.
' Classified in docs/analysis/unopened-map.md as:
'     "Recolours a kit template image into a team's actual player kit colours"  (MODERATE)
'
' Same reasoning as its sibling TKit.GetPaintedFan.bmx -- read that header first. An empty
' stub returns Null, and the two call sites both feed the result straight into image
' construction:
'     Local p:TPixmap = a0.GetPaintedPlayer(bootcol, skincol, haircol, glovecol)
'     Local px:TPixmap = TKit.CreateKit(ks, "GameMedia/Images/Interface/Player.png") ..
'                          .GetPaintedPlayer("444444", g_profile.playercols.skin, ..)
' so every player sprite and the profile portrait would be Null.
'
' WHAT THIS FAKES
' Returns a copy of the kit's loaded template pixmap. Players render in the template's own
' colours: no club kit, no skin tone, no hair colour, no keeper gloves. Sprite-sheet
' geometry is preserved because it is the real template, which is what the anim-strip
' slicing downstream depends on.
'
' Arguments accepted and ignored: a0 boot colour (hex String), a1 skin colour index,
' a2 hair colour index, a3 glove colour (hex String).
'
' WHAT THE REAL BODY MUST DO
' Recolour via Self.newcol:String[24] under Self.style, then apply boot/skin/hair/glove.
' REPRODUCE, do not fix, the documented original bug (unopened-map.md): when hair colour is
' the -1 "randomise" sentinel the original calls the randomiser, throws the result away and
' paints with the un-randomised fallback, so every haircol=-1 player gets identical hair.
' Preserve-by-default: that bug is in scope to keep.
	Method GetPaintedPlayer:TPixmap(a0:String, a1:Int, a2:Int, a3:String)
		If Self.pixmap = Null Then Return Null
		Return Self.pixmap.Copy()
	End Method
