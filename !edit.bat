@echo off
set VSCODE_DEV=
set ELECTRON_RUN_AS_NODE=1
start \VSCode\Code.exe \VSCode\resources\app\out\cli.js --ms-enable-electron-run-as-node \vscode-workspaces\squatm.code-workspace main.6502 
