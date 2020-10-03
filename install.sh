#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -p ~/install/directory/path"
   echo -e "\t-p Path to directory"
   exit 1 # Exit script after printing help
}

while getopts "p:" opt
do
   case "$opt" in
      p ) installPath="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$installPath" ]
then
   echo "Please specify install path!";
   helpFunction
fi

echo "# Building executable"
crystal build -s -t -p --release ./src/main.cr -o ./bin/mp3_to_dca
echo "# Installing into $installPath"
cp ./bin/mp3_to_dca $installPath
