# OCI Easy HPC deployment tool - ocihpc

`ocihpc` is a tool for simplifying deployments of HPC applications in Oracle Cloud Infrastructure (OCI).

## Prerequisites

### Software needed
The tool needs `oci` CLI, `unzip`, and `jq` to run. You will receive an error message if they are not installed.

To install and configure OCI CLI, please follow the steps in [this link](https://docs.cloud.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm).

`Unzip` and `jq` come installed in many linux distributions. If you need to install them, please check the tools' websites for installation.

### PATH settings
You need to set the `ocihpc` tool as an executable and add the tool directory to your path.

Clone the repository:
```sh
git clone https://github.com/oracle-quickstart/oci-ocihpc.git
```

Set the tool as an executable:
```sh
cd oci-ocihpc
chmod +x ocihpc
```

Add the tool directory to your path:
```sh
export PATH=$PATH:<the path where you cloned the repository into>
```

## Using ocihpc

### 1 - List
You can get the list of available packages by running `ocihpc list`.

Example:

```sh
$ ocihpc list

List of available packages:

ClusterNetwork
Gromacs
OpenFOAM
```

### 2 - Initialize
Create a folder that you will use as the deployment source.

```sh
$ mkdir ocihpc-test
```

Change to that folder and run `ocihpc init <package name>`. `ocihpc` will download the necessary files to that folder.

Example:

```sh
$ cd ocihpc-test
$ ocihpc init ClusterNetwork

Downlading package: ClusterNetwork

Package ClusterNetwork downloaded to /Users/opastirm/ocihpc-test/

IMPORTANT: Edit the contents of the /Users/opastirm/ocihpc-test/config.json file before running ocihpc deploy command
```

### 3 - Deploy
After you initialize, you can deploy the package with `ocihpc deploy <package name>`. This command will create a Stack on Oracle Cloud Resource Manager and deploy the package using it.

INFO: The tool will generate a deployment name that consists of _<package name>-<current directory>-<random-number>_.

Example:

```sh
$ ocihpc deploy ClusterNetwork

Starting deployment...

Deploying ClusterNetwork-ocihpc-test-7355 [0min 0sec]
Deploying ClusterNetwork-ocihpc-test-7355 [0min 17sec]
Deploying ClusterNetwork-ocihpc-test-7355 [0min 35sec]
...
```

For supported packages, you can set the number of nodes you want to deploy by adding it to the `ocihpc deploy` command. If the package does not support it, the tool will deploy with the default numbers.

For example, the following command will deploy a Cluster Network with 5 nodes:

```sh
$ ocihpc deploy ClusterNetwork 5
```

TIP: When running the `ocihpc deploy <package name>` command, your shell might autocomplete it to the name of the zip file in the folder. This is fine. The tool will correct it, you don't need to delete the .zip extension from the command.

For example, `ocihpc deploy ClusterNetwork` and `ocihpc deploy ClusterNetwork.zip` are both valid commands.


### 4 - Connect
When deployment is completed, you will see the the bastion/headnode IP that you can connect to:

```sh
Successfully deployed ClusterNetwork-ocihpc-test-7355

You can connect to your head node using the command: ssh opc@$STACK_IP -i <location of the private key you used>

You can also find the IP address of the bastion/headnode in ClusterNetwork-ocihpc-test-7355_access.info file
```

You can use the `oci connect` command or the `ssh` command from your terminal to connect to your bastion/headnode.

### 5 - Delete
When you are done with your deployment, you can delete by changing to the package folder and running `ocihpc delete <package name>`.

Example:
```sh
$ ocihpc delete ClusterNetwork

Deleting ClusterNetwork-ocihpc-test-7355 [0min 0sec]
Deleting ClusterNetwork-ocihpc-test-7355 [0min 17sec]
Deleting ClusterNetwork-ocihpc-test-7355 [0min 35sec]
...

Succesfuly deleted ClusterNetwork-ocihpc-test-7355
```