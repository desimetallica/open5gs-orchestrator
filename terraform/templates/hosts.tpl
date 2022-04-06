[5gcore]
${open5gs} ansible_user=ubuntu

[UERANSIM]
${euransim} ansible_user=ubuntu

[multi:children]
5gcore
UERANSIM

