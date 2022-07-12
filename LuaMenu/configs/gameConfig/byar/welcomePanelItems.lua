local welcomePanelItems = {
    {
        Header = "Welcome to BAR Alpha",
        Url = "https://discord.gg/N968ddE",
        Time = nil,-- "NowTime",
        Text = "Welcome back Commander. We hope you are ready for epic single player and multiplayer battles. Check out our Discord and join the community!\n",
    },

    {
        Header = "New Map: Cirolata 1.02",
        Time = nil,-- "NowTime",
        Image = "LuaMenu/configs/gameConfig/byar/minimapThumbnail/Cirolata_1.02.png",
        Text = "A new 4-way Team-FFA map on a 16x16 subtropical island.",
    },

    {
        Header = "New Map: Bismuth Valley v1.0",
        --Url = "https://drive.google.com/drive/folders/16eBcMpkgMTV9mlKxYmNda64X_dmCFdkk",
        Time = nil,-- "NowTime",
        Image = "LuaMenu/configs/gameConfig/byar/minimapThumbnail/bismuth_valley_v1.0.png",
        Text = "New 8v8 map released! Fight over large 24x16 grim alien canyon.",
    },

    --['Tumult Remake v1.0']={Width=14, Height=14, Is1v1=1, IsTeam=1, IsFFA=nil, IsCertified=nil, Special=nil, Flat=1, Hills=1, Water=nil, IsInPool=1, PlayerCount=nil,TeamCount=nil,Author='Nikuksis (original by Hunterw)', InfoText='4v4 map where only bots can pass side hills.'},

    --[[
    {
        Header = "Map Download Issues",
        Url = "https://drive.google.com/drive/folders/16eBcMpkgMTV9mlKxYmNda64X_dmCFdkk",
        Time = nil,-- "NowTime",
        Text = "We are experiencing some issues with automatic map downloads. You can download all of the maps from the google drive link in the title and just put them into /data/maps/ .",
    },
    {
        Header = "Server Moved",
        Url = nil, --"https://www.beyondallreason.info/",
        Time = nil,-- "NowTime",
        Text = "We have moved the multiplayer lobby server from road-flag.bnr.la:8200 to server2.beyondallreason.info:8200. We hope games will continue to be uninterrupted, report any connectivity issues to us on Discord!\n Please update your game to automatically switch over, and if you need to manually switch servers, you can do so in Settings->Lobby->Choose Server" ,
    },]]--
    --[[
    {
        Header = "New engine release",
        Url = nil, -- should be nil if you dont want a clickable link button
        Time = nil, --"",
        Text = "We've just released a new engine update. Be sure to report any issues to #bugreports on the discord and thank you for bearing with us through any teething problems with it.."
    }, ]]--
    {
        Header = "Beyond All Reason Alpha Championship Cup #2",
        Url = "https://www.twitch.tv/videos/1450944560",
        Time = nil, --"",
        Text = "Congratulations to Raghna for his victory. We'll have something up on YouTube in the near future but for now we still have the twitch stream."
    },
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
