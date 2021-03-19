local scenariodata = {
	index			= 3, --  integer, sort order, MUST BE EQUAL TO FILENAME NUMBER
	scenarioid		= "acidicquarrybarbs", -- no spaces, lowercase, this will be used to save the score
    version         = "1", -- increment this to keep the score when changing a mission
	title			= "Judge jury and executioner", -- can be anything
	imagepath		= "scenario007.jpg", -- placed next to lua file, should be 3:1 ratio banner style
	imageflavor		= "aviation module inspection of subject #", -- This text will be drawn over image
    summary         = [[Judge over aviation module of test subject #subsequent_number.]],
	briefing 		= [[******
	A]z­³(׃פ„½ֵןlO"-‚Z!אAא³ֿ)¸(׳sֶזmרrµ™†<ֻg WVםGצ–ֿzט₪j÷(`6_~—…N+2J‰…×<	¶}«ת
	„˜X9ןֲn±אֱIoךZE‏o״¯"O5$…›,ִ~צק`¢0פN¡‎w=VKGױ¢A?Hֿםׂp¹2÷ף.–\\ק¶{_‎}qd~®ִDׁ$(%²{ld~2†ל’3ֳ3ˆ
	...High order intelligence data link request detected.
	/dumping #current_number test subejct..
	/test subject dissolved.
	Initiating data connection with galactic subsector #A245-q.
	Sending reply packet.
	Connection established in..
	3
	2
	1
	Connection established with Selector #1-45737.
	Selector #1-45737, these are the results of training procedure, #501, of test subject's, #subsequent_number, aviation module and general competence.
	subject, #subsequent_number, was tested versus rudimentary #0 level intelligences.
	Awaiting Selector #1-45737's output.... 
	
	Recommended areas of attention:
		1.Speed: Time interval between activation of subject, #subsequent_number, and annihilation of opposing #0 level entities.
		2.Efficiency: Resoruces used between activiation of subject, #subsequent_number, and annihialtion of opposing #0 level entities.
 
	Recommended Guidelines:
		1.Examine ratio and timing of assembly of subject ,#subsequent_number's, energy structures versus aviation drone assembly and usage on opposing #0 level entities.
		2.Examine time and speed of subject, #subsequent_number's, expansion to nearby platform.
		3.Examine subject, #subsequent_number's, aviation assault algorithms, including bomber drone movement patterns and fighter drone control.
    ]],

	mapfilename		= "AcidicQuarry 5.16", -- the name of the map to be displayed here, and which to play on, no .smf ending needed
	playerstartx	= "15%", -- X position of where player comm icon should be drawn, from top left of the map
	playerstarty	= "75%", -- Y position of where player comm icon should be drawn, from top left of the map
	partime 		= 1800, -- par time in seconds
	parresources	= 1000000, -- par resource amount
	difficulty		= 6, -- Percieved difficulty at 'normal' level: integer 1-10
    defaultdifficulty = "Normal", -- an entry of the difficulty table
    difficulties    = { -- Array for sortedness, Keys are text that appears in selector (as well as in scoring!), values are handicap levels
    -- handicap values range [-100 - +100], with 0 being regular resources
        {name = "Beginner", playerhandicap = 50, enemyhandicap=0},
        {name = "Novice"  , playerhandicap = 25, enemyhandicap=0},
        {name = "Normal"  , playerhandicap = 0, enemyhandicap=0},
        {name = "Hard"    , playerhandicap = 0,  enemyhandicap=25},
        {name = "Brutal" , playerhandicap = 0,  enemyhandicap=50},
    },
    allowedsides     = {"Armada","Cortex","Random"}, --these are the permitted factions for this mission
	victorycondition= "Kill all enemy Commanders", -- This is plaintext, but should be reflected in startscript
	losscondition	= "Death of your Commander",  -- This is plaintext, but should be reflected in startscript
    unitlimits   = { -- table of unitdefname : maxnumberoftese units, 0 means disable it        -- dont use the one in startscript, put the disabled stuff here so we can show it in scenario window!
        --armavp = 0,
        --coravp = 0,
		armcir = 0,
        armferret = 0,
        armflak = 0,
        armmercury = 0,
        armrl = 0,
        armalab = 0,
		armavp = 0,
		armhp = 0,
		armlab = 0,
		armshltx = 0,
		armvp = 0,
		corerad = 0,
		corflak = 0,
		cormadsam = 0,
		corrl = 0,
		corscreamer = 0,
		coralab = 0,
		coravp = 0,
		corgant = 0,
		corhp = 0,
		corlab = 0,
		corvp = 0,
		
    } ,

    scenariooptions = { -- this will get lua->json->base64 and passed to scenariooptions in game
        myoption = "dostuff",
        scenarioid = "acidicquarrybarbs",
		disablefactionpicker = true, -- this is needed to prevent faction picking outside of the allowedsides 
    },
    -- https://github.com/spring/spring/blob/105.0/doc/StartScriptFormat.txt

    -- HOW TO MAKE THE START SCRIPT: Use Chobby's single player mode to set up your start script. When you launch a single player game, the start script is dumped into infolog.txt
    -- The following keys MUST be present in startscript below 
    --  __SCENARIOOPTIONS__
    -- __PLAYERNAME__
    -- __BARVERSION__
    -- __MAPNAME__

    -- Optional keys: 
    -- __ENEMYHANDICAP__
    -- __PLAYERSIDE__
    -- __PLAYERHANDICAP__
    -- __NUMRESTRICTIONS__
    -- __RESTRICTEDUNITS__

	startscript		= [[
[Game]
{
	[allyTeam0]
	{
		startrectright = 1;
		startrectbottom = 0.2;
		startrectleft = 0;
		numallies = 0;
		startrecttop = 0;
	}
	[ai1]
	{
		Host = 0;
		IsFromDemo = 0;
		Name = BARbstable(2);
		ShortName = BARb;
		Team = 2;
		Version = stable;
	}
	[team1]
	{
	    Side = Random;
        Handicap = __ENEMYHANDICAP__;
		RgbColor = 0.99706084 0.21503568 0.44135636;
		AllyTeam = 0;
		TeamLeader = 0;
	}
	[team0]
	{
        Side = __PLAYERSIDE__;
        Handicap = __PLAYERHANDICAP__;
		RgbColor = 0.90586215 0.60122037 0.24591541;
		AllyTeam = 1;
		TeamLeader = 0;
	}

	[allyTeam1]
	{
		startrectright = 1;
		startrectbottom = 1;
		startrectleft = 0;
		numallies = 0;
		startrecttop = 0.80000001;
	}

	[modoptions]
	{
		scenariooptions = __SCENARIOOPTIONS__;
	}

	[team2]
	{
		Handicap = 0;
		RgbColor = 0.23227084 0.54822761 0.46437711;
		AllyTeam = 0;
		TeamLeader = 0;
	}

	[ai0]
	{
		Host = 0;
		IsFromDemo = 0;
		Name = BARbstable(1);
		ShortName = BARb;
		Team = 1;
		Version = stable;
	}

	[player0]
	{
		IsFromDemo = 0;
        Name = __PLAYERNAME__;
		Team = 0;
		rank = 0;
	}

	hostip = 127.0.0.1;
	hostport = 0;
	numplayers = 1;
	startpostype = 2;
    mapname = __MAPNAME__;
	ishost = 1;
	numusers = 3;
    gametype = __BARVERSION__;
	GameStartDelay = 5;
    myplayername = __PLAYERNAME__;
	nohelperais = 0;

	NumRestrictions=13;
	[RESTRICT]
	{
        Unit0=armcir;
        Limit0=0;
        Unit2=armferret;
        Limit0=0;
        Unit3=armflak;
        Limit0=0;
        Unit4=armmercury;
        Limit0=0;
        Unit5=armrl;
        Limit0=0;
        Unit6=armalab;
        Limit0=0;
		Unit7=armavp;
        Limit0=0;
		Unit8=armhp;
        Limit0=0;
		Unit9=armlab;
        Limit0=0;
		Unit10=armshltx;
        Limit0=0;
		Unit11=armvp;
        Limit0=0;
		
		Unit12=corerad;
        Limit0=0;
		Unit13=corflak;
        Limit0=0;
		Unit14=cormadsam;
        Limit0=0;
		Unit15=corrl;
        Limit0=0;
		Unit16=corscreamer;
        Limit0=0;
		Unit17=coralab;
        Limit0=0;
		Unit18=coravp;
        Limit0=0;
		Unit19=corgant;
        Limit0=0;
		Unit20=corhp;
        Limit0=0;
		Unit21=corlab;
        Limit0=0;
		Unit22=corvp;
        Limit0=0;
	}
}    
	]],
}

return scenariodata