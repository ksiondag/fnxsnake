D:\64tass\64tass -b --m65c02 -o build/a --list=build/a.lst --labels=build/a.lbl snake.s

if ($? -eq $false) {
    Write-Error "The first command failed. Exiting..."
    exit 1
}

python .\make_pgz.py .\build\a

& 'C:\Program Files\C256 Foenix Project\FoenixIDE\FoenixIDE.exe' -b jr
