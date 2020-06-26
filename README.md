# ocihpc - Oracle Cloud Infrastructure HPC deployment tool

`ocihpc` is a tool for simplifying deployments of HPC applications in Oracle Cloud Infrastructure (OCI).

## Prerequisites
The OCI user account you use in `ocihpc` should have the necessary policies configured for OCI Resource Manager. Please check [this link](https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Tasks/managingstacksandjobs.htm) for information on required policies.

## Installing ocihpc

### Installing ocihpc on Linux

1. Download the latest release with the following command and extract it:
```sh
curl -LO https://github.com/oracle-quickstart/oci-ocihpc/releases/download/v1.0.2/ocihpc_v1.0.2_linux_x86_64.tar.gz
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
curl -LO https://github.com/oracle-quickstart/oci-ocihpc/releases/download/v1.0.2/ocihpc_v1.0.2_darwin_x86_64.tar.gz
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


1. Download the latest release from [this link](https://github.com/oracle-quickstart/oci-ocihpc/releases/download/v1.0.2/ocihpc_v1.0.2_windows_x86_64.zip) and extract it.

2. Add the ocihpc binary to your PATH.

3. Test that it works.
```sh
ocihpc.exe version 
```




## Using ocihpc

### 1 - Configure
Run ```ocihpc configure``` to check if you have a valid configuration to access OCI. The tool will walk you through creating a configuration.

In order to create your config file, you will need:
- Your user OCID (found in profile section at the top right of the screen under > user settings > user information tab),
- Tenancy OCID (Administration > Tenancy Details > Tenancy Information tab), and
- The region you are working out of (i.e. us-phoenix-1, us-ashburn-1, etc.)


You will be notified where your config file is written to:
```Configuration file saved to: /Users/sergiog/.oci/config```


Next, we will ensure that we have uploaded our API keys that we generated in the prerequisites to our user on OCI.

Navigate back to your user settings under the profile icon in OCI. Scroll down to find “API Keys” under the resources section.

To add a public key to your user, you can either:
Copy and paste the public key (you can get a copy of your key by running this command in the CLI):
```cat ~/.oci/oci_api_key_public.pem | pbcopy```
Or, you can select the key file from your files (be sure to use command+shift+. To access your hidden .oci directory)
Once the key is successfully added, you will notice the fingerprint has been added to your API Keys. 


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

Navigate to your newly created directory (ocihpc-test in this case) and open the “config.json” file using texteditor or notepad. 
Note that this is not the same config file we configured in step 1.

For this config file, we will need:
- The availability domain information that contains the HPC resources in our tenancy (Administration > Tenancy Details > Scroll down to the Service Limits section > Compute > and scroll down to find “BM.HPC2.36”) - In the screenshot below, we can see that we have a total of 6 BM.HPC2.36 machines to use in AD-2, 0 of which are currently in use. 
 

- The Bastion AD can be any AD you chose as long as there are resources (VM.standard2.1 shape)
- Bastion shape should be filled in already - VM.Standard2.1
- Node count: for the purposes of this lab, we will go with 2 so as to use up all HPC resources
- Your public ssh key 

Here is an example of a completed config.json file:
```    
{
        "ad": "jiVG:US-ASHBURN-AD-2",
        "bastion_ad": "jiVG:US-ASHBURN-AD-2",
        "bastion_shape": "VM.Standard2.1",
        "node_count": "2",
        "ssh_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgItPoh4omGT98Xa/IDy3dhO7tmgWT57f/k75pzOhFODRIBbjUMAqcwqjQI6Zd4jager2OSTWx2yczNhOCIZzO+xL5czql9olLI4oxFyN6Cc5S/Renilz2twxfNXTK7eI+3qDt+fz4jht5wWdMKK18QFkp6gtsHLqgVUEfng3rzSxSLJJInhwhJHD+zBSTuo61f6riQAQl+NRUzfF5B/mALe6AejFyRcc3FPRjv3NfLK/gv/Ulzu+KgyTXeNkIMLc0zeNUN8Y3/V36MzHvZ01mRZU47ortJieFXhCNn/Wx6OrsRppKVuW6My1TI4J/U9IZylvGOL2AdDdlMX0QYohZ sergiog@Sergios-MBP-2.attlocal.net"
    }
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
