# SWB 2.0
SWB - it is new generation command tool to bruteforce WiFi networks via android device. Reworked by @Mirivan with ❤️. ROOT Required!

## Features
 - [x] Pure bash
 - [x] Insane speed (up to 120 password/minute, depends on the network chip and network signal strength)
 - [x] WPA2/WPA3 support
 - [x] 2.4/5/6 GHz networks support

## Reworked by Mirivan
- Termux environment is explicitly specified
- Constants and readability
- Typo fixes
- Added interval and WPA version validity checks
- Neat output
- Filtering and counting valid passwords (We use grep instead of wc because we need the exact number of lines in the file, regardless of whether there is a line break at the end)
- Keys_per_second (k/s) is calculated based on start_time - it gives an idea of the speed of the search
- Fixed reading of dictionary file (Redirecting stdin/stdout/stderr prevents unnecessary messages from being printed and input from being blocked). Reading the dictionary more accurately
- The connection check is more compact and has clear context
- Adapting output on success/failure (also adding exit codes)