# Setup

## Installing and verify tool chain

Make sure you have python3.7 installed on your computer. Check by running: `python3.7 -V`

1. If needed install python3.7 and venv
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

6. Install AWS Command Line Interface v2 and setup your API key.
    ```
    sudo apt-get install awscli
    ```

7. Install Terraform from Hashicorp
    ```
    sudo apt-get install terraform
    terraform apply -var="in_node_count=7" -var="default_keypair_name=keyname" -var="default_keypair_path=./path/to/key.pem"
    ```

8. Download the security key from AWS (maybe need to change permission for it `chmod 400`) and use it to connect to the cluster: 
    ```
    ssh core@X.X.X.X -i path/to/key.pem
    ```

9. Ensure the cluster is running: `etcdctl cluster-health`

10. Destroy the cluster and free up AWS resources by running:
    ```
    terraform destroy
    ```

## Run Tests

1. Create EC2 SSH key within your AWS console, enter the keyname within the `test.bash` file.
2. Also download the key, add the key path to `test.bash`.
3. Run the test by executing `bash test.bash min-nodes max-nodes min-latency max-latency interval-latency`

## Various Debug Commands:

`journalctl --identifier=ignition --all` - Shows the output of the config tool used to bootstrap the instances

`etcdctl --endpoints=X.X.X.X:2379 cluster-health` - Show if the cluster is up

`etcdctl --endpoints=X.X.X.X:2379 member list` - Specifially shows the members of the cluster

`etcdctl endpoint status --cluster -w table` - Show leader node

`etcdctl --endpoints=X.X.X.X:2379 put key value` - Put a value in the cluster

`etcdctl --endpoints=54.246.218.50:2379 endpoint status | awk -F, '{print $2}'` - Get member id for a node

`etcdctl --endpoints=54.246.218.50:2379 move-leader a3228e72f2c653d` - Move leader 

`journalctl -u etcd-member.service -r -o json-pretty` - Show log output of etcd which includes leader elections and put operations.

`scp -i path/to/key.pem core@X.X.X.X:/remote/dir/foobar.txt /local/di` - Fetch log file from cluster
