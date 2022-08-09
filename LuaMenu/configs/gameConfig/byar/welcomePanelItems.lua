local welcomePanelItems = {
    {
        Header = "Welcome to Beyond All Reason",
        Url = "https://discord.gg/N968ddE",
        Time = nil,-- "NowTime",
        Text = "Welcome back Commander. We hope you are ready for epic single player and multiplayer battles. Check out our Discord and join the community!\n",
    },
    
    {
        Header = "Video guides for new players",
        Url = "https://www.youtube.com/channel/UCAByJ5NKeMmQ95EIWgBtbEw",
        Time = nil,-- "NowTime",
        Text = "Requiem has created some guides for new players. If you're new to the game and want to learn the basics via video we highly recommend you check them out.\n",
    },

    {
        Header = "New Map: Ice Scream v2.1",
        --Url = "https://drive.google.com/drive/folders/16eBcMpkgMTV9mlKxYmNda64X_dmCFdkk",
        Time = nil,-- "NowTime",
        Image = "LuaMenu/configs/gameConfig/byar/minimapThumbnail/ice_scream_v2.1.png",
        Text = "Complete rework for the Ice Scream map. Wide 30x10 map with icy rivers with boost for vehicle/hover speeds separated by hills best for bots. Air spot for each team.\nUpdated to version 2.1.\nBy Nikuksis",
    },

    {
        Header = "New Map: Rustcrown Canyon 1.1",
        Time = nil,-- "NowTime",
        Image = "LuaMenu/configs/gameConfig/byar/minimapThumbnail/Rustcrown_Canyon_1.1.png",
        Text = "\n \n \nPtaQ and Moose have collaborated to bring you Rustcrown Canyon. East vs West battles over a deep chasm containing a long river.",
    },

    {
        Header = "Steam release roadmap",
        Url = "https://discord.com/channels/549281623154229250/697141979892416512/997178414257680444",
        Time = nil,-- "NowTime",
        -- Image = "LuaMenu/configs/gameConfig/byar/minimapThumbnail/bismuth_valley_v1.0.png",
        Text = "We've published our Steam Release roadmap, check it out on the discord!",
    },

    --[[
    {
        Header = "New engine release",
        Url = nil, -- should be nil if you dont want a clickable link button
        Time = nil, --"",
        Text = "We've just released a new engine update. Be sure to report any issues to #bugreports on the discord and thank you for bearing with us through any teething problems with it.."
    }, ]]--
    -- {
    --     Header = "Beyond All Reason Alpha Championship Cup #2",
    --     Url = "https://www.twitch.tv/videos/1450944560",
    --     Time = nil, --"",
    --     Text = "Congratulations to Raghna for his victory. We'll have something up on YouTube in the near future but for now we still have the twitch stream."
    -- },
    {
        Header = "New single player scenarios",
        Url = nil, --"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Play these from the single player menu on the left, and tell us what you think of them on Discord in the #scenarios channel.\n" ,
    },
    {
        Header = "New code of conduct",
        Url = "https://www.beyondallreason.info/code-of-conduct",
        Time = nil,-- "NowTime",
        Text = "We recently updated our code of conduct; be sure to check it out. As our community growth we've added the ability to report problems, click a user and select 'report user' to alert the moderator team to an issue. See the full code of conduct at https://www.beyondallreason.info/code-of-conduct",
    },
    {
        Header = "Play with your friends: use our servers!",
        Url = nil,--"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "Join any empty (blue), or waiting (green) battle to start playing, or host your own public or private battle by clicking the Host Game button in the Multiplayer Battle List",
    },
    {
        Header = "Multiplayer battle room commands",
        --Url = "https://www.beyondallreason.info/",
        --Time = "NowTime",
        Text = "Type these commands into the battle room chat\n" ..
               "!help - The battle room will give you detailed commands in the chat tab\n" ..
               -- "!boss username - set username as a boss to gain full control (to disable: !boss)\n" ..
               "!preset team - sets the room to Team vs Team game\n" ..
               "!preset ffa - sets the room to Free-for-all game\n" ..
               "!preset coop - sets all players to one team and AIs to the other\n" ..
               -- "!fixcolors - Makes sure players dont have identical colors\n" ..
               "!forcestart - starts the game even if teams arent balanced or colors arent fixed\n" ..
               "!autobalance off - turns off automatic balancing (Recommended for PVE)\n" ..
               "!autofixcolors off - turns off automatic color assignment\n" 
               --"  !force Playername bonus [0-100] - Sets a % resource bonus for player or AI\n"..
               --"  !force Playername team 1 - Places player or AI into a specific team"
               ,
    },
}

return welcomePanelItems
