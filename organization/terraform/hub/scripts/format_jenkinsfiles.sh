#!/bin/bash

sleep 30

sudo tune2fs -l /dev/xvdf | grep 'jenkinsfiles'
TUNE2FS=$?

if [ $TUNE2FS -eq 0 ] ; then
    sudo systemctl stop jenkins && \
    sudo sh -c 'echo "LABEL=jenkinsfiles    /var/lib/jenkins   ext4 defaults,discard    0 0" >> /etc/fstab' && \
    sudo mount -a
    sudo systemctl start jenkins
else
    sudo mkfs.ext4 /dev/xvdf -L jenkinsfiles <<< "y" && \
    sudo systemctl stop jenkins && \
    shopt -s dotglob && sleep 15 && \
    sudo mkdir /opt/jenkins_tmp && sudo mv -f /var/lib/jenkins/* /opt/jenkins_tmp && \
    sleep 15 && \
    sudo mount /dev/xvdf /var/lib/jenkins && sudo chown jenkins:jenkins /var/lib/jenkins -R && \
    sleep 15 && \
    sudo mv -f /opt/jenkins_tmp/* /var/lib/jenkins && sudo rm -rf /opt/jenkins_tmp && \
    sudo sh -c 'echo "LABEL=jenkinsfiles    /var/lib/jenkins   ext4 defaults,discard    0 0" >> /etc/fstab' && \
    sleep 15 && \
    sudo systemctl start jenkins
fi

exit