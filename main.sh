#!/bin/bash

DIRECTORY="$(readlink -f "$(dirname "$0")")"

error() {
  echo -e "\e[91m$1\e[39m" | sed 's|<b>||g' | sed 's|</b>||g' 1>&2
  zenity --error --width 300 --text "$(echo -e "$1" | sed 's/&/&amp;/g' | tr -d '<>')"
  exit 1
}

warning() {
  echo -e "\e[91m$1\e[39m" | sed 's|<b>||g' | sed 's|</b>||g' 1>&2
  zenity --error --width 300 --text "$(echo -e "$1" | sed 's/&/&amp;/g' | tr -d '<>')"
}

newfile() {
  #set defaults - variable 1 can change filename if set, otherwise it's new-autostart.desktop
  filename='new-autostart.desktop'
  name='My New Autostarted Program'
  exec='chromium-browser https://my-favorite-site.com'
  #remember what these variables were originally set to, to make sure the user changes them all
  default_filename="$filename"; default_name="$name"; default_exec="$exec"
  window_text="Create new autostart file."
  
  #make filename greyed out if it was provided by the command line
  if [ ! -z "$1" ];then
    filename="$1"
    filenamelocked=1
    
    #read other values in if filename already exists
    if [ -f "$autostartdir/$filename" ];then
      window_text="Edit existing autostart file."
      name="$(cat "$autostartdir/$filename" | grep '^Name=' | sed 's/Name=//g' | head -n1)"
      exec="$(cat "$autostartdir/$filename" | grep '^Exec=' | sed 's/Exec=//g' | head -n1)"
      
      #and display an "open in text editor" button
      buttons=(--button="Text Editor"!"${DIRECTORY}/icons/txt.png"!"Opens <b>$autostartdir/$filename</b> in a text editor for manual modifications.":2 --button=Cancel:1 --button=OK!!"Write these new values to the autostart file":0)
    fi
  else
    filenamelocked=0
  fi
  
  while true;do
    output="$(yad "${yadflags[@]}" --form --width=450 \
      --text="$window_text" \
      --field="Filename"$([ $filenamelocked == 1 ] && echo ':RO') "$filename" \
      --field="Display name" "$name" \
      --field="Command to run" "$exec" \
      --field="For multiple commands, do this:"$'\n'"<big><b>bash -c "\""</b>command1<b>;</b> command2<b>;</b> command3<b>"\""</b></big>":LBL "" \
      "${buttons[@]}")"
    button=$?
    [ $button != 0 ] && break
    
    filename="$(echo "$output" | sed -n 1p)"
    name="$(echo "$output" | sed -n 2p)"
    exec="$(echo "$output" | sed -n 3p)"
    
    echo -e "Data received:\nFileneme: $filename\nName: $name\nCommand: $exec\nButton: $button"
    
    #run a bunch of tests on the output values and ensure they are valid before exiting the loop
    go_back_and_fix=0
    if [ "$filename" == "$default_filename" ];then
      yad "${yadflags[@]}" --text="  The filename must be changed to something unique other than "\""$default_filename"\"".  " --button="Got it."
      go_back_and_fix=1
    fi
    if [ "$name" == "$default_name" ];then
      yad "${yadflags[@]}" --text="  The name must be changed to something unique other than "\""$default_name"\"".  " --button="Got it."
      go_back_and_fix=1
    fi
    if [ "$exec" == "$default_exec" ];then
      yad "${yadflags[@]}" --text="  The command must be changed to something unique other than "\""$default_exec"\"".  " --button="Got it."
      go_back_and_fix=1
    fi
    if [ -z "$filename" ] || [ -z "$exec" ];then
      yad "${yadflags[@]}" --text="  Filename and command fields cannot be left blank.  " --button="Got it."
      go_back_and_fix=1
    fi
    if echo "$filename" | grep -q ' ' ;then
      yad "${yadflags[@]}" --text="  Filename cannot contain a space character.  " --button="Got it."
      go_back_and_fix=1
    fi
    if ! echo "$filename" | grep -q '.desktop$' ;then
      yad "${yadflags[@]}" --text='  Filename must end in "<b>.desktop</b>".  ' --button="Got it."
      go_back_and_fix=1
    fi
    
    if [ "$go_back_and_fix" == 0 ];then
      break #exit loop if all above tests passed
    fi
  done
  
  #skip everything in here if Cancel was clicked while creating a new autostart file, thereby breaking out of the loop
  if [ $button == 0 ] && [ ! -f "$autostartdir/$filename" ];then
    #create new file
    echo "[Desktop Entry]
Name=$name
Exec=$exec
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
Hidden=false" > "$autostartdir/$filename"
    echo "Created new autostart file at $autostartdir/$filename"
    motd="<b>Success</b> New autostart file (<b>$filename</b>) created."
    echo -e "File contains:\n$(cat "$autostartdir/$filename" | sed 's/^/ /g')\n"
  elif [ $button == 0 ] && [ -f "$autostartdir/$filename" ];then
    #edit existing file with new values
    echo "$(cat "$autostartdir/$filename" | sed "s|Name=.*|Name=$name|g" | sed "s|Exec=.*|Exec=$exec|g")" > "$autostartdir/$filename"
    
    echo "Edited existing autostart file at $autostartdir/$filename"
    echo -e "File contains:\n$(cat "$autostartdir/$filename" | sed 's/^/ /g')\n"
    motd="<b>Success</b> Pre-existing autostart file (<b>$filename</b>) has been updated with new values."
  elif [ $button == 2 ];then
    #open in text editor
    mousepad "$autostartdir/$filename" || leafpad "$autostartdir/$filename" || geany "$autostartdir/$filename" || xdg-open "$autostartdir/$filename" || error "Failed to find a text editor to open <b>$autostartdir/$filename</b>"
  fi
  
}

