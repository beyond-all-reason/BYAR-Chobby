--[[ -- example
    {
        Header = "bla",
        Text = "bla",
        Url = "https://www.beyondallreason.info",
        UrlText = "Beyond All Reason Website",
        Image = "LuaMenu/configs/gameConfig/byar/images/bla.png",
        Time = whatever the hell this thing does.
    }
]]



local welcomePanelItems = {
    {
        Header = "Alpha Championship Cup #3",
        Image = "LuaMenu/images/1vs1Tournament.png",
        Url = "https://www.beyondallreason.info/news/bar-alpha-championship-3-is-on-the-way",
        Time = "2023-04-08T14:00:00",
        Text = "See the brackets for upcoming championship and join the tourney or see the official stream on 8th of April!\n",
        UrlText = "Sign-Up"
    },
    {
        Header = "Welcome to Beyond All Reason",
        Text = "Welcome back Commander. We hope you are ready for epic single player and multiplayer battles. Check out our Discord and join the community!\n",
    },
    {
        Header = "Guides for new players",
        Url = "https://www.youtube.com/channel/UCAByJ5NKeMmQ95EIWgBtbEw",
        Text = "Requiem has created some guides for new players. If you're new to the game and want to learn the basics via video we highly recommend you check them out.\n",
        UrlText = "Link to video guides"
    },
    
    {
        Header = "New Map: Hades Ponds 0.7",
        Image = "LuaMenu/configs/gameConfig/byar/minimapThumbnail/Hades_Ponds_0.7.png",
        Text = "A new team-game map by Phalange.",
    },
    
    {
        Header = "New Map: Carrot Mountains v1.0",
        Image = "LuaMenu/configs/gameConfig/byar/minimapThumbnail/carrot_mountains_v1.0.png",
        Text = "A tribute to OTA Yerrot Mountains by Nikuksis.",
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

    {
        Header = "Code of Conduct",
        Url = "https://www.beyondallreason.info/code-of-conduct",
        Text = "We recently updated our code of conduct; be sure to check it out. As our community growth we've added the ability to report problems, click a user and select 'report user' to alert the moderator team to an issue. See the full code of conduct at https://www.beyondallreason.info/code-of-conduct",
        UrlText = "Code of Conduct Link"
    },

    {
        Header = "Play with your friends: use our servers!",
        Text = "Join any empty (blue), or waiting (green) battle to start playing, or host your own public or private battle by clicking the Host Game button in the Multiplayer Battle List",
    },

    {
        Header = "Useful commands in Multiplayer!",
        Text = "!boss nickname \n" ..
            "Boss someone (or yourself) in your battleroom so that person can set all the settings up without voting. You automatically become a boss of a room that you Host yourself.\n" ..
            " \n" ..
            "!forcestart \n" ..
            "If your game is stuck because of some AFK player that refuses to load or press ready, or you encountered a bug that prevents your game from starting, or you set up weird teams, !forcestart is your savior.\n" ..
            " \n" ..
            "!stop \n" ..
            "If you need to terminate the game you're currently playing for whatever reason, !stop will happily do it for you.\n" ..
            " \n" ..
            "!promote \n"  ..
            "Sends a little message on Discord on #looking-for-players channel that your room is waiting for people to join.\n" ..
            " \n" ..
            "$rename \n"  ..
            "Rename the battleroom you're currently in. Requires you to be the !boss of the battleroom to do so.\n" ..
            " \n" ..
            "$explain \n" ..
            "Gives you a nice breakdown of how the autobalance works in your current battleroom.\n" ..
            " \n" ..
            "For a full list of commands, use !help and $help in any multiplayer room." ..
            " \n",
    },
}

return welcomePanelItems
