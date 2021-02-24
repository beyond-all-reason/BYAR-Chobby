local scenariodata = {
	index			= 1, --  integer, sort order, MUST BE EQUAL TO FILENAME NUMBER
	uniqueid		= "firstscenario001", -- no spaces, lowercase, this will be used to save the score
    version         = 1, -- increment this to keep the score when changing a mission
	title			= "Killing Barbarians", -- can be anything
	imagepath		= "scenario001.jpg", -- placed next to lua file
	imageflavor		= "Be the murder hobo you always wanted to be", -- This text will be drawn over image
    summary         = [[Kill all 3 nasty barbarians in the top right ]],
	briefing 		= [[    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec massa ligula, scelerisque ac nulla id, efficitur convallis nisi. Nunc tellus neque, laoreet in porttitor ac, congue sit amet leo. Nulla dignissim lorem sit amet pharetra imperdiet. Mauris rhoncus porta tincidunt. Cras facilisis vel nunc sed congue. Praesent efficitur metus ac lectus pretium lacinia. Donec erat velit, aliquet non volutpat interdum, tincidunt non justo. Nullam volutpat urna vestibulum, rhoncus nisl nec, porttitor urna. Morbi lobortis elit at ex malesuada, id viverra ex sodales. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Donec imperdiet, dolor et fringilla congue, enim nisi feugiat libero, aliquet maximus felis justo ultrices tortor. Ut viverra elit sit amet justo porta bibendum. Suspendisse mattis lacinia massa id lacinia. Nunc sed dolor sed turpis tincidunt egestas nec vel magna. Nam ornare scelerisque lorem, quis congue tellus tempus eu. Donec et molestie tortor.

    Morbi purus turpis, convallis id mauris in, suscipit dignissim tellus. Nulla sit amet sagittis lectus. Nullam congue metus a condimentum placerat. Fusce aliquam ligula placerat, fermentum dui vel, molestie nisl. Etiam at diam blandit, malesuada odio eu, sagittis felis. Mauris augue lacus, congue ac mauris ut, posuere finibus felis. Proin ac nisl pulvinar justo pharetra efficitur at ut eros. Integer in lectus nec purus ullamcorper rhoncus. Maecenas vitae mi in eros vehicula aliquet et vitae elit. Morbi ornare vitae dui in rhoncus.
    
    Phasellus pretium auctor quam, ac efficitur purus euismod et. Etiam eget purus velit. Donec cursus tristique cursus. Duis dictum condimentum massa, sit amet hendrerit augue finibus vel. Quisque hendrerit, metus sit amet ultricies scelerisque, nisl nunc feugiat felis, vitae congue tellus felis id magna. Etiam congue accumsan auctor. Proin lobortis dolor ac dolor condimentum varius. Nunc ac mollis turpis, at elementum orci. Sed eu iaculis enim, ac fringilla felis. Proin varius fringilla suscipit. Donec gravida porttitor lectus eget aliquam. Nullam lorem sapien, aliquet id tincidunt non, accumsan a felis. Nulla ultrices blandit lorem, in mattis ipsum elementum et. Cras tristique eros vel vestibulum aliquam. Morbi cursus magna quis ante porta consectetur. ]],

	mapfilename		= "Supreme_Crossing_V1", -- the name of the map to be displayed here
	playerstartx	= "25%", -- X position of where player comm icon should be drawn, from top left of the map
	playerstarty	= "75%", -- Y position of where player comm icon should be drawn, from top left of the map
	partime 		= 3000, -- par time in seconds
	parresources	= 1000000, -- par resource amount
	difficulty		= 5, -- integer 1-10
    adjustablediff  = true, -- whether player can change bonus
    defaultside     = "Armada", --"Armada", Cortex or Random
	victorycondition= "Kill All Enemy Commanders", -- This is plaintext, but should be reflected in startscript
	losscondition	= "Death of your commander",  -- This is plaintext, but should be reflected in startscript
    unitlimits   = { -- table of unitdefname : maxnumberoftese units, 0 is disable it
        armavp = 0,
        coravp = 0,
    } ,

    scenariomodoptions = { -- this will get lua->json->base64 and passed to scenariooptions in game
        myoption = "dostuff",

    },
    -- https://github.com/spring/spring/blob/105.0/doc/StartScriptFormat.txt
	startscript		= [[[Game]
{
    [allyTeam0]
    {
        startrectright = 0.36900368;
        startrectbottom = 0.84132844;
        startrectleft = 0.2509225;
        numallies = 0;
        startrecttop = 0.70479703;
    }

    [ai1]
    {
        Host = 0;
        IsFromDemo = 0;
        Name = BARbarIAnstable(2);
        ShortName = BARbarIAn;
        Team = 2;
        Version = stable;
    }

    [team1]
    {
        Handicap = 0;
        RgbColor = 0.89999998 0.1 0.28999999;
        AllyTeam = 1;
        TeamLeader = 0;
    }

    [allyTeam1]
    {
        startrectright = 0.99631;
        startrectbottom = 0.34686348;
        startrectleft = 0.62730628;
        numallies = 0;
        startrecttop = 0;
    }

    [team3]
    {
        Handicap = 0;
        RgbColor = 0.95999998 0.50999999 0.19;
        AllyTeam = 1;
        TeamLeader = 0;
    }

    [team0]
    {
        Side = __PLAYERSIDE__;
        Handicap = __PLAYERBONUS__;
        RgbColor = 0 0.50999999 0.77999997;
        AllyTeam = 0;
        TeamLeader = 0;
    }

    [team2]
    {
        Handicap = 0;
        RgbColor = 1 0.88 0.1;
        AllyTeam = 1;
        TeamLeader = 0;
    }

    [modoptions]
    {
        scenariooptions = __SCENARIOOPTIONS__;
    }

    [ai2]
    {
        Host = 0;
        IsFromDemo = 0;
        Name = BARbarIAnstable(3);
        ShortName = BARbarIAn;
        Team = 3;
        Version = stable;
    }

    [ai0]
    {
        Host = 0;
        IsFromDemo = 0;
        Name = BARbarIAnstable(1);
        ShortName = BARbarIAn;
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
    mapname = Supreme_Crossing_V1;
    ishost = 1;
    numusers = 4;
    gametype = __BARVERSION__;
    GameStartDelay = 10;
    myplayername = __PLAYERNAME__;
    nohelperais = 0;

    
	NumRestrictions=__NUMRESTRICTIONS__;

	[RESTRICT]
	{
		//Unit0=armah;
		//Limit0=0;       // use 0 for all units that should be completely disabled
		//Unit1=corvp;
		//Limit1=50;      // >0 can be used for limiting, like build restrictions in TA
		//...
        __RESTRICTEDUNITS__
	}
}
	]],
	
}

return scenariodata