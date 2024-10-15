extends Node2D

#region map stuffs
@onready var player_scene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var exit_scene = preload("res://interactables/scenes/exit.tscn")
@onready var enemy1_scene = preload("res://Entities/Scenes/Enemies/enemy_1.tscn")
@onready var enemy2_scene = preload("res://Entities/Scenes/Enemies/enemy_2.tscn")
@onready var enemy3_scene = preload("res://Entities/Scenes/Enemies/enemy_3.tscn")
@onready var enemy4_scene = preload("res://Entities/Scenes/Enemies/enemy_4.tscn")
@onready var silverspikes_scene = preload("res://interactables/scenes/dead_area.tscn")
@onready var redspikes_scene = preload("res://interactables/scenes/redspikes.tscn")
@onready var menu_scene = preload("res://Levels/menu.tscn")

@onready var spikes_1 = $spikes1
@onready var spikes_2 = $spikes2
@onready var spikes_3 = $spikes3
@onready var spikes_4 = $spikes4
@onready var spikes_5 = $spikes5
@onready var spikes_6 = $spikes6
@onready var spikes_7 = $spikes7
@onready var spikes_8 = $spikes8
@onready var spikes_9 = $spikes9
@onready var spikes_10 = $spikes10
@onready var spikes_11 = $spikes11
@onready var spikes_12 = $spikes12
@onready var spikes_13 = $spikes13
@onready var spikes_14 = $spikes14
@onready var spikes_15 = $spikes15
@onready var spikes_16 = $spikes16
@onready var spikes_17 = $spikes17
@onready var spikes_18 = $spikes18
@onready var spikes_19 = $spikes19
@onready var spikes_20 = $spikes20
@onready var spikes_21 = $spikes21
@onready var spikes_22 = $spikes22
@onready var spikes_23 = $spikes23
@onready var spikes_24 = $spikes24
@onready var spikes_25 = $spikes25
@onready var spikes_26 = $spikes26
@onready var spikes_27 = $spikes27
@onready var spikes_28 = $spikes28
@onready var spikes_29 = $spikes29
@onready var spikes_30 = $spikes30
@onready var spikes_31 = $spikes31
@onready var spikes_32 = $spikes32
@onready var spikes_33 = $spikes33
@onready var spikes_34 = $spikes34
@onready var spikes_35 = $spikes35
@onready var spikes_36 = $spikes36
@onready var spikes_37 = $spikes37
@onready var spikes_38 = $spikes38
@onready var spikes_39 = $spikes39
@onready var spikes_40 = $spikes40
@onready var spikes_41 = $spikes41
@onready var spikes_42 = $spikes42
@onready var spikes_43 = $spikes43
@onready var spikes_44 = $spikes44
@onready var spikes_45 = $spikes45
@onready var spikes_46 = $spikes46
@onready var spikes_47 = $spikes47
@onready var spikes_48 = $spikes48
@onready var spikes_49 = $spikes49
@onready var spikes_50 = $spikes50
@onready var spikes_51 = $spikes51
@onready var spikes_52 = $spikes52
@onready var spikes_53 = $spikes53
@onready var spikes_54 = $spikes54
@onready var spikes_55 = $spikes55
@onready var spikes_56 = $spikes56
@onready var spikes_57 = $spikes57
@onready var spikes_58 = $spikes58
@onready var spikes_59 = $spikes59
@onready var spikes_60 = $spikes60
@onready var spikes_61 = $spikes61
@onready var spikes_62 = $spikes62
@onready var spikes_63 = $spikes63
@onready var spikes_64 = $spikes64
@onready var spikes_65 = $spikes65
@onready var spikes_66 = $spikes66
@onready var spikes_67 = $spikes67
@onready var spikes_68 = $spikes68
@onready var spikes_69 = $spikes69
@onready var spikes_70 = $spikes70
@onready var spikes_71 = $spikes71
@onready var spikes_72 = $spikes72
@onready var spikes_73 = $spikes73
@onready var spikes_74 = $spikes74
@onready var spikes_75 = $spikes75
@onready var spikes_76 = $spikes76
@onready var spikes_77 = $spikes77
@onready var spikes_78 = $spikes78
@onready var spikes_79 = $spikes79
@onready var spikes_80 = $spikes80
@onready var spikes_81 = $spikes81
@onready var spikes_82 = $spikes82
@onready var spikes_83 = $spikes83
@onready var spikes_84 = $spikes84
@onready var spikes_85 = $spikes85
@onready var spikes_86 = $spikes86
@onready var spikes_87 = $spikes87
@onready var spikes_88 = $spikes88
@onready var spikes_89 = $spikes89
@onready var spikes_90 = $spikes90
@onready var spikes_91 = $spikes91
@onready var spikes_92 = $spikes92
@onready var spikes_93 = $spikes93
@onready var spikes_94 = $spikes94
@onready var spikes_95 = $spikes95
@onready var spikes_96 = $spikes96
@onready var spikes_97 = $spikes97
@onready var spikes_98 = $spikes98
@onready var spikes_99 = $spikes99
@onready var spikes_100 = $spikes100
@onready var spikes_101 = $spikes101
@onready var spikes_102 = $spikes102
@onready var spikes_103 = $spikes103
@onready var spikes_104 = $spikes104
@onready var spikes_105 = $spikes105
@onready var spikes_106 = $spikes106
@onready var spikes_107 = $spikes107
@onready var spikes_108 = $spikes108
@onready var spikes_109 = $spikes109
@onready var spikes_110 = $spikes110
@onready var spikes_111 = $spikes111
@onready var spikes_112 = $spikes112
@onready var spikes_113 = $spikes113
@onready var spikes_114 = $spikes114
@onready var spikes_115 = $spikes115
@onready var spikes_116 = $spikes116
@onready var spikes_117 = $spikes117
@onready var spikes_118 = $spikes118
@onready var spikes_119 = $spikes119
@onready var spikes_120 = $spikes120
@onready var spikes_121 = $spikes121
@onready var spikes_122 = $spikes122
@onready var spikes_123 = $spikes123
@onready var spikes_124 = $spikes124
@onready var spikes_125 = $spikes125
@onready var spikes_126 = $spikes126
@onready var spikes_127 = $spikes127
@onready var spikes_128 = $spikes128
@onready var spikes_129 = $spikes129
@onready var spikes_130 = $spikes130
@onready var spikes_131 = $spikes131
@onready var spikes_132 = $spikes132
@onready var spikes_133 = $spikes133
@onready var spikes_134 = $spikes134
@onready var spikes_135 = $spikes135
@onready var spikes_136 = $spikes136
@onready var spikes_137 = $spikes137
@onready var spikes_138 = $spikes138
@onready var spikes_139 = $spikes139
@onready var spikes_140 = $spikes140
@onready var spikes_141 = $spikes141
@onready var spikes_142 = $spikes142
@onready var spikes_143 = $spikes143
@onready var spikes_144 = $spikes144
@onready var spikes_145 = $spikes145
@onready var spikes_146 = $spikes146
@onready var spikes_147 = $spikes147
@onready var spikes_148 = $spikes148
@onready var spikes_149 = $spikes149
@onready var spikes_150 = $spikes150
@onready var spikes_151 = $spikes151
@onready var spikes_152 = $spikes152
@onready var spikes_153 = $spikes153
@onready var spikes_154 = $spikes154
@onready var spikes_155 = $spikes155
@onready var spikes_156 = $spikes156
@onready var spikes_157 = $spikes157
@onready var spikes_158 = $spikes158
@onready var spikes_159 = $spikes159
@onready var spikes_160 = $spikes160
@onready var spikes_161 = $spikes161
@onready var spikes_162 = $spikes162
@onready var spikes_163 = $spikes163
@onready var spikes_164 = $spikes164
@onready var spikes_165 = $spikes165
@onready var spikes_166 = $spikes166
@onready var spikes_167 = $spikes167
@onready var spikes_168 = $spikes168
@onready var spikes_169 = $spikes169
@onready var spikes_170 = $spikes170
@onready var spikes_171 = $spikes171
@onready var spikes_172 = $spikes172
@onready var spikes_173 = $spikes173
@onready var spikes_174 = $spikes174
@onready var spikes_175 = $spikes175
@onready var spikes_176 = $spikes176
@onready var spikes_177 = $spikes177
@onready var spikes_178 = $spikes178
@onready var spikes_179 = $spikes179
@onready var spikes_180 = $spikes180
@onready var spikes_181 = $spikes181
@onready var spikes_182 = $spikes182
@onready var spikes_183 = $spikes183
@onready var spikes_184 = $spikes184
@onready var spikes_185 = $spikes185
@onready var spikes_186 = $spikes186
@onready var spikes_187 = $spikes187
@onready var spikes_188 = $spikes188
@onready var spikes_189 = $spikes189
@onready var spikes_190 = $spikes190
@onready var spikes_191 = $spikes191
@onready var spikes_192 = $spikes192
@onready var spikes_193 = $spikes193
@onready var spikes_194 = $spikes194
@onready var spikes_195 = $spikes195
@onready var spikes_196 = $spikes196
@onready var spikes_197 = $spikes197
@onready var spikes_198 = $spikes198
@onready var spikes_199 = $spikes199
@onready var spikes_200 = $spikes200
@onready var spikes_201 = $spikes201
@onready var spikes_202 = $spikes202
@onready var spikes_203 = $spikes203
@onready var spikes_204 = $spikes204
@onready var spikes_205 = $spikes205
@onready var spikes_206 = $spikes206
@onready var spikes_207 = $spikes207
@onready var spikes_208 = $spikes208
@onready var spikes_209 = $spikes209
@onready var spikes_210 = $spikes210
@onready var spikes_211 = $spikes211
@onready var spikes_212 = $spikes212
@onready var spikes_213 = $spikes213
@onready var spikes_214 = $spikes214
@onready var spikes_215 = $spikes215
@onready var spikes_216 = $spikes216
@onready var spikes_217 = $spikes217
@onready var spikes_218 = $spikes218
@onready var spikes_219 = $spikes219
@onready var spikes_220 = $spikes220
@onready var spikes_221 = $spikes221
@onready var spikes_222 = $spikes222
@onready var spikes_223 = $spikes223
@onready var spikes_224 = $spikes224
@onready var spikes_225 = $spikes225
@onready var spikes_226 = $spikes226
@onready var spikes_227 = $spikes227
@onready var spikes_228 = $spikes228
@onready var spikes_229 = $spikes229
@onready var spikes_230 = $spikes230
@onready var spikes_231 = $spikes231
@onready var spikes_232 = $spikes232
@onready var spikes_233 = $spikes233
@onready var spikes_234 = $spikes234
@onready var spikes_235 = $spikes235
@onready var spikes_236 = $spikes236
@onready var spikes_237 = $spikes237
@onready var spikes_238 = $spikes238
@onready var spikes_239 = $spikes239
@onready var spikes_240 = $spikes240
@onready var spikes_241 = $spikes241
@onready var spikes_242 = $spikes242
@onready var spikes_243 = $spikes243
@onready var spikes_244 = $spikes244
@onready var spikes_245 = $spikes245
@onready var spikes_246 = $spikes246
@onready var spikes_247 = $spikes247
@onready var spikes_248 = $spikes248
@onready var spikes_249 = $spikes249
@onready var spikes_250 = $spikes250
@onready var spikes_251 = $spikes251
@onready var spikes_252 = $spikes252
@onready var spikes_253 = $spikes253
@onready var spikes_254 = $spikes254
@onready var spikes_255 = $spikes255
@onready var spikes_256 = $spikes256
@onready var spikes_257 = $spikes257
@onready var spikes_258 = $spikes258
@onready var spikes_259 = $spikes259
@onready var spikes_260 = $spikes260
@onready var spikes_261 = $spikes261
@onready var spikes_262 = $spikes262
@onready var spikes_263 = $spikes263
@onready var spikes_264 = $spikes264
@onready var spikes_265 = $spikes265
@onready var spikes_266 = $spikes266
@onready var spikes_267 = $spikes267
@onready var spikes_268 = $spikes268
@onready var spikes_269 = $spikes269
@onready var spikes_270 = $spikes270
@onready var spikes_271 = $spikes271
@onready var spikes_272 = $spikes272
@onready var spikes_273 = $spikes273
@onready var spikes_274 = $spikes274
@onready var spikes_275 = $spikes275
@onready var spikes_276 = $spikes276
@onready var spikes_277 = $spikes277
@onready var spikes_278 = $spikes278
@onready var spikes_279 = $spikes279
@onready var spikes_280 = $spikes280
@onready var spikes_281 = $spikes281
@onready var spikes_282 = $spikes282
@onready var spikes_283 = $spikes283
@onready var spikes_284 = $spikes284
@onready var spikes_285 = $spikes285
@onready var spikes_286 = $spikes286
@onready var spikes_287 = $spikes287
@onready var spikes_288 = $spikes288
@onready var spikes_289 = $spikes289
@onready var spikes_290 = $spikes290
@onready var spikes_291 = $spikes291
@onready var spikes_292 = $spikes292
@onready var spikes_293 = $spikes293
@onready var spikes_294 = $spikes294
@onready var spikes_295 = $spikes295
@onready var spikes_296 = $spikes296
@onready var spikes_297 = $spikes297
@onready var spikes_298 = $spikes298
@onready var spikes_299 = $spikes299
@onready var spikes_300 = $spikes300
@onready var spikes_301 = $spikes301
@onready var spikes_302 = $spikes302
@onready var spikes_303 = $spikes303
@onready var spikes_304 = $spikes304
@onready var spikes_305 = $spikes305
@onready var spikes_306 = $spikes306
@onready var spikes_307 = $spikes307
@onready var spikes_308 = $spikes308
@onready var spikes_309 = $spikes309
@onready var spikes_310 = $spikes310
@onready var spikes_311 = $spikes311
@onready var spikes_312 = $spikes312
@onready var spikes_313 = $spikes313
@onready var spikes_314 = $spikes314
@onready var spikes_315 = $spikes315
@onready var spikes_316 = $spikes316
@onready var spikes_317 = $spikes317
@onready var spikes_318 = $spikes318
@onready var spikes_319 = $spikes319
@onready var spikes_320 = $spikes320

