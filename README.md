# BYAR-Chobby

BYAR mutator for Chobby

# Download links

- [Linux](https://content.spring-launcher.com/beyond-all-reason/BYAR-Chobby/Beyond%20All%20Reason.AppImage)
- [Windows](https://content.spring-launcher.com/beyond-all-reason/BYAR-Chobby/Beyond%20All%20Reason.exe)

# Developing the Lobby

1. Download using one of the links above and start the application.
2. Start the application once using the "Test" version and launch the lobby. This will download the engine and other dependencies.
3. Open the install folder (there's a button for that in the launcher), and clone this repository inside the `games` folder, `git clone https://github.com/beyond-all-reason/BYAR-Chobby.git BYAR-Chobby.sdd`. This should result in the following folder being present: `/path/to/install/folder/data/games/BYAR-Chobby.sdd/`. (`Beyond-All-Reason\data\games\BYAR-Chobby.sdd\LuaMenu\configs\gameConfig` should be a correct path)
4. Choose the `Dev Lobby` config from the launcher's top right dropdown menu which will run the lobby version on your PC. You can now develop and test any BYAR specific lobby functionality.
5. If you want to develop Chobby itself, clone it in the `games` folder similar to step 3: `git clone https://github.com/Spring-Chobby/Chobby.git Chobby.sdd`. You must also change the `depend` table in `BYAR-Chobby.sdd/modinfo.lua` to use `Chobby $VERSION` instead of `rapid://chobby:test`.

To enable debugmode, make an empty devmode.txt in the already used game install folder (/data/), and then the `Settings/Developer` tab will appear in the lobby. All debug messages are visible in th Debug chat panel.

# Developing the Game

1. Make sure you've first finished setting up the lobby development environment (previous section)
2. Open the install folder, and inside the `games` folder clone the BAR *game* repository: `git clone https://github.com/beyond-all-reason/Beyond-All-Reason.git BAR.sdd`
3. Start Chobby with `Dev Lobby` config, open the `Settings/Developer` tab and in the `Singleplayer` option choose `Beyond All Reason Dev`. The application title should change to `Beyond All Reason Dev`.
4. Choose Skirmish as you normally would - this will put you in a match against one Null AI by default - and start it. This should start Beyond All Reason with your local development version. You should see `Beyond All Reason $VERSION` in your window title.

## Tips for BYAR-Chobby development:

1. Use Zerobrane Studio dev env, open up any chobby Beyond-All-Reason\data\*.lua file with Zerobrane studio, then set Project->Project Directory->From current file
2. This allows you to ctrl+shift+f to find any text in all of chobby, useful
3. Do NOT try to edit anything in Chobby.sdd! If you want to edit something in Chobby.sdd that is not overwritten by the mutator BYAR-Chobby (e.g. does not exist in BYAR-Chobby.sdd), then copy it over to BYAR-Chobby.sdd first and commit it (so we have a baseline).
4. Open infolog.txt in notepad++ or anything to grep for errors.
