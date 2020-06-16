# ocihpc - Oracle Cloud Infrastructure Easy HPC deployment tool

`ocihpc` is a tool for simplifying deployments of HPC applications in Oracle Cloud Infrastructure (OCI).

## Prerequisites
The OCI user account you use in `ocihpc` should have the necessary policies configured for OCI Resource Manager. Please check [this link](https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Tasks/managingstacksandjobs.htm) for information on required policies.

## Installing ocihpc

### Installing ocihpc on Linux

1. Download the latest release with the following command and extract it:
```sh
curl -LO https://github.com/oracle-quickstart/oci-ocihpc/releases/download/v1.0.0/ocihpc_v1.0.0_linux_x86_64.tar.gz
```

2. Make the ocihpc binary executable.
```sh
chmod +x ./ocihpc 
```

3. Move the ocihpc binary to your PATH.
```sh
sudo mv ./ocihpc /usr/local/bin/ocihpc 
```

4. Test that it works.
```sh
ocihpc version 
```

### Installing ocihpc on macOS

1. Download the latest release with the following command and extract it:
```sh
curl -LO https://github.com/oracle-quickstart/oci-ocihpc/releases/download/v1.0.0/ocihpc_v1.0.0_darwin_x86_64.tar.gz
```

2. Make the ocihpc binary executable.
```sh
chmod +x ./ocihpc 
```

3. Move the ocihpc binary to your PATH.
```sh
sudo mv ./ocihpc /usr/local/bin/ocihpc 
```

4. Test that it works.
```sh
ocihpc version 
```

### Installing ocihpc on Windows


1. Download the latest release from [this link](https://github.com/oracle-quickstart/oci-ocihpc/releases/download/v1.0.0/ocihpc_v1.0.0_windows_x86_64.zip) and extract it.

2. Add the ocihpc binary to your PATH.

3. Test that it works.
```sh
ocihpc.exe version 
```




## Using ocihpc

### 1 - Configure
Run `ocihpc configure` to check if you have a valid configuration to access OCI. The tool will walk you through creating a configuration. 


### 2 - List
You can get the list of available stacks by running `ocihpc list`.

Example:

```sh
$ ocihpc list

List of available stacks:

ClusterNetwork
Gromacs
OpenFOAM
```

### 3 - Initialize
Create a folder that you will use as the deployment source.

IMPORTANT: Use a different folder per stack. Do not initialize more than one stack in the same folder. Otherwise, the tool will overwrite the previous one.

Change to that folder and run `ocihpc init <stack name>`. `ocihpc` will download the necessary files to that folder.


```
$ mkdir ocihpc-test
$ cd ocihpc-test
$ ocihpc init --stack ClusterNetwork

Downloading stack: ClusterNetwork

ClusterNetwork downloaded to /Users/opastirm/ocihpc-test/

IMPORTANT: Edit the contents of the /Users/opastirm/ocihpc-test/config.json file before running ocihpc deploy command
```

### 4 - Deploy
Before deploying, you need to change the values in `config.json` file. The variables depend on the stack you deploy. An example `config.json` for Cluster Network would look like this:

```json
{
  "variables": {
    "ad": "kWVD:PHX-AD-1",
    "bastion_ad": "kWVD:PHX-AD-2",
    "bastion_shape": "VM.Standard2.1",
    "node_count": "2",
    "ssh_key": "ssh-rsa AAAAB3NzaC1yc2EAAAA......W6 opastirm@opastirm-mac"
  }
}
```

After you change the values in `config.json`, you can deploy the stack with `ocihpc deploy <arguments>`. This command will create a Stack on Oracle Cloud Resource Manager and deploy the stack using it.

For supported stacks, you can set the number of nodes you want to deploy by adding it to the `ocihpc deploy` command. If the stack does not support it or if you don't provide a value, the tool will deploy with the default numbers. 

For example, the following command will deploy a Cluster Network with 5 nodes:

```
$ ocihpc deploy --stack ClusterNetwork --node-count 5 --region us-ashburn-1 --compartment-id ocid1.compartment.oc1..6zvhnus3q
```

INFO: The tool will generate a deployment name that consists of `<stack name>-<current directory>-<random-number>`.

Example:

```
$ ocihpc deploy --stack ClusterNetwork --node-count 5 --region us-ashburn-1 --compartment-id ocid1.compartment.oc1..6zvhnus3q

Deploying ClusterNetwork-ocihpc-test-7355 [0min 0sec]
Deploying ClusterNetwork-ocihpc-test-7355 [0min 17sec]
Deploying ClusterNetwork-ocihpc-test-7355 [0min 35sec]
...
```

### 5 - Connect
When deployment is completed, you will see the the bastion/headnode IP that you can connect to:

```
Successfully deployed ClusterNetwork-ocihpc-test-7355

You can connect to your head node using the command: ssh opc@$123.221.10.8 -i <location of the private key you used>
```

You can also get the connection details by running `ocihpc get ip` command.

### 5 - Delete
When you are done with your deployment, you can delete it by changing to the stack folder and running `ocihpc delete --stack <stack name>`.

Example:
```
$ ocihpc delete --stack ClusterNetwork

Deleting ClusterNetwork-ocihpc-test-7355 [0min 0sec]
Deleting ClusterNetwork-ocihpc-test-7355 [0min 17sec]
Deleting ClusterNetwork-ocihpc-test-7355 [0min 35sec]
...

Succesfully deleted ClusterNetwork-ocihpc-test-7355
```
