![autostar logo](https://github.com/Botspot/autostar/blob/main/icons/autostar.png?raw=true)
# AutoStar
Easily make programs launch on system startup.
Such programs are called "Autostarted programs", and the files used to do this are called "Autostart files".  
![2021-07-31-001559_1366x768_scrot](https://user-images.githubusercontent.com/54716352/127730003-6f4a6396-b5c5-459b-b843-ce56bfe58e23.png)  
This application was written by Botspot on 7/30/2021.  
## Installation:
[![badge](https://github.com/Botspot/pi-apps/blob/master/icons/badge.png?raw=true)](https://github.com/Botspot/pi-apps)  
### Or, to download manually:
```
git clone https://github.com/Botspot/autostar
```
AutoStar is portable and can be executed from anywhere on your filesystem. For simplicity, this README will assume AutoStar was downloaded to your $HOME directory.  
### First run:
```
~/autostar/main.sh
```
When running for the first time, AutoStar will:  

- Check and install dependencies: `yad`
- Add a Main menu launcher. (~/.local/share/applications/autostar.desktop) This launcher is located under the Preferences category.
- Check for updates. If the last local commit and the latest online commit do not match, AutoStar will run git pull and refresh the script if it was modified. Note: If you create a fork of this repository, you should change the github URL in the script to point to your repository. To disable update-checking, create a file at: ~/autostar/no-update.

## Usage
Note: AutoStar is so simple that it ought to be self-explanatory. But what's a README without at least one example? :)  
Example: if you want to **launch a webpage on startup**, then you might create a new autostart file with parameters similar to these:  
![Screenshot from 2021-07-31 00-41-03](https://user-images.githubusercontent.com/54716352/127730055-8a279535-6f88-4352-8fb9-f0d169c2ddd1.png)  
End of example.

**Modify** an existing autostart file by selecting it in the list and clicking the **Edit** button. Alternatively, you can **double-click** on the autostart file to immediately begin editing it.

**Delete** an autostart file by selecting it in the list and clicking the **Delete** button. For safety, AutoStar does not permanently delete files with the `rm` command. - it moves them to your system's Trash folder in case you later want to restore the file.

## That's about it!
Yes, this app is not the most complicated one I've ever made, but it doesn't need to be. It does its job well and saves me time, so it was worth the programming time. Hopefully this benefits you too!
