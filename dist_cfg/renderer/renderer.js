const {app, ipcRenderer} = require('electron');
const fs = require('fs');
const path = require("path");

const log = require('electron-log');

const EXTS_DIR = "exts";

const normalizedPath = path.join(__dirname, EXTS_DIR);
fs.readdirSync(normalizedPath).forEach(function(file) {
  const extPath = `./${EXTS_DIR}/` + file;
  if (extPath.endsWith(".js")) {
    log.info(`Including extension: ${extPath}...`);
    require(extPath);
  }
});

function formatBytes(bytesFirst, bytesSecond, decimals) {
  const sizes = ['Bytes', 'KiB', 'MiB', 'GiB', 'TiB'];
  const k = 1024;

  var strFirst;
  var strSecond;
  var strUnit;

  if (bytesSecond == 0) {
    strFirst = '0';
    strSecond = '0';
    strUnit = sizes[0];
  } else {
    const i = Math.floor(Math.log(bytesSecond) / Math.log(k));
    const dm = decimals || 2;

    strFirst  = parseFloat(bytesFirst / Math.pow(k, i)).toFixed(dm);
    strSecond = parseFloat(bytesSecond / Math.pow(k, i)).toFixed(dm);
    strUnit   = sizes[i];

    strFirst = ' '.repeat(strSecond.indexOf(".") - strFirst.indexOf(".")) + strFirst;
    strFirst = strFirst + ' '.repeat(strSecond.length - strFirst.length)
  }

  return `${strFirst} / ${strSecond} ${strUnit}`;
}

let configEnabled = true;
function setConfigEnabled(state) {
  configEnabled = state;
  if (state) {
    document.getElementById("config-select").removeAttribute("disabled");
  } else {
    document.getElementById("config-select").setAttribute("disabled", "");
  }
}

let operationInProgress = false;
function setInProgress(state) {
  setConfigEnabled(!state);
  if (state) {
    document.getElementById("btn-progress").classList.add("is-loading");
  } else {
    document.getElementById("btn-progress").classList.remove("is-loading");
  }
  operationInProgress = state;
}

const isDev = require('electron-is-dev');
function setMainTitle(title) {
  if (isDev) {
    title = `${title} (DEV)`;
  }
  document.getElementById("main-title").innerHTML = title;
}

function resetUI() {
  document.getElementById("progress-part").value = 0;
  document.getElementById("progress-full").value = 0;
  document.getElementById("progress-full").classList.remove("is-danger", "is-success");
  document.getElementById("progress-part").classList.remove("is-danger", "is-success");
  document.getElementById("progress-full").classList.add("is-primary");
  document.getElementById("progress-part").classList.add("is-primary");

  document.getElementById("lbl-progress-full").classList.remove("error");
  document.getElementById("lbl-progress-part").classList.remove("error");
  document.getElementById("lbl-progress-full").innerHTML = ''
  document.getElementById("lbl-progress-part").innerHTML = ''

  document.getElementById("btn-progress").classList.remove("is-warning");
  document.getElementById("btn-progress").classList.add("is-primary");
}

function stepError(message) {
  document.getElementById("lbl-progress-full").innerHTML = message;
  document.getElementById("lbl-progress-full").classList.add("error");
  document.getElementById("lbl-progress-part").classList.add("error");

  document.getElementById("progress-full").classList.remove("is-primary");
  document.getElementById("progress-part").classList.remove("is-primary");

  document.getElementById("progress-full").classList.add("is-danger");
  document.getElementById("progress-part").classList.add("is-danger");
  setInProgress(false);
}
window.onload = function() {

  document.getElementById('btn-progress').addEventListener('click', (event) => {
    event.preventDefault();
    if (!operationInProgress) {
      document.getElementById("lbl-progress-full").classList.remove("error");
      document.getElementById("btn-progress").classList.remove("is-warning");
      ipcRenderer.send("wizard-next");
    }
  });

  document.getElementById('btn-show-log').addEventListener('click', (event) => {
    event.preventDefault();

    const win = require('electron').remote.getCurrentWindow()
    const cl = document.getElementById("note-content").classList;
    if (cl.contains("open")) {
      cl.remove("open");
      win.setSize(800, 380 + 30);
    } else {
      cl.add("open");
      win.setSize(800, 750);
    }
  });

  document.getElementById('btn-upload-log').addEventListener('click', (event) => {
    ipcRenderer.send("log-upload-ask");
  });

  document.getElementById('btn-show-dir').addEventListener('click', (event) => {
    ipcRenderer.send("open-install-dir");
  });

  document.getElementById('config-select').addEventListener('change', (event) => {
    if (!configEnabled) {
      return;
    }
    const s = event.target;
    const selectedID = s[s.selectedIndex].id;
    const cfgName = selectedID.substring('cfg-'.length);
    ipcRenderer.send("change-cfg", cfgName);
  });
  // document.getElementById("btn-show-log").removeAttribute("tabIndex");
  // document.getElementById("btn-show-log").setAttribute("tabIndex", "-1");
  // document.getElementById('btn-show-log').addEventListener('focus', (event) => {
  //   event.preventDefault();
  //   console.log("ABC");
  //   this.blur();
  // });
}

