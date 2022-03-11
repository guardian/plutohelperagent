#!/bin/bash

EXT=$(echo "$1" | awk -F . '{print $NF}')

HOME = "/Users/home"

# All places using "open" relies on opening a file with the default associated application.
# Use 'open -a "Application\ Name" "$1"', to use a specific application. Exact syntax may vary
# depending on what arguments the application accepts.
if [[ $EXT == "cpr" ]]; then #we are opening a Cubase project.
	#Cubase projects don't play well with our project management, they must be opened from the
	#media directory (on SAN) otherwise new media will be created on the project storage (on NAS).
	#This would rapidly fill up the NAS, and have disk speed implications for large sessions.
	#We therefore treat the NAS copy as a backup, and create a copy on the SAN as the "Real" one if it does not exist already.

	LOG_FILE=/Users/home/Library/Logs/cubase_open.log
	DATEFORMAT="%y-%m-%d_%H:%M:%S"

	echo Log file is ${LOG_FILE}

	echo >> ${LOG_FILE}
	echo --------------------------------------------------------- >> ${LOG_FILE}
	echo -n Running as user: >> ${LOG_FILE}
	whoami >> ${LOG_FILE}
	echo ${UID} >> ${LOG_FILE}
	echo ${EUID} >> ${LOG_FILE}

	PROJECT_FILE=`basename "$1"`
	#First, get the asset folder location from a handy "pointer file" created by the create_asset_folder postrun action.
	#This has the same name as the project file, same directory and a .ptr extension
	#We also need to replace /srv in this file with /Volumes, to get the on-client path
	PTR_FILE=`echo "$1" | sed s/\.cpr/.ptr/`
	echo `date +${DATEFORMAT}` - INFO - Trying to open ${PTR_FILE} >> ${LOG_FILE}

	ASSET_FOLDER=`cat "${PTR_FILE}" | sed s.^\\/srv.\\/Volumes.`
	echo `date +${DATEFORMAT}` - INFO - Got asset folder pointer ${ASSET_FOLDER} from ${PTR_FILE} >> ${LOG_FILE}

	if [ ! -d "${ASSET_FOLDER}" ]; then
		echo `date +${DATEFORMAT}` - ERROR - Asset folder ${ASSET_FOLDER} does not exist! Check san volumes are mounted >> ${LOG_FILE}

		exit 1
	fi

	#Second, see if the project file already exists in said assets folder and copy it there if not
	if [ ! -f "${ASSET_FOLDER}/${PROJECT_FILE}" ]; then
		echo `date +${DATEFORMAT}` - INFO - Project '${PROJECT_FILE}' does not exist in asset folder '${ASSET_FOLDER}' so copying it>> ${LOG_FILE}

		cp "$1" "${ASSET_FOLDER}/${PROJECT_FILE}" >> ${LOG_FILE} 2>&1
		if [ "$?" != "0" ]; then
			echo `date +${DATEFORMAT}` - ERROR - Copy operation returned $? >> ${LOG_FILE}
			exit 3
		fi
	fi

	#Third, allocate a license from the dongle server for the session.  This means that the session must be
	#run synchronously (open -W), to de-allocate the license at the end (deactivate command below).
	#therefore, we create a temp script to do this and then execute that in the background

#	BUNDLE_PATH="/Applications/SEH UTN Manager.app"
#	cat > /tmp/open_cubase.sh << EOF
#	echo `date +${DATEFORMAT}` - INFO - Attempting to allocate license from 10.232.70.94 >> ${LOG_FILE}
#
#	"${BUNDLE_PATH}"/Contents/MacOS/utnm -c "activate 10.232.70.94 0x0819 0x0101" >> ${LOG_FILE} 2>&1
#	echo >> ${LOG_FILE}
#       echo `date +${DATEFORMAT}` - INFO - Potential code meanings: >> ${LOG_FILE}
#	cat >> ${LOG_FILE} << ECODES
#  0  The USB device is free for use.
#  1  The USB device is being plugged in.
#  5  The USB device was suprise-removed.
# 20  The plugin of the USB device failed.
# 21  The plugout of the USB device failed.
# 22  The ejection of the USB device failed.
# 23  The USB device is plugged in.
# 24  The USB device is plugged out.
# 25  The USB device is plugged in by another user.
# 26  The USB device is unreachable.
# 27  The USB device state is unknown.
#100  Unknown command.
#101  UTN server not found. Either the UTN server does not exist or the DNS
#     resolution failed.
#103  The port key is too long.
#ECODES
	echo `date +${DATEFORMAT}` - INFO - Opening "${ASSET_FOLDER}/${PROJECT_FILE}" synchronously using system open command >> ${LOG_FILE}
    open -W "${ASSET_FOLDER}/${PROJECT_FILE}"
#    "${BUNDLE_PATH}"/Contents/MacOS/utnm -c "deactivate 10.232.70.94 0x0819 0x0101" >> ${LOG_FILE} 2>&1
#EOF
    /bin/bash /tmp/open_cubase.sh &
elif [[ $EXT == "plproj" ]]; then
    # Prelude project files with Prelude
    open "$1"
else
    # Show all other files in the finder
    open "$1"
fi