#endregion

@onready var intermission_level = $"."
@onready var gui = $GUI_intermission
@onready var player_spawn = $player_spawn

@onready var exit = $exit
@onready var main_mouse_icon = $CanvasLayer/main_mouse_icon
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var pause_menu_canvas = $CanvasLayer
@onready var spikes_timer = $spikes_timer


@onready var loading_screen_canvas = $CanvasLayer2
@onready var loading_screen_intermission = $CanvasLayer2/loading_screen_intermission
@onready var next_level_timer = $next_level_timer

@onready var tilemap = $TileMap
var spike

var spikes_array
var enemies_array
var ground_layer = 0
var change_scenes_once = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	player_data.game_active = true
	player_data.levels = 19
	player_data.hurt_ready = true
	player_data.reached_exit = false
#region spikes array
	spikes_array = [spikes_1, 
		spikes_2, 
		spikes_3,
		spikes_4, 
		spikes_5,
		spikes_6, 
		spikes_7,
		spikes_8, 
		spikes_9,
		spikes_10, 
		spikes_11,
		spikes_12,
		spikes_13,
		spikes_14,
		spikes_15,
		spikes_16,
		spikes_17,
		spikes_18,
		spikes_19,
		spikes_20,
		spikes_21,
		spikes_22,
		spikes_23,
		spikes_24,
		spikes_25,
		spikes_26,
		spikes_27,
		spikes_28,
		spikes_29,
		spikes_30,
		spikes_31,
		spikes_32,
		spikes_33,
		spikes_34,
		spikes_35,
		spikes_36,
		spikes_37,
		spikes_38,
		spikes_39,
		spikes_40,
		spikes_41,
		spikes_42,
		spikes_43,
		spikes_44,
		spikes_45,
		spikes_46,
		spikes_47,
		spikes_48,
		spikes_49,
		spikes_40,
		spikes_50,
		spikes_51,
		spikes_52,
		spikes_53,
		spikes_54,
		spikes_55,
		spikes_56,
		spikes_57,
		spikes_58,
		spikes_59,
		spikes_60,
		spikes_61,
		spikes_62,
		spikes_63,
		spikes_64,
		spikes_65,
		spikes_66,
		spikes_67,
		spikes_68,
		spikes_69,
		spikes_70,
		spikes_71,
		spikes_72,
		spikes_73,
		spikes_74,
		spikes_75,
		spikes_76,
		spikes_77,
		spikes_78,
		spikes_79,
		spikes_80,
		spikes_81,
		spikes_82,
		spikes_83,
		spikes_84,
		spikes_85,
		spikes_86,
		spikes_87,
		spikes_88,
		spikes_89,
		spikes_90,
		spikes_91,
		spikes_92,
		spikes_93,
		spikes_94,
		spikes_95,
		spikes_96,
		spikes_97,
		spikes_98,
		spikes_99,
		spikes_100,
		spikes_101,
		spikes_102,
		spikes_103,
		spikes_104,
		spikes_105,
		spikes_106,
		spikes_107,
		spikes_108,
		spikes_109,
		spikes_110,
		spikes_111,
		spikes_112,
		spikes_113,
		spikes_114,
		spikes_115,
		spikes_116,
		spikes_117,
		spikes_118,
		spikes_119,
		spikes_120,
		spikes_121,
		spikes_122,
		spikes_123,
		spikes_124,
		spikes_125,
		spikes_126,
		spikes_127,
		spikes_128,
		spikes_129,
		spikes_130,
		spikes_131,
		spikes_132,
		spikes_133,
		spikes_134,
		spikes_135,
		spikes_136,
		spikes_137,
		spikes_138,
		spikes_139,
		spikes_140,
		spikes_141,
		spikes_142,
		spikes_143,
		spikes_144,
		spikes_145,
		spikes_146,
		spikes_147,
		spikes_148,
		spikes_149,
		spikes_150,
		spikes_151,
		spikes_152,
		spikes_153,
		spikes_154,
		spikes_155,
		spikes_156,
		spikes_157,
		spikes_158,
		spikes_159,
		spikes_160,
		spikes_161,
		spikes_162,
		spikes_163,
		spikes_164,
		spikes_165,
		spikes_166,
		spikes_167,
		spikes_168,
		spikes_169,
		spikes_170,
		spikes_171,
		spikes_172,
		spikes_173,
		spikes_174,
		spikes_175,
		spikes_176,
		spikes_177,
		spikes_178,
		spikes_179,
		spikes_180,
		spikes_181,
		spikes_182,
		spikes_183,
		spikes_184,
		spikes_185,
		spikes_186,
		spikes_187,
		spikes_188,
		spikes_189,
		spikes_190,
		spikes_191,
		spikes_192,
		spikes_193,
		spikes_194,
		spikes_195,
		spikes_196,
		spikes_197,
		spikes_198,
		spikes_199,
		spikes_200,
		spikes_201,
		spikes_202,
		spikes_203,
		spikes_204,
		spikes_205,
		spikes_206,
		spikes_207,
		spikes_208,
		spikes_209,
		spikes_210,
		spikes_211,
		spikes_212,
		spikes_213,
		spikes_214,
		spikes_215,
		spikes_216,
		spikes_217,
		spikes_218,
		spikes_219,
		spikes_220,
		spikes_221,
		spikes_222,
		spikes_223,
		spikes_224,
		spikes_225,
		spikes_226,
		spikes_227,
		spikes_228,
		spikes_229,
		spikes_230,
		spikes_231,
		spikes_232,
		spikes_233,
		spikes_234,
		spikes_235,
		spikes_236,
		spikes_237,
		spikes_238,
		spikes_239,
		spikes_240,
		spikes_241,
		spikes_242,
		spikes_243,
		spikes_244,
		spikes_245,
		spikes_246,
		spikes_247,
		spikes_248,
		spikes_249,
		spikes_250,
		spikes_251,
		spikes_252,
		spikes_253,
		spikes_254,
		spikes_255,
		spikes_256,
		spikes_257,
		spikes_208,
		spikes_259,
		spikes_260,
		spikes_261,
		spikes_262,
		spikes_263,
		spikes_264,
		spikes_265,
		spikes_266,
		spikes_267,
		spikes_268,
		spikes_269,
		spikes_270,
		spikes_271,
		spikes_272,
		spikes_273,
		spikes_274,
		spikes_275,
		spikes_276,
		spikes_277,
		spikes_278,
		spikes_279,
		spikes_280,
		spikes_281,
		spikes_282,
		spikes_283,
		spikes_284,
		spikes_285,
		spikes_286,
		spikes_287,
		spikes_288,
		spikes_289,
		spikes_290,
		spikes_291,
		spikes_292,
		spikes_293,
		spikes_294,
		spikes_295,
		spikes_296,
		spikes_297,
		spikes_298,
		spikes_299,
		spikes_300
		]
		
