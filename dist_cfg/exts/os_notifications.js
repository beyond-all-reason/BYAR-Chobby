'use strict';

// Shows an OS toast notification and/or flashes the game's taskbar icon when
// Chobby sends an "Alert" command (ring, battle starting, returned to lobby).
// Chobby decides *when* to alert and sends the final message text; this
// extension decides *whether* to show it: nothing is shown while the game
// window is in the foreground, because the user is already looking at it.

const { app, Notification } = require('electron');
const { execFile } = require('child_process');
const fs = require('fs');
const path = require('path');

const { bridge } = require('../spring_api');
const { log } = require('../spring_log');

const DEDUPE_MS = 3000;
const PS_TIMEOUT_MS = 10000;

let toastTitle = 'Beyond All Reason';
try {
	toastTitle = require('../launcher_config').config.title || toastTitle;
} catch (err) {
	log.warn(`os_notifications: cannot read launcher config title: ${err}`);
}

// Windows toast attribution requires the AppUserModelID to match the installed
// shortcut's AUMID, which electron-builder sets to build.appId (generated as
// 'com.springrts.launcher.<owner>.<repo>' by the game repo's make_package_json).
// Packaged builds strip the build key from package.json, but app-update.yml
// next to the asar carries the same owner/repo pair.
function resolveAppId () {
	try {
		const appId = require('../../package.json').build.appId;
		if (appId) {
			return appId;
		}
	} catch (err) {
		// packaged build; fall through to app-update.yml
	}
	try {
		const yml = fs.readFileSync(path.join(process.resourcesPath, 'app-update.yml'), 'utf8');
		const owner = yml.match(/^owner:\s*(\S+)/m);
		const repo = yml.match(/^repo:\s*(\S+)/m);
		if (owner && repo) {
			return `com.springrts.launcher.${owner[1]}.${repo[1]}`;
		}
	} catch (err) {
		log.warn(`os_notifications: cannot read app-update.yml: ${err}`);
	}
	return 'com.springrts.launcher';
}

if (process.platform === 'win32') {
	app.setAppUserModelId(resolveAppId());
}

// The engine window belongs to a separate spring/recoil process the launcher
// spawned, so Electron's flashFrame cannot reach it; a PowerShell one-shot
// does the foreground check and FlashWindowEx instead.
// Exit code contract: 10 = an engine window is foreground (skip everything),
// 0 = not foreground (flash performed if requested, caller may toast).
function buildScript (flash) {
	return `
$ErrorActionPreference = 'Stop'
$doFlash = $${flash ? 'true' : 'false'}
Add-Type @"
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential)]
public struct FLASHWINFO { public uint cbSize; public IntPtr hwnd; public uint dwFlags; public uint uCount; public uint dwTimeout; }
public static class Win32 {
	[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
	[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
	[DllImport("user32.dll")] public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);
}
"@
$procs = @(Get-Process | Where-Object { ($_.ProcessName -like 'spring*' -or $_.ProcessName -like 'recoil*') -and $_.MainWindowHandle -ne 0 })
if ($procs.Count -eq 0) { exit 0 }
$fg = [Win32]::GetForegroundWindow()
$fgProcId = [uint32]0
[void][Win32]::GetWindowThreadProcessId($fg, [ref]$fgProcId)
foreach ($p in $procs) { if ($p.Id -eq $fgProcId) { exit 10 } }
if ($doFlash) {
	foreach ($p in $procs) {
		$fi = New-Object FLASHWINFO
		$fi.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($fi)
		$fi.hwnd = $p.MainWindowHandle
		$fi.dwFlags = 15
		$fi.uCount = 0
		$fi.dwTimeout = 0
		[void][Win32]::FlashWindowEx([ref]$fi)
	}
}
exit 0
`;
}

// Resolves true when an engine window is foreground (user is viewing).
// -EncodedCommand sidesteps every quoting/escaping concern of -Command.
function checkFocusAndFlash (flash) {
	return new Promise(resolve => {
		const encoded = Buffer.from(buildScript(flash), 'utf16le').toString('base64');
		execFile('powershell.exe',
			['-NoProfile', '-NonInteractive', '-EncodedCommand', encoded],
			{ timeout: PS_TIMEOUT_MS, windowsHide: true },
			error => {
				if (!error) {
					resolve(false);
				} else if (error.code === 10) {
					resolve(true);
				} else {
					log.warn(`os_notifications: focus check failed (${error.message}), showing toast anyway`);
					resolve(false);
				}
			});
	});
}

function showToast (message) {
	if (!Notification.isSupported()) {
		return;
	}
	new Notification({ title: toastTitle, body: message }).show();
}

function handleAlert (message, toast, flash) {
	if (process.platform !== 'win32') {
		// TODO: add Linux/macOS side focus check + toast
		return Promise.resolve();
	}
	return checkFocusAndFlash(flash).then(isForeground => {
		if (!isForeground && toast) {
			showToast(message);
		}
	});
}

const recentAlerts = new Map();
let queue = Promise.resolve();

bridge.on('Alert', command => {
	command = command || {};
	const message = typeof command.message === 'string' ? command.message : '';
	const toast = !!command.toast;
	const flash = !!command.flash;
	if (message === '' || (!toast && !flash)) {
		return;
	}
	const now = Date.now();
	const last = recentAlerts.get(message);
	if (last !== undefined && now - last < DEDUPE_MS) {
		return;
	}
	if (recentAlerts.size > 50) {
		recentAlerts.clear();
	}
	recentAlerts.set(message, now);
	queue = queue
		.then(() => handleAlert(message, toast, flash))
		.catch(err => log.error(`os_notifications: ${err}`));
});
