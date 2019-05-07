#!/bin/bash

if tune2fs -l /dev/xvdf | grep 'jenkinsfiles' 2> /dev/null; then
    echo "jenkinsfiles already"
else
    y | mkfs.ext4 /dev/xvdf -L jenkinsfiles
    systemctl stop jenkins && \
    mkdir /opt/jenkins_tmp && mv -f /var/lib/jenkins/* /var/lib/jenkins/.* /opt/jenkins_tmp && \
    mount /dev/xvdf /var/lib/jenkins && chown jenkins:jenkins /var/lib/jenkins -R && \
    shopt -s dotglob && mv -f /opt/jenkins_tmp/* /var/lib/jenkins && rm -rf /opt/jenkins_tmp && \
    echo "LABEL=jenkinsfiles    /var/lib/jenkins   ext4 defaults,discard    0 0"
    systemctl start jenkins
fi