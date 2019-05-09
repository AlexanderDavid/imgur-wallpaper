#!/bin/bash

#### FUNCTIONS ####

#
# Print the proper usage for the shell script
#
usage() {
	echo "usage: imgur-wallpaper [[-g gallery] | [-h]]"
}

#
# TODO function description
# @param	TODO The first parameter
# @return
#
log() {
	log_message=$1
	echo "$(tput setaf 3)[LOG] ${log_message} $(tput sgr0)"
}

fatal() {
	fatal_message=$1
	echo "$(tput setaf 1)[FATAL] ${fatal_message} $(tput sgr0)"
	exit
}

#### GLOBAL VARIABLES ####

# Directory to store the images in
readonly IMAGE_DIR="$HOME/.cache/imgur-wallpapers"

#### DEPENDENCIES ####

# Check that curl is installed
if [[ -z curl ]] ;
then
    fatal "Could not find command curl!"
fi

# Check that wget is installed
if [[ -z wget ]] ;
then
    fatal "Could not find command wget!"
fi

#### MAIN ####
gallery=""

# Get the command line arguments
while [ "$1" != "" ]; do
	case $1 in
		# If the user passed in -g or --gallery then check the next
		# argument for the gallery string. If it is not present the
		# string will remain ""
		-g | --gallery ) 
			if [ "$2" != "" ] 
			then
				gallery=$2
			fi 
					     ;;

		# If the user passed in -h or --help then show the usage
		# and exit the program
 		-h | --help )    
			usage
			exit
			;;
	esac

	# Shift the arguments down so we can while through the
	# first one insead of foreaching through them all
	shift
done

# Check that a gallery exists at the gallery id passed in. We assume
# that if a gallery exists at the url then there will be a 200 response
# code returned in the header
if curl -I https://imgur.com/gallery/"$gallery" -s | head -n 1 | grep 200 > /dev/null
then 
	log "Found Imgur gallery at https://imgur.com/gallery/$gallery"
else
	fatal "Did not find Imgur gallery at https://imgur.com/gallery/$gallery"
fi

# Using regex to parse through the HTML (this may break later) and find all of the IDs 
# of the pictures in the gallery
images=("$(wget https://imgur.com/gallery/"$gallery" -q -O - | grep -o -P '(?<=<div id=").*(?=" class="post-image-container)')")
images_arr=($images)

# Log how many images were in the gallery
log "Found ${#images_arr[@]} images in gallery"

# Choose a random number between one and the length of the array to download 
random=$$$(date +%s)
random_image=${images_arr[$RANDOM % ${#images_arr[@]} ]}

# Log which image was chosen
log "Choose image https://imgur.com/$random_image.png to download"

# Create the directory that the images are cached in
mkdir -p $IMAGE_DIR
log "Creating the temporary image cache directory"

# Download the random image into the directory
if wget https://imgur.com/"${random_image}".png -P "${IMAGE_DIR}" &> /dev/null
then 
	log "Downloaded https://imgur.com/$random_image.png to $IMAGE_DIR/$random_image.png"
else
	fatal "Failed to download https://imgur.com/$random_image.png"
fi

# Assume the user is using gnome because I'm using gnome TODO add Feh support
gsettings set org.gnome.desktop.background picture-uri "${IMAGE_DIR}"/"${random_image}.png"