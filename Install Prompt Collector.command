#!/bin/bash
# Double-click installer for Prompt Collector for Draw Things.
set -euo pipefail

APP_NAME="Prompt Collector"
SERVICE_NAME="Prompt Collector (Draw Things)"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SCRIPT="$SOURCE_DIR/prompt_collector.py"
INSTALL_DIR="$HOME/Library/Application Support/$APP_NAME"
SERVICES_DIR="$HOME/Library/Services"
WORKFLOW_DIR="$SERVICES_DIR/$SERVICE_NAME.workflow"

if [[ ! -f "$SOURCE_SCRIPT" ]]; then
  echo "Installation stopped: prompt_collector.py is missing."
  read -r -p "Press Return to close…" _
  exit 1
fi

echo "Installing $SERVICE_NAME…"
mkdir -p "$INSTALL_DIR" "$SERVICES_DIR"
cp "$SOURCE_SCRIPT" "$INSTALL_DIR/prompt_collector.py"
chmod 755 "$INSTALL_DIR/prompt_collector.py"
rm -rf "$WORKFLOW_DIR"
mkdir -p "$WORKFLOW_DIR/Contents"

# A Finder Quick Action is an Automator workflow bundle. Generating it here
# avoids asking the user to open Automator or paste any code.
/usr/bin/python3 - "$WORKFLOW_DIR" "$INSTALL_DIR/prompt_collector.py" "$SERVICE_NAME" <<'PYTHON'
import plistlib
import sys
import uuid
from pathlib import Path

workflow_dir = Path(sys.argv[1])
script_path = sys.argv[2]
service_name = sys.argv[3]
input_uuid = str(uuid.uuid4()).upper()
output_uuid = str(uuid.uuid4()).upper()
action_uuid = str(uuid.uuid4()).upper()

action = {
    "AMAccepts": {"Container": "List", "Optional": False,
                  "Types": ["com.apple.cocoa.path"]},
    "AMActionVersion": "1.0",
    "AMApplication": ["Automator"],
    "AMLargeIconName": "RunShellScript",
    "AMParameterProperties": {
        "COMMAND_STRING": {}, "CheckedForUserDefaultShell": {},
        "inputMethod": {}, "shell": {}, "source": {},
    },
    "AMProvides": {"Container": "List", "Types": ["com.apple.cocoa.path"]},
    "ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
    "ActionName": "Run Shell Script",
    "ActionParameters": {
        "COMMAND_STRING": f'/usr/bin/python3 "{script_path}" "$@"',
        "CheckedForUserDefaultShell": True,
        "inputMethod": 1,
        "shell": "/bin/bash",
        "source": "",
    },
    "BundleIdentifier": "com.apple.RunShellScript",
    "CFBundleVersion": "2.0.3",
    "CanShowSelectedItemsWhenRun": False,
    "CanShowWhenRun": True,
    "Category": ["AMCategoryUtilities"],
    "Class Name": "RunShellScriptAction",
    "InputUUID": input_uuid,
    "Keywords": ["Shell", "Script", "Run"],
    "OutputUUID": output_uuid,
    "UUID": action_uuid,
    "UnlocalizedApplications": ["Automator"],
    "arguments": {},
    "isViewVisible": True,
    "location": "529.000000:620.000000",
    "nibPath": "/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib",
}

workflow = {
    "AMApplicationBuild": "523",
    "AMApplicationVersion": "2.10",
    "AMDocumentVersion": "2",
    "actions": [{"action": action, "isViewVisible": True}],
    "connectors": {},
    "workflowMetaData": {
        "workflowTypeIdentifier": "com.apple.Automator.servicesMenu",
        "serviceInputTypeIdentifier": "com.apple.Automator.fileSystemObject",
        "serviceApplicationBundleID": "com.apple.finder",
    },
}

info = {
    "CFBundleName": service_name,
    "CFBundleIdentifier": "io.github.quick-eyed-sky.prompt-collector",
    "NSServices": [{
        "NSMenuItem": {"default": service_name},
        "NSMessage": "runWorkflowAsService",
        "NSSendFileTypes": ["public.png"],
    }],
}

with (workflow_dir / "Contents" / "document.wflow").open("wb") as file:
    plistlib.dump(workflow, file)
with (workflow_dir / "Contents" / "Info.plist").open("wb") as file:
    plistlib.dump(info, file)
PYTHON

# Tell macOS to refresh its Services / Quick Actions index.
/System/Library/CoreServices/pbs -update 2>/dev/null || true

echo
echo "Installed."
echo "In Finder: select a Draw Things PNG, right-click it, then choose"
echo "Quick Actions > $SERVICE_NAME."
echo
read -r -p "Press Return to close…" _
