' TContractOffer.GetOffer
' VA 0x00571431   2026 bytes   sig (:TClub):TContractOffer   slot 0x3c   KIND=Function
' byte-identical vs NSS5.exe (2026/2026, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=86)
' Body-only format: statements only, parameters are a0, a1, ...
'
' ASSUMPTIONS
'   Global (name ours): 0x00C6B424 -> g_signaturesound:TSound. `If Not g_signaturesound` is
'     the required 21-byte setne/movzx form (matches TBlackJack.SetUp's established idiom for
'     this exact lazy-load shape), not the 12-byte `= Null` form. 0x004BC564 is the
'     already-verified module Function LoadSoundChecked($,i):TSound; the literal at 0x00C8F79C
'     decodes (harness.read_string) to 'GameMedia/Sounds/Signature.ogg', pushed directly with
'     NO g_mediaprefix/g_pathPrefix concatenation at this call site.
'   Global (name ours): 0x00C6B428 -> g_contractoffers:TList (same Global CreateContract.bmx
'     already established). `If g_contractoffers <> Null` is the direct 12-byte cmp/je form
'     (a plain relational test, unlike the `Not` form above).
'   Global (name ours): 0x00C6F028 -> g_profile:TProfile (established by every other
'     TContractOffer body in this file). Fields used: clubid 0x20, contractwage 0x78,
'     relationboss 0x104, date 0x10, contractexpires 0x74, position 0x30, myclub 0x1D0.
'     TMyDate.sdate:Int is at +8 (object_model.json). TProfile.GetAge()i is slot 0xA0
'     (vtable_map.tsv).
'   a0:TClub fields: id 0xC, strength 0x24 (both inherited from TBase_Team).
'   TContractOffer(a0's downcast target, and New's class table) = 0x00C6B7B8
'     (class_tables.tsv). TList slots 0x8C ObjectEnumerator / 0x30 HasNext / 0x34 NextObject
'     compile from `For Local o:TContractOffer = EachIn g_contractoffers` exactly as in the
'     sibling TContractOffer.GetClubsInterestedInLoan.bmx.
'   Float literals read from the exe (harness -- struct.unpack, f32 unless noted):
'     0xC8F7E4=6.5 (strength divisor), 0xC8F7E8=2.25 (f64, pow base), 0xC8F7F0=75.0
'     (relationboss divisor), 0xC8F7F4=0.7 and 0xC8F7F8=0.7 (SAME value, two separate literal
'     slots -- bcc does not dedupe, matching the established pattern in GetPlayerValueStatus),
'     0xC8F7FC=1.25 (expired-contract wage bump), then the tier-ladder multipliers 0xC8F800/
'     04/08=3.0, 0xC8F80C/10/14=2.0, 0xC8F818/1C/20=1.5, 0xC8F824/28/2C=1.25,
'     0xC8F830=1.5 (signingfee only), 0xC8F834/38/3C=0.5.
'
' SHAPE NOTES (byte-observable, established via localise_diff.py against the original)
'  * The list-search candidate and the newly-created offer are TWO SEPARATE Locals (`o` in
'    the For loop, `c` after it), not one reused variable. Ghidra's decompile folds them into
'    one `puVar6` (SSA-style), which is misleading: the ORIGINAL puts the search candidate in
'    ecx (dead on no-match) and the created object in esi, two independent register-allocator
'    nodes with independent reference counts. Reusing a single "c" for both roles inflates
'    its reference count enough that bcc leaves `a0` (the TClub parameter) unregistered
'    (reloaded from [ebp+8] on every use) -- +66 bytes of dead weight, all in reload
'    instructions. Splitting into `o`/`c` restores both `a0` and `c` to registers, matching
'    the original exactly (codegen-patterns.md 18: reference count/liveness, not something to
'    force by hand -- the fix here is a genuine two-Locals structural difference, not a
'    reorder).
'  * `g_profile.GetAge()` is called ONCE for the length-tier ladder and cached in a Local
'    (`age`), then compared three times (`age > 30`, `age > 32`, `age > 33`). Writing three
'    separate `g_profile.GetAge()` calls (bcc does no CSE) cost 3x17 extra bytes. The LATER,
'    unrelated wage-cap check (`g_profile.GetAge() < 31`) is a genuinely separate call at a
'    different program point and is NOT the same node -- it stays a fresh call.
'  * Every "round down to the nearest N" (`x = (x \ N) * N`) is TWO SEPARATE STATEMENTS in
'    the original (a plain division statement, then a plain multiplication statement), not
'    one combined `(x/N)*N` expression -- confirmed by instruction grouping: for the
'    goalbonus/assistbonus/cleanbonus trio the original does all three idiv first, THEN all
'    three imul, which only a 6-statement source produces; a 3-statement combined-expression
'    source interleaves div/mul per field instead.
'  * Case 0 and Case 1 of the position Select have byte-IDENTICAL bodies emitted at two
'    DIFFERENT addresses (not one shared target with two `je`s) -- the original wrote them as
'    separate Case blocks, not `Case 0, 1`. Reproduced as written (law 4: do not DRY).
'  * Position 5's assistbonus is the only bonus in the whole ladder with NO `+ 50` -- confirmed
'    directly in the disassembly (no `add eax,0x32` before the store), not a Ghidra artifact.
'    Left exactly as the original computes it.
'  * `2.25 ^ (a0.strength / 6.5)` matches the FPU trace exactly: the division is done in
'    single precision (`fdiv dword`, matching 6.5's 4-byte encoding) and only promoted to
'    double at the `pow` call boundary; `2.25` is embedded directly as pow's declared-Double
'    argument (`fld qword`) with no separate conversion. Legacy bcc literal typing needs no
'    explicit `#`/`:Float` suffix here to get this split.
'   ORIGINAL BUG (not fixed): the very first block re-checks/re-caches g_signaturesound on
'   EVERY call to GetOffer regardless of which branch follows (find-existing vs create-new);
'   the sound is loaded once and cached, so this costs nothing at runtime, but it is dead
'   work on the "found existing offer" early-return path.
'!Global g_signaturesound:TSound
'!Global g_contractoffers:TList
'!Global g_profile:TProfile
If Not g_signaturesound
	g_signaturesound = LoadSoundChecked("GameMedia/Sounds/Signature.ogg", 0)
