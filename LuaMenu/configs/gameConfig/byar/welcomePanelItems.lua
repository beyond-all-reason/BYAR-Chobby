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
        Text = "Welcome back Commander. We hope you are ready for epic Singleplayer and Multiplayer battles. Check out our Discord and join the community!\n",
    },
    {
        Header = "Beyond All Reason: Season 2 | Balance patch and a ton of great news",
        Text = " \n" .. "Beyond All Reason kicks off 2025 with a massive Seasonal Update! New balance changes, rating adjustments, maps, and the highly anticipated Alpha Cup 2025. Join the battle and shape the future of BAR!",
        Image = "LuaMenu/images/welcomepanel/season2small.png",
        Time = "2025-03-23T11:00:00",
        Url = "https://www.beyondallreason.info/news/season-2-is-here",
        UrlText = "Read Announcement",
    },
    {
        Header = "Creative Call to Arms - April Fools Music Edition.",
        Text = "Are you a music producer yourself? Or maybe you have a friend who is and would like to get some recognition? " .. " \n" .. " \n" .. "Create a remix/cover of any BAR track, or even a mix of BAR themes in a single track, and it might end up featured in the game!\n\nAn unique opportunity for aspiring music artists to shine!" .. " \n" .. " \n" .. "You have to be quick though, You only have a few days!",
        Image = "LuaMenu/images/welcomepanel/BAR OST.png",
        Url = "https://discord.com/channels/549281623154229250/697141979892416512/1354571123207180418",
        UrlText = "Announcement on Discord",
        Time = "2025-04-01T06:00:00",
    },
    {
        Header = "We need you! Creative Call to Arms Vol.2",
        Text = "We’re now seeking volunteers to design icons for weapon types to enhance the game’s visual identity. We need icons for weapon stats like Ground to Air, Air to Ground, Damage, Burst, Reload Time, and more. " .. " \n" .. " \n" .. "Let's create something awesome together! Check #concept-art channel on Discord for more details (needs Development role).",
        Image = "LuaMenu/images/welcomepanel/CTA2.png",
        Url = "https://discord.com/channels/549281623154229250/1346438415176040561/1353700113641508884",
        UrlText = "Go to #concept-art",
    },
    {
        Header = "Upcoming Events:",
    },
    {
        Header = "Fight Night Open",
        Text = "Casual 1v1 Tournament - practice for Alpha Cup!",
        Time = "2025-04-04T01:00:00",
        Url = "https://bfn.challonge.com/FN1",
        UrlText = "Sign Up",
    },
    {   
        Header = "Dominaticus BAR Open Royale",
        Text = "All-Welcome 4v4 Tournament",
        Time = "2025-04-05T14:00:00",
        Url = "https://form.jotform.com/250542038778058",
        UrlText = "Sign Up",
    },
    {   
        Header = "Alpha Cup V 2025",
        Text = "Crown a new 1v1 Champion! All welcome.",
        Time = "2025-04-12T16:00:00",
        Url = "https://challonge.com/eb74xb0p",
        UrlText = "Sign Up",
    },
    {
        Header = "Apprentice League",
        Text = "Maximum 30 OS 1v1 Tournament",
        Time = "2025-04-12T01:00:00",
        Url = "https://discord.gg/YgSUjQpTZe",
        UrlText = "Join the Discord",
    },
    {
        Header = "New Map: Project SD-129",
        Text = "Project SD-129 is a massive up to 32-player FFA and Team FFA map by Nikuksis, set on a donut-shaped asteroid with a space backdrop." .. " \n" .. " \n" .. "Designed for chaotic free-for-alls but also balanced for team play, Asteroid Isles in the middle feature some resources that are only reachable by air. Try it now!",
        Image = "LuaMenu/configs/gameConfig/byar/minimapOverride/Project_SD-129_v1.0.jpg",
    },
    {
        Header = "Now Available: BAR Guides",
        Text = "New to Beyond All Reason? Check out these new Guides on Discord written by Zeteo!" .. " \n" .. " \n",
        Url = "https://discord.com/channels/549281623154229250/1303141562120929320/1303141562120929320",
        UrlText = "Read the new Guides",
    },
    {
        Header = "BAR is accepting donations again! ",
        Text = "Dear Commanders, we are delighted to announce the reopening of our donation platform after a longer-than-expected hiatus." .. " \n" .. " \n" .. "As we've been hard at work refining BAR to ensure maximum enjoyment for our ever-expanding community, we repeatedly placed donation efforts on hold to focus on other priorities." .. " \n" .. " \n" .. "Support BAR with our newly reopened donation platform!" .. " \n",
        Image = "LuaMenu/images/donate.png",
        Url = "https://www.beyondallreason.info/news/support-bar-with-our-newly-reopened-donation-platform",
        UrlText = "Read Announcement",
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
            " \n" ..
            " \b",
    },
}

return welcomePanelItems
