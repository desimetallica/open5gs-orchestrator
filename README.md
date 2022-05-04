# open5gs-orchestrator
Terraform and ansible deploy on openstack for open5gs and UERANSIM

on UERANSIM VM run:

 /opt/UERANSIM/build/nr-gnb -c /opt/UERANSIM/config/open5gs-gnb.yaml 
 /opt/UERANSIM/build/nr-ue -c /opt/UERANSIM/config/open5gs-ue.yaml 

you should ping the wan on tun interface with:

 ping -I uesimtun0 8.8.8.8