#region enemies_array

	enemies_array = [spikes_1, 
		spikes_2, 
		spikes_3,
		spikes_4, 
		spikes_5,
		spikes_6, 
		spikes_7,
		spikes_8, 
		spikes_9,
		spikes_10, 
		spikes_11,
		spikes_12,
		spikes_13,
		spikes_14,
		spikes_15,
		spikes_16,
		spikes_17,
		spikes_18,
		spikes_19,
		spikes_20,
		spikes_21,
		spikes_22,
		spikes_23,
		spikes_24,
		spikes_25,
		spikes_26,
		spikes_27,
		spikes_28,
		spikes_29,
		spikes_30,
		spikes_31,
		spikes_32,
		spikes_33,
		spikes_34,
		spikes_35,
		spikes_36,
		spikes_37,
		spikes_38,
		spikes_39,
		spikes_40,
		spikes_41,
		spikes_42,
		spikes_43,
		spikes_44,
		spikes_45,
		spikes_46,
		spikes_47,
		spikes_48,
		spikes_49,
		spikes_40,
		spikes_50,
		spikes_51,
		spikes_52,
		spikes_53,
		spikes_54,
		spikes_55,
		spikes_56,
		spikes_57,
		spikes_58,
		spikes_59,
		spikes_60,
		spikes_61,
		spikes_62,
		spikes_63,
		spikes_64,
		spikes_65,
		spikes_66,
		spikes_67,
		spikes_68,
		spikes_69,
		spikes_70,
		spikes_71,
		spikes_72,
		spikes_73,
		spikes_74,
		spikes_75,
		spikes_76,
		spikes_77,
		spikes_78,
		spikes_79,
		spikes_80,
		spikes_81,
		spikes_82,
		spikes_83,
		spikes_84,
		spikes_85,
		spikes_86,
		spikes_87,
		spikes_88,
		spikes_89,
		spikes_90,
		spikes_91,
		spikes_92,
		spikes_93,
		spikes_94,
		spikes_95,
		spikes_96,
		spikes_97,
		spikes_98,
		spikes_99,
		spikes_100,
		spikes_101,
		spikes_102,
		spikes_103,
		spikes_104,
		spikes_105,
		spikes_106,
		spikes_107,
		spikes_108,
		spikes_109,
		spikes_110,
		spikes_111,
		spikes_112,
		spikes_113,
		spikes_114,
		spikes_115,
		spikes_116,
		spikes_117,
		spikes_118,
		spikes_119,
		spikes_120,
		spikes_121,
		spikes_122,
		spikes_123,
		spikes_124,
		spikes_125,
		spikes_126,
		spikes_127,
		spikes_128,
		spikes_129,
		spikes_130,
		spikes_131,
		spikes_132,
		spikes_133,
		spikes_134,
		spikes_135,
		spikes_136,
		spikes_137,
		spikes_138,
		spikes_139,
		spikes_140,
		spikes_141,
		spikes_142,
		spikes_143,
		spikes_144,
		spikes_145,
		spikes_146,
		spikes_147,
		spikes_148,
		spikes_149,
		spikes_150,
		spikes_151,
		spikes_152,
		spikes_153,
		spikes_154,
		spikes_155,
		spikes_156,
		spikes_157,
		spikes_158,
		spikes_159,
		spikes_160,
		spikes_161,
		spikes_162,
		spikes_163,
		spikes_164,
		spikes_165,
		spikes_166,
		spikes_167,
		spikes_168,
		spikes_169,
		spikes_170,
		spikes_171,
		spikes_172,
		spikes_173,
		spikes_174,
		spikes_175,
		spikes_176,
		spikes_177,
		spikes_178,
		spikes_179,
		spikes_180,
		spikes_181,
		spikes_182,
		spikes_183,
		spikes_184,
		spikes_185,
		spikes_186,
		spikes_187,
		spikes_188,
		spikes_189,
		spikes_190,
		spikes_191,
		spikes_192,
		spikes_193,
		spikes_194,
		spikes_195,
		spikes_196,
		spikes_197,
		spikes_198,
		spikes_199,
		spikes_200,
		spikes_201,
		spikes_202,
		spikes_203,
		spikes_204,
		spikes_205,
		spikes_206,
		spikes_207,
		spikes_208,
		spikes_209,
		spikes_210,
		spikes_211,
		spikes_212,
		spikes_213,
		spikes_214,
		spikes_215,
		spikes_216,
		spikes_217,
		spikes_218,
		spikes_219,
		spikes_220,
		spikes_221,
		spikes_222,
		spikes_223,
		spikes_224,
		spikes_225,
		spikes_226,
		spikes_227,
		spikes_228,
		spikes_229,
		spikes_230,
		spikes_231,
		spikes_232,
		spikes_233,
		spikes_234,
		spikes_235,
		spikes_236,
		spikes_237,
		spikes_238,
		spikes_239,
		spikes_240,
		spikes_241,
		spikes_242,
		spikes_243,
		spikes_244,
		spikes_245,
		spikes_246,
		spikes_247,
		spikes_248,
		spikes_249,
		spikes_250,
		spikes_251,
		spikes_252,
		spikes_253,
		spikes_254,
		spikes_255,
		spikes_256,
		spikes_257,
		spikes_208,
		spikes_259,
		spikes_260,
		spikes_261,
		spikes_262,
		spikes_263,
		spikes_264,
		spikes_265,
		spikes_266,
		spikes_267,
		spikes_268,
		spikes_269,
		spikes_270,
		spikes_271,
		spikes_272,
		spikes_273,
		spikes_274,
		spikes_275,
		spikes_276,
		spikes_277,
		spikes_278,
		spikes_279,
		spikes_280,
		spikes_281,
		spikes_282,
		spikes_283,
		spikes_284,
		spikes_285,
		spikes_286,
		spikes_287,
		spikes_288,
		spikes_289,
		spikes_290,
		spikes_291,
		spikes_292,
		spikes_293,
		spikes_294,
		spikes_295,
		spikes_296,
		spikes_297,
		spikes_298,
		spikes_299,
		spikes_300
		]
