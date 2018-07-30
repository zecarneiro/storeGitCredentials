#!/bin/bash

# Global variable
home="$(echo $HOME)"
gitConfig="$home/.gitconfig"
operation="$1"
urlWithCredentials="$2"
credentalFile="$home/.git-credentials"
user="$2"
email="$3"

function showMessage(){
	echo "Operation finished"
}

function isStoreSet(){
	if [ ! -f $gitConfig ]; then
		echo 0
	elif [ $(cat $gitConfig | grep -c "helper = store --file $credentalFile") -gt 0 ]; then
		echo 1
	else
		echo 0
	fi
}

function store(){
	local -i haveCredentials=$1
	
	if [ $(isStoreSet) -eq 0 ]; then
		git config --global credential.helper "store --file $credentalFile"
	fi

	if [ $haveCredentials -eq 1 ]; then
		if [ $(cat $credentalFile | grep -c "$urlWithCredentials") -le 0 ]; then
			echo "$urlWithCredentials" | tee -a $credentalFile
		fi
	else
		if [ ! -f $credentalFile ]; then
			echo "" | tee $credentalFile
		fi
	fi

	showMessage
}

function erase(){
	git config --global --unset credential.helper
	
	if [ -f $credentalFile ]; then
		rm $credentalFile
	fi

	showMessage
}

function setUserInfo(){
	if [ -z $user ]||[ -z $email ]; then
		echo "user and email is not set"
	else
		# Unset old user info
		git config --global --unset user.name
		git config --global --unset user.email

		# Set new user
		git config --global user.name "$user"
		git config --global user.email "$email"
	fi

	showMessage
}

function main(){
	case "$operation" in
		"store")
			if [ -z $urlWithCredentials ]; then
				$(store 0)
			else
				$(store 1)
			fi
			;;
		"erase")
			erase
			;;
		"setInfo")
			setUserInfo
			;;
		*)
			echo "$0 (store | erase) URL-CREDENTIAL(OPTIONAL)"
			echo "Example: $0 store https://username:password@mydomain.xxx (mydomain.xxx : gitlab.com or other"
			echo "$0 setInfo user email"
			;;
	esac
}
main