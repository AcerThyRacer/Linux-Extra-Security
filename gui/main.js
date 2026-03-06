const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const sudo = require('sudo-prompt');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1000,
    height: 700,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    },
    icon: path.join(__dirname, 'assets', 'icon.png')
  });

  mainWindow.loadFile('index.html');

  // Open DevTools in development
  // mainWindow.webContents.openDevTools();

  mainWindow.on('closed', function () {
    mainWindow = null;
  });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', function () {
  if (mainWindow === null) {
    createWindow();
  }
});

// IPC Handler for Command Execution
ipcMain.on('execute-command', (event, commandStr) => {
  const isSudo = commandStr.includes('apply') || commandStr.includes('guided') || commandStr.includes('rollback');
  const isDryRun = commandStr.includes('--dry-run');

  // Parse command logic
  // Command structure expected from UI: `./bin/linux-extra-security [--dry-run] [--yes] <module> <action>`
  const parts = commandStr.trim().split(/\s+/);

  // Ensure we run from the project root instead of gui directory
  const projectRoot = path.join(__dirname, '..');

  const options = {
    cwd: projectRoot,
    env: process.env
  };

  if (!isDryRun && isSudo) {
    // Requires Root
    event.sender.send('command-output', 'Requesting root privileges for execution...\n');

    // sudo-prompt takes the full command string
    sudo.exec(`cd "${projectRoot}" && ${commandStr}`, { name: 'Linux Extra Security' }, (error, stdout, stderr) => {
      if (error) {
        event.sender.send('command-output', `Error: ${error.message}\n`);
        event.sender.send('command-finished', 1);
        return;
      }

      if (stdout) {
        event.sender.send('command-output', stdout);
      }

      if (stderr) {
        event.sender.send('command-output', stderr);
      }

      event.sender.send('command-finished', 0);
    });
  } else {
    // Does not require root (e.g., dry-run, plan, show-status)
    const cmd = parts.shift();
    const child = spawn(cmd, parts, options);

    child.stdout.on('data', (data) => {
      event.sender.send('command-output', data.toString());
    });

    child.stderr.on('data', (data) => {
      event.sender.send('command-output', data.toString());
    });

    child.on('error', (err) => {
      event.sender.send('command-output', `Failed to start child process: ${err}\n`);
    });

    child.on('close', (code) => {
      event.sender.send('command-finished', code);
    });
  }
});
