# OCI Easy HPC deployment tool - ocihpc

`ocihpc` is a tool for simplifying deployments of HPC applications in Oracle Cloud Infrastructure (OCI).



### 1 - List
You can get the list of available packages by running `ocihpc.sh list`.

Example:

```sh
$ ocihpc.sh list

List of available packages:

ClusterNetwork
Gromacs
OpenFOAM
```

### 2 - Initialize
Initilize the package to deploy with `ocihpc.sh init <package name>`. This will create a directory with the package's name and put the needed files in it.

Example:

```sh
ocihpc.sh init ClusterNetwork
```

### 3 - Deploy
After you initialize, you can deploy the package with `ocihpc.sh deploy <package name>`. This command will create a Stack on Oracle Cloud Resource Manager and deploy the package using it.

Example:

```sh
ocihpc.sh deploy ClusterNetwork
```

### 4 - Connect
You can connect to the bastion of the package deployment with `ocihpc.sh connect <package name>`.

Example:

```sh
ocihpc.sh connect ClusterNetwork
```

### 5 - Delete
When you are done with your package deployment, you can delete it with `ocihpc.sh delete <package name>`.

Example:
```sh
ocihpc.sh delete ClusterNetwork
```
