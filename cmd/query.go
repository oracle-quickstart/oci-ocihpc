// This software is licensed under the Universal Permissive License (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl

package cmd

var outputQuery = map[string]string{
	"ClusterNetwork":    "bastion",
	"CFDClusterNetwork": "bastion",
}

var stackUser = map[string]string{
	"ClusterNetwork":    "opc",
	"CFDClusterNetwork": "opc",
}

var stackVersion = map[string]string{
	"ClusterNetwork":    "0.12.x",
	"CFDClusterNetwork": "0.12.x",
}

var defaultNodeCount = map[string]string{
	"ClusterNetwork":    "2",
	"CFDClusterNetwork": "2",
}
