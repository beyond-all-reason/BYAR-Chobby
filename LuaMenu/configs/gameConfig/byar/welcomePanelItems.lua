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
        Header = "ATG and Isthmus restored",
        Text = "All That Glitters and Supreme Isthmus have been restored to the map rotation after a brief absence.",
    },

    {
        Header = "Big game updates!!!",
        Text = "Together with The Highest BAR Council, Game Design Team, Community and Moderation Committee and a bunch of random devs we decided on some uncontroversial yet very urgent updates aimed to enhance the player experience. Read below for the details." .. " \n" .. " \n" .. "Trees and Critters:" .. " \n" .. " \n" .. "Something menacing lurks in the bushes; beware of interrupting its slumber!" .. " \n" .. " \n" .. "New musics and boomboxes:" .. " \n" .. " \n" .. "We decided to change the tone of our soundtrack a little bit, a lot of people complained it is a bit too serious and dramatic so we remixed the tunes. Capture boomboxes to make it even more epic!" .. " \n" .. " \n" .. "Hats on:" .. " \n" .. " \n" .. "Upon a number of requests form the community we are finally introducing paid cosmetics for units, the first batch is free! Weeee!" .. " \n" .. " \n" .. "More epic changes to discover:" .. " \n" .. " \n" .. "We might have changes some more stuff but I don't even have the whole intel. Find them out!",
    },

    {
        Header = "Beyond All Reason Alpha Championship Cup #4",
        Text = "Format: 1v1 - Double Elimination",
        --Image = "LuaMenu/images/welcomepanel/1vs1Tournament.png",
        Url = "https://challonge.com/beyondallreasoncup4",
        UrlText = "Signup and Details",
    },

    {
        Header = "Guides for new players",
        Url = "https://www.youtube.com/channel/UCAByJ5NKeMmQ95EIWgBtbEw",
        Text = "Requiem has created some guides for new players. If you're new to the game and want to learn the basics via video we highly recommend you check them out.\n",
        UrlText = "Link to video guides"
    },

    --{
    --    Header = "Please help us test new engines!",
    --    Text = "Just select [Engine Test] in the launcher dropdown, and then play Skirmish and Multiplayer games. AMD testers especially needed. Report anything out of the ordinary to Discord!\n",
    --    UrlText = "BAR #engine channel on Discord"
    --},

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
    },
    --]]

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
