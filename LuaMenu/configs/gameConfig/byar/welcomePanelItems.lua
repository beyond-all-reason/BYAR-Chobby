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
        Header = "Welcome to Beyond All Reason",
        Text = "Welcome back Commander. We hope you are ready for epic single player and multiplayer battles. Check out our Discord and join the community!\n",
    },
    {
        Header = "Improvise, Adapt, Overcome - Insane 6v6 tourney is coming!",
        Image = "LuaMenu/images/6v6Tournament.png",
        Text = "With just three weeks passing since the last official tournament, we are back with another one, and this time we are really going to shake things up. Are you ready to embrace the unexpected, think on your feet, and conquer challenges with your quick wit and creativity? Join us for the most exhilarating and mind-bending tournament of the year: the 'Improvise, Adapt, Overcome' 6v6 Tournament!\n\n",
        Url = "https://www.beyondallreason.info/news/improvise-adapt-overcome-insane-6v6-tourney-is-coming",
        UrlText = "More info",
    },
    {
        Header = nil,
        Text = "Qualifiers start Oct 28 5PM CEST - Register your team today!",
        Url = "https://www.start.gg/tournament/improvise-adapt-overcome/details",
        UrlText = "Register at start.gg",
    },
    {
        Header = "Commander update survey!",
        Url = "https://forms.gle/6iagp9r8EWPc3YUQ9",
        Text = "\nWe would like to collect your feedback in a systematic way to use as supplementary data for the Game Design Team's discussion and ultimately decision on if and what tweaks should be applied. Thank you in advance for your time!\n",
        UrlText = "Participate"
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
