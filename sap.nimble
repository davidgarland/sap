# Package

version       = "0.1.0"
author        = "davidgarland"
description   = "SAP: Summer AI Project"
license       = "MIT"
srcDir        = "src"
bin           = @["sap"]

# Dependencies

requires "nim >= 0.18.0"
requires "arraymancer"
requires "sdl2"
requires "sol"

task clean, "Cleans up files.":
  exec "rm -rf sap"
