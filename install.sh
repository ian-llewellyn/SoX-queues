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
# mkdir /var/SoX-queues
#       /var/SoX-queues/queue1
#       /var/SoX-queues/queue2
#       /var/SoX-queues/processing
#       /var/SoX-queues/output
#       /var/SoX-queues/completed
#       /var/SoX-queues/failed
EOF
	read -p "Do you want to proceed? Y/N: " answer

	if [ "${answer^^[y]}" != "Y" ]; then
		exit 1
	fi

	cp -v soxqd /etc/rc.d/init.d/soxqd
	cp -v SoX-queue /usr/local/bin/SoX-queue
	mkdir -v /etc/SoX-queues
	cp -v service1.conf service2.conf /etc/SoX-queues
	useradd -d /var/SoX-queues -r soxq && echo "added user: soxq"
	install -o soxq -m 755 -v -d /var/SoX-queues/{queue{1,2},processing,output,completed,failed}

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

	if [ "${answer^^[y]}" != "Y" ]; then
		exit 1
	fi

	rm -v /etc/rc.d/init.d/soxqd
	rm -v /usr/local/bin/SoX-queue
	userdel soxq && echo "removed user: soxq"
	rm -frv /var/SoX-queues
fi
