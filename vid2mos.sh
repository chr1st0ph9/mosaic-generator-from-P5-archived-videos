#!/bin/bash

# The converter is expected to accept the full file name of the image or video to convert as a parameter. It
# must return the full name (including path) of the generated preview via its standard out channel.
# Preview generators must not create other output on the standard out or standard error channel. 
#

AW_PATH="/usr/local/aw/bin"
FFMPEG="$AW_PATH/ffmpeg"
FFPROBE="$AW_PATH/ffprobe"
TMP="/tmp"
# DEBUG must be used only when running the script in a shell 
# for testing, P5 does not support this option 
#DEBUG="1"
DEBUG=""


if [ "$1" == -v ] 
then
	input_file=$2
	DEBUG=1
else
	input_file=$1
fi

if [ ! -f "$input_file" ]
then
	[ $DEBUG == "1" ] && echo "[-] File $input_file not found"
	exit 1 
fi

# seek position="00:00:10" 
position="10"

# mosaic is format 4:3
mosaic_factor=3
# a 1 value ratio 4x3=	12 images
# a 2 value ratio 8x6=	48 images
# a 3 value ratio 12x9= 108 images ...

# find tiling
tiling_value=$(( 4 * $mosaic_factor))x$((3 * $mosaic_factor))
[ $DEBUG ] && echo "Tiles = $tiling_value"

nb_frames_to_extract=$(( $mosaic_factor*4 * $mosaic_factor*3 ))
[ $DEBUG ] && echo "Frames number = $nb_frames_to_extract"

nb_total_frames=$($FFPROBE -v error -of flat=s=_ -select_streams v:0 -show_entries stream=nb_frames "$input_file" | cut -d'=' -f2 )
nb_total_frames=`echo $nb_total_frames | tr -d \"  `
[ $DEBUG ] && echo "Total number of frames = $nb_total_frames"

# interval between 2 frames 
int_frame=$(( $nb_total_frames / $nb_frames_to_extract ))
[ $DEBUG ] && echo "Frames interval = $int_frame"

#
#  /usr/local/aw/bin/ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -print_format csv /Volumes/dancingWithMartina/_video_download/_TechniqueofLatinDancing_Walter\ Laird.mp4
#  /usr/local/aw/bin/ffprobe -i /Volumes/dancingWithMartina/_video_download/_TechniqueofLatinDancing_Walter\ Laird.mp4   -v error -show_format -show_streams|grep frame
#

# 
#  output filename generation as jpg 
filename=$(basename -- "$input_file")
filename="${filename%.*}"
output_file=$TMP/$filename.jpg
ffmpeg_output=$TMP/$filename.log

quiet_option="-hide_banner -loglevel error"
[ $DEBUG ] && quiet_option=""

$FFMPEG \
			$quiet_option \
			-ss "$position" \
			-i "$input_file" \
			-frames 1 \
			-filter:v "select=not(mod(n\,$int_frame)),scale=320:240,tile=$tiling_value" \
			-y	\
			"$output_file" 2> "$ffmpeg_output"


[ $DEBUG ] && cat "$ffmpeg_output"


echo $output_file

