
##
## test.bash(int min_nodes, int max_nodes, int min_delay_my, int max_delay_my, int my_increment)
##

## Commit one test round
##
##    commit_test(int nodes, int my, int sigma)
##
commit_test(){

    mkdir -p result_data/$1

    echo "========="
    echo "Commit new test with $i nodes and my $2:"
    echo ""
    local currentDate=$(date +%d-%b-%H_%M)
    local remote_filename="${2}-${currentDate}-remote.txt"
    local local_filename="${2}-${currentDate}-local.txt"

    terraform apply -var="in_node_count=${1}" -var="simulated_latency=${2}" -var="default_keypair_name=${aws_key_name}" -var="default_keypair_path=${key_path}" --auto-approve;
    local terraform_create_output=$(terraform output etcd-bootstrap-node-public_ip);

    sleep 15
    n=0
    until [ $n -ge 30 ]
    do
        echo $n
        etcdctl --endpoints=$terraform_create_output:2379 endpoint status && break
        n=$[$n+1]
        sleep 15
    done

    etcdctl --endpoints=$terraform_create_output:2379 member list
    new_leader_node_id=$(etcdctl --endpoints=$terraform_create_output:2379 member list | sed -n 2p | awk -F, '{print $1}')
    new_leader_node_ip=$(etcdctl --endpoints=$terraform_create_output:2379 member list | sed -n 2p | awk -F, '{print $4}' | sed 's~http[s]*://~~g' | sed 's/^.//' | cut -d ':'  -f 1)

    # local public_node_id=$(etcdctl --endpoints=$terraform_create_output:2379 endpoint status | awk -F, '{print $2}')
    # etcdctl --endpoints=$terraform_create_output:2379 move-leader $public_node_id

    echo -n "Put a value to the cluster..."
    echo 
    etcdctl --endpoints=$terraform_create_output:2379 put test_key a_nice_value
    
    echo "Move leader to id:$new_leader_node_id with ip: $new_leader_node_ip"
    etcdctl --endpoints=$terraform_create_output:2379 move-leader $new_leader_node_id

    sleep 160

    echo "Kill leader" > ./result_data/${1}/$local_filename
    echo $(date) > ./result_data/${1}/$local_filename
    (ssh -o "StrictHostKeyChecking=no" core@$terraform_create_output -i ./key.pem ssh  -o "StrictHostKeyChecking=no" core@$new_leader_node_ip -i /home/core/key.pem sudo ip link set eth0 down)&

    sleep 160

    echo "Create and fetch log file:"

    ssh -o "StrictHostKeyChecking=no" core@$terraform_create_output -i $key_path "journalctl -u etcd-member.service > /home/core/log.txt"
    scp -i $key_path core@$terraform_create_output:/home/core/log.txt ./result_data/${1}/$remote_filename

    echo "Destoy testbench"
    terraform destroy -auto-approve
}

key_path="./key.pem"
aws_key_name="Mars 2020"

min_nodes=$1
max_nodes=$2
min_my=$3
max_my=$4
inc_my=$5

for((i=$min_nodes; i<=$max_nodes; i++))
do
    delay=$min_my
    until [ $delay -ge $max_my ]
    do
        commit_test $i $delay
        delay=$[$delay+$inc_my]
    done
done

