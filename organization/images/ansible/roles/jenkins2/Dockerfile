FROM ubuntu:18.04

RUN ls -al
RUN apt-get update
RUN apt-get install ansible curl -y

ADD . /opt/role-ansible

RUN ansible-playbook -vvv /opt/role-ansible/tests/playbook.yml

EXPOSE 8080
CMD ["/etc/init.d/jenkins", "restart"]
