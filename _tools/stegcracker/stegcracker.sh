#!/bin/bash
PROJECT_URL="https://github.com/Paradoxis/StegCracker"
UPDATE_URL="https://raw.githubusercontent.com/Paradoxis/StegCracker/master/stegcracker"

# Print banner
echo "StegCracker - ($PROJECT_URL)"
echo "Copyright (c) $(date +%Y) - Luke Paris (Paradoxis)"
echo

# Print usage / Load arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file> [<wordlist>]"
    echo "Options:"
    echo "  --update | Updates StegCracker to the latest version"
    exit 1
else
    wordlist=${2:-/usr/share/wordlists/rockyou.txt}
fi

# Ensure steghide is installed
if [[ ! $(which steghide) ]]; then
    echo -e "\x1B[31mError:\x1B[0m Steghide does not appear to be installed, or has not been added to your current PATH."

    if [[ $(cat /etc/issue | grep Kali && which apt-get) ]]; then
        echo "       You can install it by running the following command: apt-get install steghide -y"
    fi

    exit 1
fi

# Is the user trying to update StegCracker?
if [ ! -f $1 ] && [ $1 = "--update" ]; then
    echo -n "Updating StegCracker to the latest version.. "

    if $(curl -s $UPDATE_URL > $(which $0)); then
        echo -e "\x1B[32mDONE\x1B[0m"
        exit
    else
        echo -e "\x1B[31mFAILED\x1B[0m"
        exit 1
    fi
fi

# Count number of entries in the current wordlist
line_count=$(wc -l "$wordlist" | cut -d ' ' -f 1)

if [[ "$?" -ne "0" ]]; then
    echo -e "\x1B[31mError:\x1B[0m Failed to count number of lines in wordlist '$wordlist'!"
    exit 1
fi

# Check if the wordlist has at least one entry
if [[ "$line_count" -le "0" ]]; then
    echo -e "\x1B[31mError:\x1B[0m Wordlist '$wordlist' appears to be empty."
    exit 1
fi

# Ensure the input file exists
if [ ! -f $1 ]; then
   echo -e "\x1B[31mError:\x1B[0m File '$1' does not exist!"
   exit 1
fi

# Ensure the file is steghide compatible
if [[ ! $(echo "jpg jpeg bmp wav au" | grep -i "${1##*.}") ]]; then
    echo -e "\x1B[31mError:\x1B[0m Unsupported file type '${1##*.}'! Supported extensions: jpg, jpeg, bmp, wav, au"
    exit 1
fi

# Ensure we don't accidentally overwrite a file
if [ -f $1.out ]; then
   echo -e "\x1B[31mError:\x1B[0m Output file '$1.out' already exists!"
   exit 1
fi

# Print message indicating we've started cracking the file
echo "Attacking file '$1' with wordlist '$wordlist'.."

while read pass; do

    # Calculate progress
    line=$((line + 1))
    progress=$((line * 100 / line_count))

    # Crack the file and quit upon finding the right one
    if steghide extract -sf $1 -xf $1.out -p "$pass" -f > /dev/null 2>&1; then
        echo "Successfully cracked file with password: $pass"
        echo "Tried $line passwords"
        echo "Your file has been written to: $1.out"
        exit 0
    else
        echo -en "$line/$line_count ($progress%) Attempted: $pass\033[0K\r"
    fi
done < <(grep "" $wordlist)

# If we didn't exit before this point, we probably failed
echo -e "\x1B[31mError:\x1B[0m Failed to crack file, ran out of passwords."
exit 1