module Octane.Data.Antennas where

import Data.Function ((&))

import qualified Data.Bimap as Bimap
import qualified Data.Text as StrictText


-- | A one-to-one mapping between antenna IDs and their names.
antennas :: Bimap.Bimap Int StrictText.Text
antennas =
    [ ("None", 0)
    , ("(Beta Reward) Gold Nugget", 6)
    , ("8-Ball", 1)
    , ("Alien", 753)
    , ("Balloon Dog", 752)
    , ("Batman", 804)
    , ("Blue Chequered Flag", 284)
    , ("Bomb Pole", 614)
    , ("Calavera", 574) -- DOTDSkull
    , ("Camo Flag", 285)
    , ("Candle", 757)
    , ("Candy Cane", 649)
    , ("Chick Magnet", 392)
    , ("Cupcake", 393)
    , ("Dave's Bread", 391)
    , ("deadmau5", 781) -- Mau5
    , ("Disco Ball", 800)
    , ("Disconnect", 394)
    , ("Dollar Sign", 3)
    , ("Donut", 395)
    , ("Foam Finger", 398)
    , ("Fuzzy Brute", 593) -- FurballFrakenstein
    , ("Fuzzy Vamp", 595) -- FurballVampire
    , ("Genie Lamp", 798)
    , ("Gingerbread Man", 5)
    , ("Heart", 7)
    , ("Holiday Gift", 650) -- ChristmasGift
    , ("Horseshoe", 8)
    , ("Hula Girl", 762)
    , ("Jolly Roger", 217) -- Pirate
    , ("Lightning Bolt", 9)
    , ("Moai", 522)
    , ("Parrot", 750)
    , ("Peace", 11)
    , ("Piñata", 400)
    , ("Planetoid", 12) -- Saturn
    , ("Radioactive", 615) -- RadiationSymbol
    , ("Rainbow", 490)
    , ("Reddit Snoo", 629)
    , ("Retro Ball - Urban", 575)
    , ("Retro Ball - Utopia", 576)
    , ("Retro Ball - Wasteland", 577)
    , ("Rocket", 755)
    , ("Rose", 785)
    , ("Rubber Duckie", 779)
    , ("Safety Flag", 286) -- OrangeNylon
    , ("Skull", 13)
    , ("Smiley", 14)
    , ("Snowman", 15)
    , ("Soccer Ball", 16)
    , ("Star", 17)
    , ("Sunflower", 786)
    , ("Superman", 805)
    , ("Sweet Tooth", 18)
    , ("Tennis Ball", 19)
    , ("The Game Awards - Statue", 655) -- VGA_Statue
    , ("UFO", 20)
    , ("Venus Flytrap", 788)
    , ("Waffle", 401)
    , ("White Flag", 491)
    , ("Wonder Woman", 806)
    -- TODO: What are these called in game?
    , ("Community", 527)
    , ("ESL_Champ", 537)
    , ("Eyeball", 396)
    , ("Moderator", 528)
    , ("PanicButton", 829)
    , ("Psyonix", 287)
    , ("TourneyChamp", 539)
    , ("Translator", 530)
    -- Community Flags
    , ("9GAG", 799)
    , ("AbleGamers", 814)
    , ("Achievement Hunter", 610)
    , ("Angry Army", 548) -- AgryJoe
    , ("Anne Munition", 531)
    , ("Day[9]TV", 654)
    , ("Destructoid", 724)
    , ("EMD1", 532) -- EatMyDiction
    , ("ESL", 536)
    , ("Funhaus", 611)
    , ("Gamespot", 725)
    , ("Gassy Mexican", 511)
    , ("Gfinity", 732)
    , ("GoldGlove", 728)
    , ("IGN", 802)
    , ("itmeJP", 533)
    , ("LIRIK", 513)
    , ("lolRenaynay", 628)
    , ("MLG", 538)
    , ("NeoGAF", 616)
    , ("NVIDIA", 808)
    , ("Operation Sports", 726)
    , ("PC Gamer", 667)
    , ("Polaris", 608)
    , ("Razer", 573)
    , ("Reddit", 630)
    , ("RL Garage", 645)
    , ("Rocket Beans TV", 869)
    , ("Rooster Teeth", 612)
    , ("Saudi Gamer", 534)
    , ("Serious Gaming", 572)
    , ("Something Awful", 699)
    , ("Spooky1611", 514)
    , ("Team Fat", 220)
    , ("Team PowA", 515)
    , ("The Attack", 535)
    , ("The Game Awards - Logo", 693) -- VGX
    , ("Twitch", 221)
    , ("YouTube Gaming", 516)
    -- Country Flags
    , ("Afghanistan", 407)
    , ("Albania", 408)
    , ("Algeria", 124)
    , ("American Samoa", 409)
    , ("Andorra", 830)
    , ("Angola", 410)
    , ("Anguilla", 831)
    , ("Antigua & Barbuda", 832)
    , ("Argentina", 125)
    , ("Armenia", 411)
    , ("Aruba", 833)
    , ("Australia", 126)
    , ("Austria", 127)
    , ("Azerbaijan", 412)
    , ("Bahamas", 834)
    , ("Bahrain", 550)
    , ("Bangladesh", 413)
    , ("Barbados", 835)
    , ("Belarus", 414)
    , ("Belgium", 128)
    , ("Belize", 551)
    , ("Benin", 415)
    , ("Bermuda", 836)
    , ("Bhutan", 552)
    , ("Bolivia", 416)
    , ("Bosnia and Herzegovina", 129)
    , ("Botswana", 553)
    , ("Brazil", 130)
    , ("British Virgin Islands", 837)
    , ("Bulgaria", 131)
    , ("Burkina Faso", 417)
    , ("Burma", 418)
    , ("Burundi", 419)
    , ("Cambodia", 420)
    , ("Cameroon", 132)
    , ("Canada", 133)
    , ("Cape Verde Islands", 134)
    , ("Cayman Islands", 838)
    , ("Central African Republic", 540)
    , ("Chad", 422)
    , ("Chile", 135)
    , ("China", 136)
    , ("Chinese Taipei", 198)
    , ("Colombia", 137)
    , ("Comoros", 554)
    , ("Congo", 138)
    , ("Congo DR", 423)
    , ("Cook Islands", 839)
    , ("Costa Rica", 139)
    , ("Croatia", 140)
    , ("Cuba", 424)
    , ("Curacao", 840)
    , ("Cyprus", 141)
    , ("Czech Republic", 142)
    , ("Côte d'Ivoire", 165)
    , ("Denmark", 143)
    , ("Djibouti", 555)
    , ("Dominica", 841)
    , ("Dominican Republic", 425)
    , ("East Timor", 556)
    , ("Ecuador", 144)
    , ("Egypt", 426)
    , ("El Salvador", 145)
    , ("England", 146)
    , ("Equatorial Guinea", 147)
    , ("Eritrea", 427)
    , ("Estonia", 428)
    , ("Ethiopia", 429)
    , ("Falkland Islands", 842)
    , ("Faroe Islands", 843)
    , ("Fiji", 557)
    , ("Finland", 148)
    , ("France", 149)
    , ("Gabon", 430)
    , ("Gambia", 558)
    , ("Georgia", 431)
    , ("Germany", 150)
    , ("Ghana", 151)
    , ("Gibraltar", 844)
    , ("Greece", 152)
    , ("Grenada", 863)
    , ("Guam", 432)
    , ("Guatemala", 153)
    , ("Guinea", 154)
    , ("Guinea Bissau", 559)
    , ("Guyana", 560)
    , ("Haiti", 433)
    , ("Honduras", 155)
    , ("Hong Kong", 156)
    , ("Hungary", 157)
    , ("Iceland", 158)
    , ("India", 159)
    , ("Indonesia", 160)
    , ("Iran", 161)
    , ("Iraq", 434)
    , ("Ireland", 162)
    , ("Isle Of Man", 845)
    , ("Israel", 163)
    , ("Italy", 164)
    , ("Jamaica", 166)
    , ("Japan", 167)
    , ("Jordan", 435)
    , ("Kazakhstan", 436)
    , ("Kenya", 168)
    , ("Kiribati", 846)
    , ("Kosovo", 561)
    , ("Kuwait", 437)
    , ("Kyrgyzstan", 438)
    , ("Laos", 439)
    , ("Latvia", 440)
    , ("Lebanon", 441)
    , ("Lesotho", 562)
    , ("Liberia", 442)
    , ("Libya", 443)
    , ("Lithuania", 444)
    , ("Luxembourg", 169)
    , ("Macau", 563)
    , ("Macedonia", 445)
    , ("Madagascar", 446)
    , ("Malawi", 447)
    , ("Malaysia", 170)
    , ("Maldives", 847)
    , ("Mali", 448)
    , ("Malta", 171)
    , ("Marshall Islands", 848)
    , ("Mauritania", 449)
    , ("Mauritius", 564)
    , ("Mexico", 172)
    , ("Micronesia", 849)
    , ("Moldova", 450)
    , ("Mongolia", 451)
    , ("Montenegro", 452)
    , ("Montserrat", 864)
    , ("Morocco", 453)
    , ("Mozambique", 454)
    , ("Namibia", 457)
    , ("Nepal", 458)
    , ("Netherlands", 173)
    , ("New Caledonia", 850)
    , ("New Zealand", 174)
    , ("Nicaragua", 175)
    , ("Nigeria", 176)
    , ("North Korea", 460)
    , ("North Mariana Islands", 456)
    , ("Northern Ireland", 177)
    , ("Norway", 178)
    , ("Oman", 461)
    , ("Palestine", 462)
    , ("Palau", 851)
    , ("Palestine", 462)
    , ("Panama", 180)
    , ("Papua New Guinea", 463)
    , ("Paraguay", 464)
    , ("Peru", 181)
    , ("Philippines", 182)
    , ("Poland", 183)
    , ("Portugal", 184)
    , ("Puerto Rico", 465)
    , ("Puntland", 565)
    , ("Qatar", 466)
    , ("Republic of Niger", 459)
    , ("Romania", 185)
    , ("Russia", 186)
    , ("Rwanda", 467)
    , ("Réunion", 566)
    , ("Saint Kitts & Nevis", 852)
    , ("Saint Lucia", 853)
    , ("Saint Vincent", 854)
    , ("Samoa", 855)
    , ("San Marino", 856)
    , ("Sao Tome", 857)
    , ("Saudi Arabia", 468)
    , ("Scotland", 187)
    , ("Senegal", 188)
    , ("Serbia", 189)
    , ("Seychelles", 858)
    , ("Sierra Leone", 469)
    , ("Singapore", 190)
    , ("Slovakia", 191)
    , ("Slovenia", 192)
    , ("Solomon Islands", 567)
    , ("Somalia", 470)
    , ("Somaliland", 568)
    , ("South Africa", 193)
    , ("South Korea", 194)
    , ("South Sudan", 471)
    , ("Spain", 195)
    , ("Sri Lanka", 389)
    , ("Sudan", 472)
    , ("Suriname", 569)
    , ("Swaziland", 570)
    , ("Sweden", 196)
    , ("Switzerland", 197)
    , ("Syria", 473)
    , ("Tahiti", 859)
    , ("Tajikistan", 474)
    , ("Tanzania", 475)
    , ("Thailand", 199)
    , ("Togo", 476)
    , ("Tonga", 730)
    , ("Trinidad and Tobago", 477)
    , ("Tunisia", 200)
    , ("Turkey", 201)
    , ("Turkmenistan", 478)
    , ("Turks & Caicos", 860)
    , ("Uganda", 479)
    , ("Ukraine", 204)
    , ("United Arab Emirates", 202)
    , ("United Kingdom", 203)
    , ("United States", 206)
    , ("Uruguay", 502)
    , ("US Virgin Islands", 480)
    , ("Uzbekistan", 481)
    , ("Vanuatu", 861)
    , ("Vatican City", 862)
    , ("Venezuela", 207)
    , ("Vietnam", 208)
    , ("Wales", 209)
    , ("Western Sahara", 571)
    , ("Yemen", 210)
    , ("Zambia", 482)
    , ("Zimbabwe", 483)
    -- NBA Flags
    , ("NBA", 1263)
    , ("Atlanta Hawks", 1245)
    , ("Boston Celtics", 1246)
    , ("Brooklyn Nets", 1247)
    , ("Charlotte Hornets", 1248)
    , ("Chicago Bulls", 1249)
    , ("Cleveland Cavaliers", 1250)
    , ("Dallas Mavericks", 1251)
    , ("Denver Nuggets", 1252)
    , ("Detroit Pistons", 1253)
    , ("Golden State Warriors", 1254)
    , ("Houston Rockets", 1255)
    , ("Indian Pacers", 1256)
    , ("Los Angeles Clippers", 1257)
    , ("Los Angeles Lakers", 1258)
    , ("Memphis Grizzlies", 1259)
    , ("Miami Heat", 1260)
    , ("Milwaukee Bucks", 1261)
    , ("Minnesota Timberwolves", 1262)
    , ("New Orleans Pelicans", 1264)
    , ("New Tork Knicks", 1265)
    , ("Oklahoma City Thunder", 1266)
    , ("Orlando Magic", 1267)
    , ("Philadelphia 76ers", 1268)
    , ("Phoenix Suns", 1269)
    , ("Portland Trail Blazers", 1270)
    , ("Sacramento Kings", 1271)
    , ("San Antonio Spurs", 1272)
    , ("Toronto Raptors", 1273)
    , ("Utah Jazz", 1274)
    , ("Washington Wizards", 1275)
    -- Video Games
    , ("Blacklight", 385)
    , ("Blacklight: Retribution", 211)
    , ("Chivalry - Agatha Knights", 525)
    , ("Chivalry - Mason Order", 526)
    , ("Edge Of Space", 213)
    , ("Euro Truck Simulator Rig", 813) -- ETS2
    , ("Fallout - Vault Boy", 673)
    , ("Fenix Rage", 216)
    , ("Goat Simulator - G2", 927)
    , ("Goat Simulator - Goatenna", 867)
    , ("Oddworld - Abe", 678)
    , ("Oddworld - Molluck", 679)
    , ("Oddworld - Necrum", 632)
    , ("Oddworld - RuptureFarms", 633)
    , ("Portal - Aperture Laboratories", 656)
    , ("Portal - Cake Sticker", 657)
    , ("Portal - Companion Cube", 681)
    , ("Portal - PotatOS", 698)
    , ("Portal - Wheatley", 686) -- Portal_PC
    , ("Shadowgate", 218)
    , ("Strike Vector EX", 219)
    , ("Unreal", 222)
    , ("Unreal Frag Center", 485)
    , ("Unreal Tournament", 489) -- UTBlue
    , ("Unreal Tournament (Classic)", 487) -- UT
    , ("Unreal Tournament - Blue", 484) -- Epic_BlueFlag
    , ("Unreal Tournament - Flak Shell", 397)
    , ("Unreal Tournament - Red", 486) -- Epic_RedFlag
    , ("Unreal Tournament 2004", 488)
    , ("Warframe", 223)
    , ("Warframe - Chroma", 682)
    , ("Warframe - Excalibur", 684)
    , ("Warframe - Loki", 683)
    , ("Witcher Medallion", 749)
    , ("Worms W.M.D", 1008)
    , ("Worms W.M.D. Grenade", 1000)
    ] & map (\ (v, k) -> (k, StrictText.pack v)) & Bimap.fromList
