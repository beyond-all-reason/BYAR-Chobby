This is how you can measure incoming command performance:
1. Disable auto-login in the lobby.
2. Move these `.ipynb` scripts to the Spring data directory so they have direct access to the infolog file.
3. Enable command capture: open `dbg_profile.lua` and set `ENABLED` and `CAPTURE_COMMANDS` to `true`.
4. Collect data: Run the lobby once, grab some real-world command data.
5. Parse data: Open `commands.ipynb` and run all cells. Copy the generated `commands.json` to your Spring data directory (e.g. `"~/Beyond All Reason/"` on Linux)
6. Set streaming mode: open `dbg_profile.lua` and set `STREAM_COMMANDS` to `true` and `CAPTURE_COMMANDS` to `false`. Optionally set `AUTO_QUIT` to `true` so it auto-exists when finished.
7. Measure: open Chobby again and have it stream all the commands.
8. Parse measurements: Open `time_measurements.ipynb` and execute all but the last cell. You may want to store your baseline as `times_orig.log` for easier comparison later.

Steps 1~6 are preparation steps. You are likely to repeat only steps 7 & 8 as you perform optimization.
