#!/bin/bash

# Global variable
home="$(echo $HOME)"
operation="$1"
option="$2"

# Files
credentalFile="$home/.git-credentials"
gitConfig="$home/.gitconfig"
fileToSaveInfo="$home/.gitUserInfo"

# Store
urlWithCredentials="$3"

# Info
user="$3"
email="$4"

# Exit
function exitScript(){
	exit 1
}

# Check if file or directory exist
function isFileDirExist(){
	local -i isFileOrDir=$1
	local file="$2"
	local -i exist

	# Ckeck Dir
	if [ $isFileOrDir -eq 0 ]; then
		if [ -d "$file" ]; then
			exist=1
		else
			exist=0
		fi
	# Ckeck File
	elif [ $isFileOrDir -eq 1 ]; then
		if [ -f "$file" ]; then
			exist=1
		else
			exist=0
		fi
	# Ckeck nothing
	else
		exist=0
	fi

	# Return response
	echo $exist
}

# Show message
function showMessage(){
	echo
	echo "Operation finished"
}

# Check if store is active
function isStoreSet(){
	if [ $(isFileDirExist 1 "$gitConfig") -eq 0 ]; then
		echo 0
	elif [ $(cat $gitConfig | grep -c "helper = store --file $credentalFile") -gt 0 ]; then
		echo 1
	else
		echo 0
	fi
}

# Store Credential inserted by user
function store(){
	local -i haveCredentials=$1
	
	# Set store on git
	if [ $(isStoreSet) -eq 0 ]; then
		git config --global credential.helper "store --file $credentalFile"
	fi

	# Create file to save credentials
	if [ $(isFileDirExist 1 "$credentalFile") -eq 0 ]; then
		touch $credentalFile
	fi

	# Save credential on credentials file
	if [ "$option" = "-u" ]; then
		if [ ! -z $urlWithCredentials ]; then
			if [ $(cat $credentalFile | grep -c "$urlWithCredentials") -le 0 ]; then
				echo "$urlWithCredentials" | tee -a $credentalFile > /dev/null
			fi
		else
			echo "Invalid URL"
		fi
	fi

	showMessage
}

# Return index of user info to set
function getUserInfo(){
	local -i onlyShowList=$1
	local -i indexUser=1
	local -i existIndex
	local userInfoToReturn
	local emilInfoToReturn
	local activedUser=$(git config user.name)
	local activedEmail=$(git config user.email)

	# Show active user from git command
	echo >&2
	echo >&2 "Actived User Info:"
	echo >&2 "USER: $activedUser"
	echo >&2 "EMAIL: $activedEmail"
	echo >&2

	if [ $(isFileDirExist 1 "$fileToSaveInfo") -eq 1 ]&&[ -s "$fileToSaveInfo" ]; then
		while [ 1 ]; do
			existIndex=$(cat $fileToSaveInfo | grep -c "name$indexUser")

			if [ $existIndex -gt 0 ]; then
				if [ $indexUser -eq 1 ]; then
					printf >&2 "List an option:\n"
				fi

				# Print list
				userInfoToReturn=$(cat $fileToSaveInfo | grep "name$indexUser" | cut -d ':' -f2)
				emailInfoToReturn=$(cat $fileToSaveInfo | grep "email$indexUser" | cut -d ':' -f2)
				echo >&2 "$indexUser: $userInfoToReturn - $emailInfoToReturn"
			elif [ $indexUser -eq 1 ]; then
				indexUser=-1
				break
			else
				break
			fi
			indexUser=indexUser+1
		done
	else
		indexUser=-1
	fi

	if [ $indexUser -eq -1 ]; then
		echo >&2 "Not exist saved user info"
	else
		if [ $onlyShowList -eq 0 ]; then
			# Read user option inserted
			read -p "Insert an option: " indexUser

			existIndex=$(cat $fileToSaveInfo | grep -c "name$indexUser")
			if [ $existIndex -le 0 ]; then
				echo >&2 "Invalid option inserted"
				indexUser=-1
			fi
		else
			indexUser=-1
		fi
	fi

	# Return
	if [ $onlyShowList -eq 0 ]; then
		echo $indexUser
	fi
}

