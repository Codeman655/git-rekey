#!/bin/bash

#Check for git-crypt
function usage(){
  echo "Execute from root directory of repository"
  echo "git-rekey [-u user1,user2,...] -k keyname "
  exit 1
}

#This function 
function rekey (){
  echo "rekeying $2 with the new key name: $1"
  perl -pi -e "s/git-crypt[-\w]*/git-crypt-$1/g" $2
}


#Check dependencies 
if ! [[ -x $(which git-crypt) ]] &&  ! [[ -x $(which perl) ]]; then 
  echo "Please ensure you have installed git-crypt and perl"
  usage
fi



#Set defaults
users=""
keyname=""

#Use getopts for options
while getopts u:k: option
  do  case "$option" in
      u)  users=$OPTARG;;
      k)  keyname=$OPTARG;;
      [?]) exit 1;;
    esac
done

#Check arguments
if [[ -z $keyname ]] || [[ $# -gt 4 ]] ; then 
  usage
  exit 1
fi

#convert list of users into an array
if [[ -n users ]] ;  then 
  IFS=',' read -a list <<< "$users";
  echo $list;
fi

#Go into main loop
if [[ -f $(which git-crypt) ]] && [[ -e .git ]] ; then
  #Ask for keyname or take from params $1
  echo "Chaging key to $keyname"

  #run git-crypt init -k <keyname>
  git-crypt init -k "$keyname"

  #find all .gitattributes and replace git-crypt.* with git-crypt-key
  #find . -name ".gitattributes" -exec rekey $1 {} \;
  echo "Modifying .gitattributes files"
  attr=$(find . -name ".gitattributes")
  for file in $attr; do 
    rekey $keyname $file
  done


  #Run `git-crypt status -e` to find encrypted files
  #Touch all encrypted files
  files=$( git-crypt status -e | grep encrypted | awk '{print $NF}' )
  touch $files

  #with the new key in place, add users
  for user in "${list[@]}"; do
    echo "Adding user: $user"
    git-crypt add-gpg-user -n -k $keyname $user
  done

  #Run git-crypt status
  git-crypt status -e

  #Run git status
  echo "Please check the status of your commit"
  git stats
  
else
  usage
  exit 1
fi

