:: Set the path to the fs folder
set fsDir=D:\Users\StjerneIdioten\My Documents\my games\FarmingSimulator2019
:: Run linux script which cleans mods folder, zips mod and adds it to mods folder
wsl bash -ic ./deploy.sh
:: Go to the fs dir
cd "%fsDir%"
:: Open the log file in notepad++
start notepad++ "%cd%"/log.txt
:: Launch FS
START C:\"Program Files (x86)"\Steam\steamapps\common\"Farming Simulator 19"\FarmingSimulator2019