# Save Info user on file
function saveUserInfo(){
	local -i indexUser=1
	local -i existIndex

	if [ $(isFileDirExist 1 "$fileToSaveInfo") -eq 1 ]&&[ -s "$fileToSaveInfo" ]; then
		while [ 1 ]; do
			existIndex=$(cat $fileToSaveInfo | grep -c "name$indexUser")

			if [ $existIndex -le 0 ]; then
				break
			elif [ $indexUser -eq 1 ]&&[ $existIndex -le 0 ]; then
				break
			fi
			indexUser=indexUser+1
		done
	fi

	# Save
	echo "name$indexUser:$user" | tee -a $fileToSaveInfo > /dev/null
	echo "email$indexUser:$email" | tee -a $fileToSaveInfo > /dev/null
}

# Set Info user defined by user
function setUserInfo(){
	local -i infoSeleted
	local -i isToSet=0

	# Change profile
	if [ -z $option ]||[ "$option" = "-p" ]; then
		infoSeleted=$(getUserInfo 0)

		if [ $infoSeleted -ne -1 ]; then
			user=$(cat $fileToSaveInfo | grep "name$infoSeleted" | cut -d ':' -f2)
			email=$(cat $fileToSaveInfo | grep "email$infoSeleted" | cut -d ':' -f2)
			isToSet=1
		fi

	# List of saved profile
	elif [ "$option" = "-l" ]; then
		getUserInfo 1

	# Set/Save info
	elif [ "$option" = "-o" ]||[ "$option" = "-s" ]||[ "$option" = "-S" ]; then
		if [ -z "$user" ]||[ -z "$email" ]; then
			echo "user and email is not set"
		else
			if [ "$option" != "-S" ]; then
				isToSet=1
			fi

			# Save Info
			if [ "$option" = "-s" ]||[ "$option" = "-S" ]; then
				saveUserInfo
			fi
		fi
	fi

	if [ $isToSet -eq 1 ]; then
		# Unset old user info
		git config --global --unset user.name
		git config --global --unset user.email

		# Set new user
		git config --global user.name "$user"
		git config --global user.email "$email"
	fi

	showMessage
}

# Erase Credential and disable store
function erase(){
	git config --global --unset credential.helper

	# Unset old user info
	git config --global --unset user.name
	git config --global --unset user.email
	
	if [ $(isFileDirExist 1 "$credentalFile") -eq 1 ]; then
		rm $credentalFile
	fi

	if [ $(isFileDirExist 1 "$fileToSaveInfo") -eq 1 ]; then
		rm $fileToSaveInfo
	fi

	showMessage
}

# Main
function main(){
	case "$operation" in
		"store")
			store
			;;
		"info")
			setUserInfo
			;;
		"erase")
			erase
			;;
		*)
			
			echo "$0 (store | erase | info) option"
			echo
			echo "### Store ###"
			echo "Option(OPTIONAL):"
			echo "	-u: Include url with credentials."
			echo "			Example: $0 store -u https://username:password@mydomain.xxx (mydomain.xxx : gitlab.com or other)"
			echo
			echo "### Info ###"
			echo "Option:"
			echo "	-s: = set and save info"
			echo "			Example: $0 info -s user email"
			echo "	-S: = only save info"
			echo "			Example: $0 info -S user email"
			echo "	-o: = only set info"
			echo "			Example: $0 info -o user email"
			echo "	-l: = list of saved info"
			echo "			Example: $0 info -l"
			echo "	-p: = change profile on git with list of saved info"
			echo "			Example: $0 info -p"
			echo
			echo "### Erase ###"
			echo "Without option"
			echo
			echo "Argument 6 or greater will be ignored"
			;;
	esac
	exitScript
}
main