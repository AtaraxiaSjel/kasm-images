#!/bin/bash
# Replaces the Thunar file manager with a no-op script. A running file manager
# could let a user drag a downloaded file out of the browser and browse the
# container filesystem, so the binary is neutralized as a breakout mitigation.
set -e

cp /dockerstartup/install/close_browser_breakout_via_file_manager/script_that_just_exits /usr/bin/thunar
