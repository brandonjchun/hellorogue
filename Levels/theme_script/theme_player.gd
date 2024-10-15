extends Node

@onready var tiny = $tiny
@onready var wizards = $wizards
@onready var magma = $magma
@onready var grand = $grand
@onready var mapbasic = $mapbasic
@onready var goodfight = $goodfight
@onready var steel = $steel
@onready var sinister = $sinister
@onready var plumus = $plumus
@onready var final = $final
@onready var fileselect = $fileselect
@onready var questionairre = $questionairre
@onready var bossbattle = $bossbattle
@onready var makuhita = $makuhita
@onready var silentchasm = $silentchasm
@onready var ninetales = $ninetales
@onready var lapis = $lapis
@onready var blazepeak = $blazepeak
@onready var skytowersummit = $skytowersummit

func theme_tiny():
	if not tiny.playing:
		tiny.play()
		
func theme_tiny_stop():
	tiny.stream_paused = true

func theme_wizards():
	if not wizards.playing:
		wizards.play()
		
func theme_wizards_stop():
	wizards.stream_paused = true

func theme_magma():
	if not magma.playing:
		magma.play()
		
func theme_magma_stop():
	magma.stream_paused = true
	
func theme_grand():
	if not grand.playing:
		grand.play()
		
func theme_grand_stop():
	grand.stream_paused = true
	
func theme_mapbasic():
	if not mapbasic.playing:
		mapbasic.play()
		
func theme_mapbasic_stop():
	mapbasic.stream_paused = true
	
func theme_goodfight():
	if not goodfight.playing:
		goodfight.play()
		
func theme_goodfight_stop():
	goodfight.stream_paused = true
	
func theme_steel():
	if not steel.playing:
		steel.play()
		
func theme_steel_stop():
	steel.stream_paused = true
	
func theme_sinister():
	if not sinister.playing:
		sinister.play()
		
func theme_sinister_stop():
	sinister.stream_paused = true
	
func theme_plumus():
	if not plumus.playing:
		plumus.play()
		
func theme_plumus_stop():
	plumus.stream_paused = true
	
func theme_final():
	if not final.playing:
		final.play()
		
func theme_final_stop():
	final.stream_paused = true
	
	

func theme_fileselect():
	if not fileselect.playing:
		fileselect.play()
		
func theme_fileselect_stop():
	fileselect.stream_paused = true
	
	
func theme_questionairre():
	if not questionairre.playing:
		questionairre.play()
		
func theme_questionairre_stop():
	questionairre.stream_paused = true
	
	
func theme_bossbattle():
	if not bossbattle.playing:
		bossbattle.play()
		
func theme_bossbattle_stop():
	bossbattle.stream_paused = true
	
	
func theme_makuhita():
	if not makuhita.playing:
		makuhita.play()
		
func theme_makuhita_stop():
	makuhita.stream_paused = true
	
	
func theme_silentchasm():
	if not silentchasm.playing:
		silentchasm.play()
		
func theme_silentchasm_stop():
	silentchasm.stream_paused = true
	
	
func theme_ninetales():
	if not ninetales.playing:
		ninetales.play()
		
func theme_ninetales_stop():
	ninetales.stream_paused = true
	
	
func theme_lapis():
	if not lapis.playing:
		lapis.play()
		
func theme_lapis_stop():
	lapis.stream_paused = true
	
	
func theme_blazepeak():
	if not blazepeak.playing:
		blazepeak.play()
		
func theme_blazepeak_stop():
	blazepeak.stream_paused = true
	
	
func theme_skytowersummit():
	if not skytowersummit.playing:
		skytowersummit.play()
		
func theme_skytowersummit_stop():
	skytowersummit.stream_paused = true

func play_heal():
	$heal.play()

func play_ammo():
	$ammo.play()
	
func play_e1_death():
	$e1_death.play()
	
func play_e2_death():
	$e2_death.play()

func play_e3_bullet():
	$e3_bullet.play()
	
func play_e3_death():
	$e4_death.play()
	
func play_e4_bullet():
	$e4_bullet.play()
	
func play_e4_death():
	$e3_death.play()
	
	