EndIf

If g_contractoffers <> Null
	For Local o:TContractOffer = EachIn g_contractoffers
		If o.club.id = a0.id Then Return o
	Next
EndIf

Local c:TContractOffer = New TContractOffer
c.club = a0
c.newbossrel = 70
If a0.id = g_profile.clubid
	c.newbossrel = g_profile.relationboss
EndIf

If g_profile.contractwage = 0 And g_profile.date.GetYear() = 1
	c.wage = 1000
	c.length = 3
	c.goalbonus = 50
	c.assistbonus = 50
	c.cleanbonus = 50
	c.signingfee = 1000
Else
	c.wage = 2.25 ^ (a0.strength / 6.5)

	If a0.id = g_profile.clubid
		Local fVar2:Float = g_profile.relationboss / 75.0
		If fVar2 < 0.7 Then fVar2 = 0.7
		c.wage = c.wage * fVar2
	ElseIf g_profile.date.sdate > g_profile.contractexpires
		c.wage = c.wage * 1.25
	EndIf

	c.length = Rand(3, 5)
	Local age:Int = g_profile.GetAge()
	If age > 30 Then c.length = 3
	If age > 32 Then c.length = 2
	If age > 33 Then c.length = 1

	Select g_profile.position
		Case 0
			c.goalbonus = 0
			c.assistbonus = 0
			c.cleanbonus = (a0.strength * g_profile.myclub.strength) / 5 + 50
		Case 1
			c.goalbonus = 0
			c.assistbonus = 0
			c.cleanbonus = (a0.strength * g_profile.myclub.strength) / 5 + 50
		Case 2
			c.goalbonus = 0
			c.assistbonus = (a0.strength * g_profile.myclub.strength) / 20 + 50
			c.cleanbonus = (a0.strength * g_profile.myclub.strength) / 10 + 50
		Case 3
			c.goalbonus = (a0.strength * g_profile.myclub.strength) / 15 + 50
			c.assistbonus = (a0.strength * g_profile.myclub.strength) / 15 + 50
			c.cleanbonus = 0
		Case 4
			c.goalbonus = (a0.strength * g_profile.myclub.strength) / 20 + 50
			c.assistbonus = (a0.strength * g_profile.myclub.strength) / 10 + 50
			c.cleanbonus = 0
		Case 5
			c.goalbonus = (a0.strength * g_profile.myclub.strength) / 10 + 50
			c.assistbonus = (a0.strength * g_profile.myclub.strength) / 20
			c.cleanbonus = 0
	End Select

	c.signingfee = a0.strength * a0.strength
	If a0.strength >= 90
		c.signingfee = c.signingfee * 10
		c.goalbonus = c.goalbonus * 3.0
		c.assistbonus = c.assistbonus * 3.0
		c.cleanbonus = c.cleanbonus * 3.0
	ElseIf a0.strength >= 86
		c.signingfee = c.signingfee * 6
		c.goalbonus = c.goalbonus * 2.0
		c.assistbonus = c.assistbonus * 2.0
		c.cleanbonus = c.cleanbonus * 2.0
	ElseIf a0.strength >= 83
		c.signingfee = c.signingfee * 4
		c.goalbonus = c.goalbonus * 1.5
		c.assistbonus = c.assistbonus * 1.5
		c.cleanbonus = c.cleanbonus * 1.5
	ElseIf a0.strength >= 80
		c.signingfee = c.signingfee * 2
		c.goalbonus = c.goalbonus * 1.25
		c.assistbonus = c.assistbonus * 1.25
		c.cleanbonus = c.cleanbonus * 1.25
	ElseIf a0.strength >= 75
		c.signingfee = c.signingfee * 1.5
	Else
		c.goalbonus = c.goalbonus * 0.5
		c.assistbonus = c.assistbonus * 0.5
		c.cleanbonus = c.cleanbonus * 0.5
	EndIf

	c.goalbonus = c.goalbonus / 100
	c.assistbonus = c.assistbonus / 100
	c.cleanbonus = c.cleanbonus / 100
	c.goalbonus = c.goalbonus * 100
	c.assistbonus = c.assistbonus * 100
	c.cleanbonus = c.cleanbonus * 100

	If a0.id = g_profile.clubid And c.wage < g_profile.contractwage And g_profile.GetAge() < 31
		c.wage = g_profile.contractwage
	EndIf
	c.wage = c.wage / 100
	c.wage = c.wage * 100
	If c.wage < 500 Then c.wage = 500

	If g_profile.date.sdate > g_profile.contractexpires And g_profile.clubid <> c.club.id
		c.signingfee = c.signingfee * 4
	EndIf
	c.signingfee = c.signingfee / 1000
	c.signingfee = c.signingfee * 1000
	If c.signingfee < 500 Then c.signingfee = 500
EndIf

Return c
