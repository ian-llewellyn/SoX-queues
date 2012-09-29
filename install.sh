#!/bin/bash

exec_name=$(basename "$0")
exec_dir=$(dirname "$0")

if [ "$(whoami)" != "root" ]; then
	echo "The (un)installation script must be run as root." >&2
	exit 1
fi

if [ "$exec_name" == "install.sh" ]; then
	## INSTALL
	pushd "$exec_dir" &> /dev/null
	cat <<EOF
This is what's about to happen to your system:
# cp soxqd /etc/rc.d/init.d/soxqd
# cp SoX-queue /usr/local/bin/SoX-queue
# mkdir /etc/SoX-queues
# cp service1.conf service2.conf /etc/SoX-queues
# useradd -d /var/SoX-queues -r -s /sbin/nologin soxq
# mkdir -pv /var/SoX-queues/{light,talk,urban}/{complete,failed,output,processing}
EOF
	read -p "Do you want to proceed? Y/N: " answer

	if [ "${answer/y/Y}" != "Y" ]; then
		exit 1
	fi

	cp -v soxqd /etc/rc.d/init.d/soxqd
	cp -v SoX-queue /usr/local/bin/SoX-queue
	mkdir -v /etc/SoX-queues
	for queue_name in light talk urban; do
		sed "s/\$queue_name/$queue_name/g" queue.conf > /etc/SoX-queues/$queue_name.conf
		cp -v queue.efx /etc/SoX-queues/$queue_name.efx
		mkdir -pv /var/SoX-queues/$queue_name/{complete,failed,output,processing}
	done
	useradd -d /var/SoX-queues -r -s /sbin/nologin soxq && echo "added user: soxq"
	chown -R soxq:soxq /var/SoX-queues

	echo "Note: inotify-tools and SoX must be installed on the system in"
	echo "order for the SoX-queue program to work."

	popd &> /dev/null
elif [ "$exec_name" == "uninstall.sh" ]; then
	## UNINSTALL
	cat <<EOF
You are running the SoX-queues uninstall program. This will:
# rm /etc/rc.d/init.d/soxqd
# rm /usr/local/bin/SoX-queue
# userdel soxq
# rm -fr /var/SoX-queues
and leave /etc/SoX-queues and it's contents intact.
EOF
	read -p "Do you want to proceed? Y/N: " answer

	if [ "${answer/y/Y}" != "Y" ]; then
		exit 1
	fi

	rm -v /etc/rc.d/init.d/soxqd
	rm -v /usr/local/bin/SoX-queue
	userdel soxq && echo "removed user: soxq"
	rm -frv /var/SoX-queues
fi
