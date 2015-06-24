#!/bin/bash

#Check for git-crypt
function usage(){
  echo "Execute from root directory of repository"
  echo "git-rekey [-u user1,user2,...] -k keyname "
  exit 1
}

function rekey (){
  perl -pi -e "s/git-crypt\w*/git-crypt-$1/g" $2
}

#Set defaults
users=""
keyname=""
while getopts u:k: option
  do  case "$option" in
      u)  OIFS=IFS;
          IFS=',';
          users=$OPTARG;;
      k)  keyname=$OPTARG;;
      [?]) exit 1;;
    esac
done

#Check arguments
if [[ -z $keyname ]] || [[ $# -gt 4 ]] ; then 
  usage
  exit 1
fi

IFS=',' read -a list <<< "$users"
echo $list
echo "list of list:"
for user in "${list[@]}"
do
    echo "$user"
done
exit 1

#Go into main loop
if [[ -f $(which git-crypt) ]] && [[ -e .git ]] ; then
  #Ask for keyname or take from params $1
  echo "$1"

  #run git-crypt init -k <keyname>
  git-crypt init -k "$1"

  #find all .gitattributes and replace git-crypt.* with git-crypt-key
  #find . -name ".gitattributes" -exec rekey $1 {} \;
  attr=$(find . -name ".gitattributes")
  for file in $attr; do 
    rekey $1 $file
  done

  #Run `git-crypt status -e` to find encrypted files
  #Touch all encrypted files
  files=$( git-crypt status -e | grep encrypted | awk '{print $NF}' )
  touch $files

  #Run git-crypt status
#  git-crypt status -e
  
  #Ask to commit changes
#  git status
else
  
  usage
  exit 1
fi

