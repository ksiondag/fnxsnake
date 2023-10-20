64tass --long-address --flat -b --m65816 --intel-hex -o build/snake.hex --list=build/snake.lst --labels=build/snake.lbl snake.s

if ($? -eq $false) {
    Write-Error "The first command failed. Exiting..."
    exit 1
}

FoenixIDE.exe -b jr816 -k .\build\snake.hex
