# BYAR-Chobby

BYAR mutator for [Chobby](https://github.com/spring-chobby/chobby)

# Download links

- [Windows] and [Linux] https://github.com/beyond-all-reason/BYAR-Chobby/releases

# Developing the Lobby

1. Download using one of the links above and start the application.

2. Start the application once and launch the lobby. This will download the engine and other dependencies.

3. Open the install directory (there's a button for that in the launcher), and create a `games` directory, then clone this repository inside the `games` directory:

**NOTE**: The `games` directory is `data/games` under windows, and just `games` under Linux.

```
git clone https://github.com/beyond-all-reason/BYAR-Chobby.git BYAR-Chobby.sdd
```

This should result in the following directory being present: `/path/to/install/dir/data/games/BYAR-Chobby.sdd/` under . (`Beyond-All-Reason\data\games\BYAR-Chobby.sdd\LuaMenu\configs\gameConfig` should be a correct path)

4. Choose the `Dev Lobby` config from the launcher's top right dropdown menu which will run the lobby version on your PC. You can now develop and test any BYAR specific lobby functionality.

To enable debugmode, make an empty `devmode.txt` in the already used game install directory (`/data/`), and then the `Settings/Developer` tab will appear in the lobby. All debug messages are visible in th Debug chat panel.

# Developing the Game

1. Make sure you've first finished setting up the lobby development environment (previous section)

2. Open the install directory, and inside the `games` directory clone the BAR *game* repository:

```
git clone https://github.com/beyond-all-reason/Beyond-All-Reason.git BAR.sdd
```

3. Start Chobby with `Dev Lobby` config, open the `Settings/Developer` tab and in the `Singleplayer` option choose `Beyond All Reason Dev`. The application title should change to `Beyond All Reason Dev`.

4. Choose Skirmish as you normally would - this will put you in a match against one Null AI by default - and start it. This should start Beyond All Reason with your local development version. You should see `Beyond All Reason $VERSION` in your window title.

## Tips for BYAR-Chobby development:

1. Use Zerobrane Studio dev env, open up any chobby Beyond-All-Reason\data\*.lua file with Zerobrane studio, then set Project->Project Directory->From current file
2. This allows you to ctrl+shift+f to find any text in all of chobby, useful
3. Open infolog.txt in notepad++ or anything to grep for errors.

## How to make new launcher releases:

Note: Windows executables are signed, this procedure can be done only by one of the developers that have code signing cerificate.

1. Modify a file in the `dist_cfg` folder (https://github.com/beyond-all-reason/BYAR-Chobby/tree/master/dist_cfg) on the `master` branch to trigger a launcher build. It should start a new action here: https://github.com/beyond-all-reason/BYAR-Chobby/actions
2. Wait until the build **completely** finishes (the action should be green and have a check), otherwise you might create an incomplete release.
3. Make a pre-release by finding the latest Draft here https://github.com/beyond-all-reason/BYAR-Chobby/releases, open it:
   - click `Edit draft`
   - Mark it as "pre-release"
   - then `Publish Release`
4. Use `build/sign_release.py` to sign the new launcher binary, e.g.

   ```
   python ./build/sign_release.py --signtool 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\signtool.exe' v1.1832.0
   ```

5. Edit release:
   - replace the Windows executable and `latest.yml` file with the singed version and new generated `latest.yml`
   - untick pre-release and mark it as latest release
6. Send new download links to .exe and .AppImage to BAR discord #website so download links on website can be updated.
7. Note that pr-downloader is fetched from https://github.com/beyond-all-reason/spring-launcher

### Contributing

All contributors are welcome; if you spot an issue or bug open an issue in this repo or visit *#chobby* channel on [BAR Discord](https://discord.gg/beyond-all-reason). Pull requests are also welcome; even if it's just a spelling mistake, however if using AI tools please follow our [AI Usage Policy](/AI_POLICY.md).