autostartdir="$HOME/.config/autostart"
mkdir -p "$autostartdir"

command -v yad >/dev/null || (echo "Installing 'yad'..." ; sudo apt update && sudo apt install -y yad || error "Failed to install yad!")
yadflags=(--center --title="AutoStar" --separator='\n' --window-icon="${DIRECTORY}/icons/autostar.png")

#default message displayed on list of autostart files
motd="Autostart folder: <b>$autostartdir</b>"

#check for updates and auto-update if the no-update files does not exist
if [ ! -f "${DIRECTORY}/no-update" ];then
  prepwd="$(pwd)"
  cd "$DIRECTORY"
  localhash="$(git rev-parse HEAD)"
  latesthash="$(git ls-remote https://github.com/Botspot/autostar HEAD | awk '{print $1}')"
  
  if [ "$localhash" != "$latesthash" ] && [ ! -z "$latesthash" ] && [ ! -z "$localhash" ];then
    echo "AutoStar is out of date. Downloading new version..."
    echo "To prevent update checking from now on, create a file at ${DIRECTORY}/no-update"
    sleep 1
    
    #get file hash of this running script to compare it later
    oldhash="$(shasum "$0")"
    
    echo "running 'git pull'..."
    git pull
    
    if [ "$oldhash" == "$(shasum "$0")" ];then
      #this script not modified by git pull
      echo "git pull finished. Proceeding..."
    else
      echo "git pull finished. Reloading script..."
      #run updated script in background
      ( "$0" "$@" ) &
      exit 0
    fi
  fi
  cd "$prepwd"
fi

if [ ! -f ~/.local/share/applications/autostar.desktop ];then
  echo "Creating menu button..."
  mkdir -p ~/.local/share/applications
  echo "[Desktop Entry]
Name=AutoStar
Comment=Conveniently manage programs to launch on startup
Exec=$0
Icon=${DIRECTORY}/icons/autostar.png
Terminal=false
Type=Application
Categories=System;Settings;
StartupNotify=true" > ~/.local/share/applications/autostar.desktop
fi

if [ "$1" == setup ];then
  echo "AutoStar setup complete."
  exit 0
fi

IFS=$'\n'
while true;do
  echo -n "Creating file list... "
  LIST=''
  for file in $(find "$autostartdir" -type f);do
    filecontents="$(cat "$file" | tr '\r' '\n')"
    name="$(echo "$filecontents" | grep '^Name=' | sed 's/Name=//g' | head -n1)"
    exec="$(echo "$filecontents" | grep '^Exec=' | sed 's/Exec=//g' | head -n1)"
    LIST="$LIST
${DIRECTORY}/icons/txt.png
$(basename "$file")
<b>$name</b>
$(date -r "$file" '+%b %d, %Y')
$exec"
  done
  echo Done
  
  filename="$(echo "$LIST" | tail -n +2 | yad "${yadflags[@]}" --width=750 --height=300 \
    --text="$motd" \
    --list --column=:IMG --column=File --column=Name --column="Date added" --column=command --print-column='2' \
    --button=New!"${DIRECTORY}/icons/new.png"!"Create a new autostart file":4 \
    --button=Delete!"${DIRECTORY}/icons/trash.png"!"Move the selected autostart file to the Trash":2 \
    --button=Edit!"${DIRECTORY}/icons/edit.png"!"Modify an existing autostart file.":0)"
  button=$?
  
  echo "Chosen filename: '$filename'"
  
  if [ $button == 4 ];then
    #set example default variables for use in the yad window
    echo "New autostart file"
    newfile
    
  elif [ $button == 2 ];then
    echo "Delete autostart file"
    if [ -z "$filename" ];then
      echo "One autostart file must be selected."
      yad "${yadflags[@]}" --text="  One autostart file must be selected for this Delete button to do anything.  " --button="Got it."
    else
      errors="$(gio trash "$autostartdir/$filename" 2>&1)"
      [ $? != 0 ] && warning "Failed to move <b>$autostartdir/$filename</b> to Trash!\nErrors: $errors"
    fi
  elif [ $button == 0 ];then
    echo "Edit autostart file"
    if [ -z "$filename" ];then
      echo "One autostart file must be selected."
      yad "${yadflags[@]}" --text="  One autostart file must be selected for this Edit button to do anything.  " --button="Got it."
    else
      newfile "$filename"
    fi
  else
    echo "Exiting now."
    exit 0
  fi
  sync #wait for filesystem changes before re-scanning
done



