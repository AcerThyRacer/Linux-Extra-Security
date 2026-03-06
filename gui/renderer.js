const { ipcRenderer } = require('electron');

document.addEventListener('DOMContentLoaded', () => {
  const themeSelector = document.getElementById('theme');
  const body = document.body;
  const cmdBtns = document.querySelectorAll('.cmd-btn');
  const actionTitle = document.getElementById('current-action');
  const actionDesc = document.getElementById('action-desc');
  const executeBtn = document.getElementById('execute-btn');
  const terminal = document.getElementById('terminal');
  const clearBtn = document.getElementById('clear-btn');
  const dryRunCheck = document.getElementById('dry-run');
  const autoYesCheck = document.getElementById('auto-yes');

  let currentCommand = null;

  // Theme Switching
  themeSelector.addEventListener('change', (e) => {
    body.className = e.target.value;
    terminal.innerHTML += `> Theme changed to ${e.target.options[e.target.selectedIndex].text}\n`;
    scrollToBottom();
  });

  // Command Selection
  cmdBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      cmdBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      currentCommand = btn.getAttribute('data-cmd');
      actionTitle.innerText = btn.innerText;
      actionDesc.innerText = btn.getAttribute('data-desc');
      executeBtn.disabled = false;
    });
  });

  // Execute Command
  executeBtn.addEventListener('click', () => {
    if (!currentCommand) return;

    let fullCommand = `./bin/linux-extra-security`;

    if (dryRunCheck.checked) {
      fullCommand += ` --dry-run`;
    }

    if (autoYesCheck.checked) {
      fullCommand += ` --yes`;
    }

    fullCommand += ` ${currentCommand}`;

    executeBtn.disabled = true;
    executeBtn.innerText = 'Executing...';
    terminal.classList.add('loading');

    terminal.innerHTML += `\n$ ${fullCommand}\n`;
    scrollToBottom();

    // Send command to main process
    ipcRenderer.send('execute-command', fullCommand);
  });

  // Handle stdout from main process
  ipcRenderer.on('command-output', (event, data) => {
    terminal.innerHTML += escapeHtml(data);
    scrollToBottom();
  });

  // Handle command finish
  ipcRenderer.on('command-finished', (event, code) => {
    terminal.classList.remove('loading');
    terminal.innerHTML += `\n[Process exited with code ${code}]\n`;
    scrollToBottom();

    executeBtn.disabled = false;
    executeBtn.innerText = 'Execute Command';
  });

  // Clear Terminal
  clearBtn.addEventListener('click', () => {
    terminal.innerHTML = '';
  });

  // Utilities
  function scrollToBottom() {
    terminal.scrollTop = terminal.scrollHeight;
  }

  function escapeHtml(unsafe) {
    return unsafe
         .replace(/&/g, "&amp;")
         .replace(/</g, "&lt;")
         .replace(/>/g, "&gt;")
         .replace(/"/g, "&quot;")
         .replace(/'/g, "&#039;");
  }
});
