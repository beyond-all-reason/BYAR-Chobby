--[[ -- example
    {
        Header = "bla",
        Text = "bla",
        Url = "https://www.beyondallreason.info",
        UrlText = "Beyond All Reason Website",
        Image = "LuaMenu/configs/gameConfig/byar/images/bla.png",
        Time = "2023-05-06T14:00:00", -- needs to be in UTC and is converted to user's local timezone, shows the time difference 
    }
]]

local welcomePanelItems = {
    {
        Header = "Introducing the Supreme Tournament!!!",
        Text = "We are delighted to announce the SUPREME Tournament, an event that will genuinely highlight the incredible talent within our community.\n \nThis tournament will feature teams consisting of 8 players, with the option for up to 4 substitutes, battling it out on \"The Finest Map\" out there - Supreme Strait!\n \nRegistration deadline: 2023-10-06\nTournament start: 2023-10-07\n \nMatch days are going to be Saturdays and Sundays\n(1 per weekend for each team)\n \nWe invite everyone, regardless of their rank or experience level, to participate. Whether you wish to join with your friends or seek a team in our dedicated \"looking-for-team\" channel, we welcome you with open arms.\n \nJoin our Discord server and register now for the ultimate showdown!",
        Url = "https://discord.gg/prG3A5kHyv",
        UrlText = "Join tournament discord",
    },
    {
        Header = "New Map: Lavender Bender v2!",
        Image = "LuaMenu/configs/gameConfig/byar/minimapThumbnail/Lavender_Bender_v2.png",
        Text = "1v1-4v4 map\nBy Johannes",
    },
    {
        Header = "Commander update survey!",
        Url = "https://forms.gle/6iagp9r8EWPc3YUQ9",
        Text = "\nWe would like to collect your feedback in a systematic way to use as supplementary data for the Game Design Team's discussion and ultimately decision on if and what tweaks should be applied. Thank you in advance for your time!\n",
        UrlText = "Participate"
    },
    {
        Header = "Welcome to Beyond All Reason",
        Text = "Welcome back Commander. We hope you are ready for epic single player and multiplayer battles. Check out our Discord and join the community!\n",
    },
    {
        Header = "Season 0 has started!",
        Url = "https://www.beyondallreason.info/news/new-opportunities-ahead-season-zero-is-about-to-begin",
        Text = "The OpenSkill uncertainty factor was reset for all players to its default value (the same as for new players). It's expected that your match rating (displayed in lobby) is lower than what it was before the reset, and likewise for your rank icon\n",
        UrlText = "More info",
    },
    {
        Header = "Commander Update",
        Url = "https://www.beyondallreason.info/news/commander-update-details",
        Text = "Commanders have been changed! They are now immune to the mighty D-Gun and their explosion does less damage. Their wreckage contains reduced metal value of 1250 (was 2000)\n",
        UrlText = "More info",
    },
    {
        Header = "PRO 4v4 Tournament concluded!",
        Image = "LuaMenu/images/Group_141.png",
        Url = "https://www.youtube.com/watch?v=_dq9Xwfh4h4",
        Text = "\nCongratulations to the team BARcode!\nAs the dust slowly settles after the epic battles of 4v4 tourney, enjoy the tourney stream VOD! We really had a blast organising, casting an playing this one and sitting together with Chris Taylor (the creator of Total Annihilation) for a surprise interview.\n",
        UrlText = "Watch"
    },
    
    {
        Header = "Guides for new players",
        Url = "https://www.youtube.com/channel/UCAByJ5NKeMmQ95EIWgBtbEw",
        Text = "Requiem has created some guides for new players. If you're new to the game and want to learn the basics via video we highly recommend you check them out.\n",
        UrlText = "Link to video guides"
    },

    {
        Header = "Please help us test new engines!",
        Text = "Just select [Engine Test] in the launcher dropdown, and then play Skirmish and Multiplayer games. AMD testers especially needed. Report anything out of the ordinary to Discord!\n",
        UrlText = "BAR #engine channel on Discord"
    },

    {
        Header = "Steam release roadmap",
        Url = "https://www.beyondallreason.info/development/steam-release",
        Text = "We've published our Steam Release roadmap, check it out on the website!",
        UrlText = "Roadmap Link"
    },

    --[[
    {
        Header = "New engine release",
        Url = nil, -- should be nil if you dont want a clickable link button
        Time = nil, --"",
        Text = "We've just released a new engine update. Be sure to report any issues to #bugreports on the discord and thank you for bearing with us through any teething problems with it.."
    }, ]]--

    --{
    --    Header = "Code of Conduct",
    --    Url = "https://www.beyondallreason.info/code-of-conduct",
    --    Text = "We recently updated our code of conduct; be sure to check it out. As our community growth we've added the ability to report problems, click a user and select 'report user' to alert the moderator team to an issue. See the full code of conduct at https://www.beyondallreason.info/code-of-conduct",
    --    UrlText = "Code of Conduct Link"
    --},

    {
        Header = "Play with your friends: use our servers!",
        Text = "Join any empty (blue), or waiting (green) battle to start playing, or host your own public or private battle by clicking the Host Game button in the Multiplayer Battle List",
    },

    {
        Header = "Useful commands in Multiplayer!",
        Text = "!boss [nickname] \n" ..
            "Boss someone (or yourself) in your battleroom so that person can set all the settings up without voting. You automatically become a boss of a room that you Host yourself.\n" ..
            " \n" ..
            "!forcestart \n" ..
            "If your game is stuck because of some AFK player that refuses to load or press ready, or you encountered a bug that prevents your game from starting, or you set up weird teams, !forcestart is your savior.\n" ..
            " \n" ..
            "!stop \n" ..
            "If you need to terminate the game you're currently playing for whatever reason, !stop will happily do it for you.\n" ..
            " \n" ..
            "!promote \n"  ..
            "Sends a little message on ingame main chat that your room is waiting for people to join.\n" ..
            " \n" ..
            "$rename [name] \n"  ..
            "Renames the battleroom you're currently in. Requires you to be the !boss of the battleroom to do so.\n" ..
            " \n" ..
            "$setratinglevels [min] [max] \n"  ..
            "Sets minimum and maximum skill rating allowed in the room.\n" ..
            " \n" ..
            "$resetratinglevels\n"  ..
            "Removes skill rating limits from the room.\n" ..
            " \n" ..
            "$explain \n" ..
            "Gives you a nice breakdown of how the autobalance works in your current battleroom.\n" ..
            " \n" ..
            "For a full list of commands, use !help and $help in any multiplayer room." ..
            " \n",
    },
}

return welcomePanelItems
