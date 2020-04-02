

# Setup

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