//////////////////////////////
// Config events
//////////////////////////////

let config;
let allConfigs;

ipcRenderer.on("config", (e, c) => {
  config = c;

  document.title = config.title;
  setMainTitle(config.title);

  let buttonText;
  if (config.no_downloads) {
    // TODO: add later
    if (config.auto_start && !operationInProgress  && false) {
      buttonText = "Starting...";
    } else {
      buttonText = "Start";
    }
  } else {
    // TODO: add later
    if (config.auto_download && !operationInProgress && false) {
      if (config.auto_start) {
        buttonText = "Updating and Starting...";
      } else {
        buttonText = "Updating...";
      }
    } else {
      if (config.auto_start) {
        buttonText = "Update & Start";
      } else {
        buttonText = "Update";
      }
    }
  }

  resetUI();
  document.getElementById("btn-progress").innerHTML = buttonText;
  document.getElementById(`cfg-${config.package.id}`).selected = true;
  // document.getElementById("current_config").innerHTML = `Config: ${config.package.display}`;
});

ipcRenderer.on("all-configs", (e, ac) => {
  allConfigs = ac;

  var cfgSelect = document.getElementById("config-select");

  allConfigs.forEach((cfg) => {
    var cfgElement = document.createElement("option");
    cfgElement.id = `cfg-${cfg.package.id}`;
    cfgElement.appendChild(document.createTextNode(cfg.package.display));

    cfgSelect.appendChild(cfgElement);
  });
});

//////////////////////////////
// Wizard events
//////////////////////////////

let steps;
let currentStep = 0;

ipcRenderer.on("wizard-list", (e, s) => {
  steps = s;
});

ipcRenderer.on("wizard-started", (e) => {
  currentStep = 0;
  setInProgress(true);
});

ipcRenderer.on("wizard-stopped", (e) => {
  setInProgress(false);
});

ipcRenderer.on("wizard-finished", (e) => {
  document.getElementById("btn-progress").innerHTML = "Start";
  document.getElementById("lbl-progress-full").innerHTML = 'Download complete'
  document.getElementById("lbl-progress-part").innerHTML = ''

  document.getElementById("progress-part").value = 100;
  document.getElementById("progress-full").value = 100;

  document.getElementById("progress-part").classList.remove("is-primary", "is-danger");
  document.getElementById("progress-part").classList.add("is-success");

  document.getElementById("progress-full").classList.remove("is-primary", "is-danger");
  document.getElementById("progress-full").classList.add("is-success");
  //document.getElementById("progress-part").value = parseInt(100 * currentStep / steps.length);
});

ipcRenderer.on("wizard-next-step", (e, step) => {
  document.getElementById("lbl-progress-part").innerHTML = '';
  document.getElementById("lbl-progress-full").innerHTML =
    `Step ${currentStep} of ${steps.length} Checking for download: ${step.name} `;
  document.getElementById("progress-full").value = Math.round(100 * currentStep / steps.length);
  currentStep++;
});

//////////////////////////////
// Download events
//////////////////////////////

ipcRenderer.on("dl-started", (e, downloadItem) => {
  document.getElementById("lbl-progress-full").innerHTML =
    `Step ${currentStep} of ${steps.length}: Downloading ${downloadItem} `;
    document.getElementById("progress-part").classList.remove("is-success", "is-danger");
    document.getElementById("progress-part").classList.add("is-primary");
});

ipcRenderer.on("dl-progress", (e, downloadItem, current, total) => {
  document.getElementById("progress-part").value = Math.round(100 * current / total);

  const step = currentStep + current / total - 1;
  document.getElementById("progress-full").value = Math.round(100 * step / steps.length);

  if (downloadItem != "autoUpdate") {
    document.getElementById("lbl-progress-part").innerHTML = `${formatBytes(current, total)}`;
  } else {
    document.getElementById("lbl-progress-part").innerHTML = `${current.toFixed(2)}%`;
  }
});

ipcRenderer.on("dl-finished", (e, downloadItem) => {
  document.getElementById("progress-part").value = 100;
  document.getElementById("progress-part").classList.remove("is-primary", "is-danger");
  document.getElementById("progress-part").classList.add("is-success");
});

ipcRenderer.on("dl-failed", (e, downloadItem, msg) => {
  stepError(`Step ${currentStep} of ${steps.length}: ${msg}`);
});

//////////////////////////////
// Launch events
//////////////////////////////

ipcRenderer.on("launch-started", (e) => {
  setInProgress(true);
  document.getElementById("lbl-progress-full").innerHTML = `Launching`;
  // specifically enable config editing after launch
  setConfigEnabled(true);
});

ipcRenderer.on("launch-finished", (e) => {
  setInProgress(false);
});

ipcRenderer.on("launch-failed", (e, msg) => {
  stepError(`${msg}`);
});

//////////////////////////////
// Log events
//////////////////////////////

const {format} = require('util');
const util = require('util');
ipcRenderer.on("log", (e, msg) => {
  var para = document.createElement("p");
  var text = format.apply(util, msg.data);
  var node = document.createTextNode(`[${msg.date} ${msg.level}] ${text}`);
  para.appendChild(node);
  para.classList.add(msg.level);
  var element = document.getElementById("note-content");
  element.appendChild(para);
});