#endregion
		
#endregion

	generate_level()
	
	spikes_timer.start()
	ThemePlayer.theme_grand()
	
	pause_menu.exit_pause_menu.connect(on_exit_pause_menu)
	pause_menu.enter_pause_menu.connect(on_enter_pause_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player_data.player_is_dead:
		loading_screen_intermission.reset_next_scene()
		
	if player_data.toggle_loading_screen:
		intermission_level.visible = false
		gui.visible = false
		pause_menu.visible = false
		if loading_screen_canvas.layer < 4:
			loading_screen_canvas.layer = 4
			loading_screen_canvas.visible = true
			loading_screen_intermission.visible = true
			loading_screen_intermission.z_index = 10

		if change_scenes_once == 0:
			if player_data.player_is_dead:
				loading_screen_intermission.reset_next_scene()
			else:
				loading_screen_intermission.load_next_scene()
			next_level_timer.start()
			change_scenes_once += 1
			player_data.toggle_loading_screen = false
	
	ThemePlayer.theme_final_stop()
	ThemePlayer.theme_skytowersummit_stop()
	ThemePlayer.theme_magma_stop()
	ThemePlayer.theme_makuhita_stop()
	ThemePlayer.theme_silentchasm_stop()
	ThemePlayer.theme_steel_stop()
	ThemePlayer.theme_lapis_stop()
	ThemePlayer.theme_sinister_stop()
	ThemePlayer.theme_blazepeak_stop()
	ThemePlayer.theme_questionairre_stop()
	ThemePlayer.theme_fileselect_stop()
	ThemePlayer.theme_ninetales_stop()
	ThemePlayer.theme_sinister_stop()

func generate_level():
	instance_player()

func instance_player():
	var player = player_scene.instantiate()
	player.position = player_spawn.position
	add_child(player)
	
func on_exit_pause_menu():
	pause_menu_canvas.visible = false
	pause_menu.visible = false
	main_mouse_icon.visible = false
	pause_menu_canvas.layer = -4
	
func on_enter_pause_menu():
	pause_menu_canvas.visible = true
	pause_menu.visible = true
	main_mouse_icon.visible = true
	pause_menu_canvas.layer = 4


func _on_next_level_timer_timeout():
	intermission_level.visible = true
	gui.visible = true
	pause_menu.visible = true
	loading_screen_canvas.layer = -10
	loading_screen_canvas.visible = false
	loading_screen_intermission.visible = false
	loading_screen_intermission.z_index = -10
	player_data.toggle_loading_screen = false
	change_scenes_once = 0

func _on_spikes_timer_timeout():
	if spikes_array.size()-100 >= 1:
		var spike_type = randi_range(0, 1)
		var spike_position_source = randi_range(0, spikes_array.size()-100)
		var spike_source = spikes_array.pop_at(spike_position_source)
		match spike_type:
			0: 
				spike = silverspikes_scene.instantiate()
			1: 
				spike = redspikes_scene.instantiate()
		spike.position = spike_source.position
		spikes_array.remove_at(spike_position_source)
		add_child(spike)


func _on_enemy_spawn_timeout():
	var enemy
	var enemy_type = randi_range(0, 3)
	var enemy_position
	match enemy_type:
		0:
			enemy = enemy1_scene.instantiate()
			for i in range(8):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
		1:
			enemy = enemy2_scene.instantiate()
			for i in range(6):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
		2:
			enemy = enemy3_scene.instantiate()
			for i in range(2):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
		3:
			enemy = enemy4_scene.instantiate()
			for i in range(4):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
	$enemy_spawn.start()
	
	
	
