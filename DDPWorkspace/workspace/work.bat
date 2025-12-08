..\cue2ddp.exe "CDImage.cue" "production"

ren "production\SD" "PQDESCR"

set /p backup="Enter Backup Folder under M:\DDP\, ex: 岑寧兒\岑寧兒 - HERE: "

robocopy /MOV "production" "M:\DDP\%backup%"

start "" "M:\DDP\%backup%"

pause;