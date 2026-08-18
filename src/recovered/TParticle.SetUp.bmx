' TParticle.SetUp
' VA 0x0056F748   155 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_particles:TList
'!Global g_particleImage:TImage
'!Global g_particleSound:TSound
g_particles = CreateList()
g_particleImage = LoadImageChecked("EngineMedia/Match/Other/Star.png", -1)
MidHandleImage(g_particleImage)
g_particleSound = LoadSoundChecked("EngineMedia/Match/Sounds/Skill.ogg", 0)
