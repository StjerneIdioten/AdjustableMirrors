#Save current mod root
modDir=$(pwd)

#Go to the mods folder
cd "$FS_MOD_DIR"

#Clean mod folder
rm ./*

#Go back to mod root
cd "$modDir"

#Go into folder containing all files for zip
cd modfiles

#Zip all files
zip -r FS19_AdjustableMirrors.zip .

#Move mod into mods directory
mv -f FS19_AdjustableMirrors.zip "${FS_MOD_DIR}/"
