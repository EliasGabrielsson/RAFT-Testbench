# Setup

Make sure you have python3.7 installed on your computer. Check by running: `python3.7 -V`

1. Setup python3.7 venv
    ```
    sudo apt-get install python3.7 python3.7-venv
    ```

2. To create of an isolated python environment, run the following command in the root project folder
    ```
    python3.7 -m venv .venv
    ```

3. Temporarily change to the local python path:

    ```
    source .venv/bin/activate
    ```

4. Verify the virtual python environment's version
    ```
    python --version
    ```
5. Install dependencies be executing:
    ```
    pip install -r requirements.txt
    ```

# Roadmap

## Setup a basic network configuration

## Setup a ETCD cluster

Use this premade EC2 Image:
http://coreos.com/os/docs/latest/booting-on-ec2.html

The default username is: `core`.

Make a Terraform script which enables number of nodes to be set dynamiclly in range from 3-30.

## Setup an Ignite conf.
Get etcd work somehow

## Runtime configuration of Ignite conf.
Explore if its possible to ssh inject new configs in a nice way

## Create static config of tc-netem
Provision a static conf during setup using Terraform.
https://netbeez.net/blog/how-to-use-the-linux-traffic-control/

## Runtime configuration of tc-netem
Explore if its possible to ssh inject new configs in a nice way from the terraform script.

## Setup Grafana 
Setup an instance of grafana consuming the information from: https://prometheus.io/


# Sources for the paper:
https://etcd.io/docs/v3.4.0/benchmarks/etcd-3-demo-benchmarks/


https://docs.bitnami.com/general/infrastructure/etcd/administration/create-cluster/
# Debug

`journalctl --identifier=ignition --all`
etcdctl cluster-health
etcdctl member list

0. Ersätt med bitnami images

1. SKRIV CONF MHA:
https://github.com/etcd-io/etcd/blob/master/Documentation/op-guide/configuration.md

advertise-client-urls: http://IP_ADDRESS_OWN:2379
initial-advertise-peer-urls: http://IP_ADDRESS_OWN:2380
initial-cluster=http://IP_ADDRESS_OWN:2380,http://IP_ADDRESS_MEMBER_1:2380,http://IP_ADDRESS_MEMBER_2:2380

2. ERSÄTT CONF <- Provision
/opt/bitnami/conf/etcd.conf.yml 

3. KÖR 
sudo /opt/bitnami/ctlscript.sh restart