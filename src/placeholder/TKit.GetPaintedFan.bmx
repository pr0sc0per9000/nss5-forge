' ############################################################################
' # PLACEHOLDER -- NOT a reconstruction. NOT byte-exact. NOT verified.       #
' # Delete this file to restore the empty-stub behaviour exactly.            #
' ############################################################################
'
' Real function: TKit.GetPaintedFan @ 0x004DB79E, 1,569 bytes, never opened by anyone.
' Classified in docs/analysis/unopened-map.md as:
'     "Recolours a crowd-figure template into a club's kit colours"  (MODERATE)
'
' WHY A PLACEHOLDER EXISTS AT ALL
' Unrecovered functions compile to empty 14-byte stubs. An empty stub whose signature
' returns an object returns Null, and TPitch.SetUp does:
'     Local f0:TPixmap = kit.GetPaintedFan(Rand(0,4), Rand(0,2))
'     ...
'     g_fansimg[0] = LoadAnimImage(f0, 64, 128, 0, 30, -1)
'     For Local i:Int = 0 To 5 : MidHandleImage(g_fansimg[i]) : Next
' so Null propagated into LoadAnimImage, produced a Null TImage, and MidHandleImage threw
' "Attempt to access field or method of Null object" -- killing the boot before the
' language screen. Crowd art is cosmetic; it should not gate the first playable build.
'
' WHAT THIS FAKES
' Returns the kit's already-loaded template pixmap instead of a recoloured copy, so the
' crowd renders in the template's own colours rather than the club's. Geometry is
' untouched -- callers slice it as a 64x128, 30-frame anim strip, and returning the real
' template keeps that layout valid, which a synthetic pixmap would not.
'
' `.Copy()` is deliberate. Self.pixmap is the shared template held by the TKit, and
' TPitch.SetUp asks for six fans from the same kit and hands each to LoadAnimImage. Handing
' out the same object six times would alias one pixmap into six TImages.
'
' The two Int arguments (fan variant and, most likely, a skin-tone index -- unconfirmed)
' are accepted and ignored. Every fan therefore looks identical, which is visible on screen
' and is the intended tell that this is not the real body.
'
' WHAT THE REAL BODY MUST DO
' Recolour the template using Self.newcol (String[24]) the way the sibling
' TKit.GetPaintedPlayer does, honouring Self.style. Note the known original bug recorded in
' unopened-map.md for the player variant: when hair colour is the -1 "randomise" sentinel
' the original calls the randomiser, DISCARDS the result and paints with the un-randomised
' fallback. That bug is reproduced, not fixed: the original is the specification.
	Method GetPaintedFan:TPixmap(a0:Int, a1:Int)
		If Self.pixmap = Null Then Return Null
		Return Self.pixmap.Copy()
	End Method
