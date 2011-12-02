#!/bin/bash
CONFIG_DIR=/home/ian/devel/processor
MAX_SOX_INSTANCES=4

## Usage function
usage() {
	if [ ! -z $1 ]; then
		echo "Unrecognised command line parameter: $1" >&2
	fi
	echo "Usage: $0 <-c config_file>" >&2
	return 0
}

## Command line args
while [ $# -ne 0 ]; do
	case $1 in
	-c)
		shift
		config_files="$config_files $1"
		;;
	*)
		usage $1
		exit 1
		;;
	esac
	shift
done

# Generate our own list of config files if none was provided
if [ -z "$config_files" ]; then
	for config_file in $CONFIG_DIR/*.conf ; do
		config_files="$config_files $config_file"
	done
fi

sox_do() {
	## Command line args
	while [ $# -ne 0 ]; do
		case $1 in
		-c)
			shift
			config_file="$1"
			;;
		*)
			file=$1
			;;
		esac
		shift
	done

	source $config_file

	$SOX_BIN $PROCESSING_DIR/$file -C 256 $OUTPUT_DIR/$file $EFFECTS
	if [ $? -eq 0 ]; then
		# Completed Successfully
		mv $PROCESSING_DIR/$file $SUCCESS_DIR/$file
	else
		# Did not complete Successfully
		rm $OUTPUT_DIR/$file
		mv $PROCESSING_DIR/$file $FAIL_DIR/$file
	fi
}

## Create a map for each queue_dir => conf_file
declare -A maps
# for each config file:
for config_file in $config_files ; do
#   build up a mapping array of QUEUE_PATH => config_file
	source $conf_file
	$maps[$QUEUE_DIR]=$conf_file
done


inotifywait -m -e CLOSE_WRITE -e MOVED_TO "${!maps[@]}" | while read dir operation file ; do
	# Is this an audio file?
	if [[ "$file" != "*.mp2" ]] && [[ "$file" != "*.mp3" ]]; then
		# No it's not! Skip
		echo "File: $file is not audio" >&2
		continue
	fi

	# Is there a need to double check this?
	if [ "$operation" != "CLOSE_WRITE" -o "$operation" != "MOVE_TO" ]; then
		continue
	fi

	# How many SoX have we got on at the moment?
	sox_instances=$(pgrep sox | wc -l)
	if [ -z "$sox_instances" ]; then sox_instances=0 ; fi

	# Delay here until there is an opening for us..
	until [ $sox_instances -lt $MAX_SOX_INSTANCES ]; do
		echo "Waiting for other SoX instances to finish." >&2
		sleep 30
	done

	# Move the source file into the processing directory
	mv $dir/$file $PROCESSING_DIR/$file
	if [ $? -ne 0 ]; then
		echo "There was a problem moving $dir/$file for processing." >&2
		echo "Perhaps there is already a file by that name being processed." >&2
		continue
	fi

	# Process the audio
	sox_do -c ${maps[$dir]} $file &

done







## init.d/processor start
CONFIG_DIR=/home/ian/devel/processor

declare -A maps
for conf_file in $CONFIG_DIR/*.conf ; do
# for each config file:
#   build up a mapping array of QUEUE_PATH => config_file
	source $conf_file
	$maps[$QUEUE_DIR]=$conf_file
done

# inotifywait on each queue directory: ${!maps[@]}
inotifywait -m -e CLOSE_WRITE -e MOVED_TO "${!maps[@]}" | while read q_dir opperation file ; do
#   queue1 CLOSE_WRITE file.mp2
	if [[ "$file" != "*.mp2" ]] && [[ "$file" != "*.mp3" ]]; then
		echo "File: $file is not audio" >&2
		continue
	fi

#   sox_do -c ${maps[queue1]}  -- OR --
#   source ${maps[queue1]} && mv $file && sox_do

# call sox_do on a file (passing in the source dirctory)
# sox_do loads necessary params
# pros: one inotifywait, FIFO queue, easier as system service
# cons:
sox_do -c config filename
done


processor -c config
# watches queue dir indefinately
# pros: simple
# cons: less orderly queue














