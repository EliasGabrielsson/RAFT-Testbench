### ########################## ###
### [[variable]] in_node_count ###
### ########################## ###

variable in_node_count {
    description = "The (minimum 3) number of EC2 nodes the etcd3 cluster will be brought up with."
    default     = "3"
}

variable simulated_latency {
    description = "Added latency to egress for each node"
    default     = "40"
}

variable default_keypair_name {
    description = "A keypair stored within the selected AWS account"
    default     = "Mars 2020"
}

variable default_keypair_path {
    description = "Path to the aws keypair file."
    default     = "./key.pem"
}