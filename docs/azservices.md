# Allow Azure Services

| Scenario ID | Service Tag                   |
| ----------- | ----------------------------- |
| `azservices`       | N/A (similar to `AzureCloud`) |

## Setup

Setup of this scenario follows the standard setup steps outlined in the [main README](../README.md#Deployment).

## Scenario

In this scenario we're looking at taking advantage of a network toggle found on Azure database services, typically worded as one of the following:

- Allow Azure services and resources to access this server
- Accept connections from within public Azure datacenters

Functionally, these are very similar to the `AzureCloud` service tag in that they permit inbound traffic from all IP addresses within the Azure public cloud. And, as with abusing the `AzureCloud` service tag, an attacker can simply deploy a virtual machine within their own Azure environment in order to interact with the target SQL deployment.

![AzureServices attack diagram](../img/diag/azureservices/attack.svg)

You can find any of the URIs & credentials for this scenario in the output of `terraform apply` e.g.:

```plain
sql = {
  "sql_uri" = "statgtsqlue1xsql.mysql.database.azure.com"
  "sql_username" = "sqladmin"
  "sql_password" = "password"
  "sql_command" = "mysql --user=sqladmin --password='password' --host=statgtsqlue1xsql.mysql.database.azure.com --ssl"
  "ssh_command" = "ssh -i /home/vagrant/repos/service-tag-abuse/keys/staatksqlue1xattackvm_rsa adminuser@staatksqlue1xattackvm.uksouth.cloudapp.azure.com"
}
```

If you try to interact with the SQL server directly, using the command provided in the terraform output, you'll find that the connection times out. You can, however, ssh to the deployed attack box, and execute the same mysql command from there. This attempt should be successful, as the requests originates from an IP range within the Azure public cloud address space.

```sh
> ssh -i /home/vagrant/repos/service-tag-abuse/keys/staatksqlue1xattackvm_rsa adminuser@staatksqlue1xattackvm.uksouth.cloudapp.azure.com

> mysql --user=sqladmin --password='password' --host=statgtsqlue1xsql.mysql.database.azure.com --ssl
```

This should succesfully authenticate allowing us to perform further actions, such as listing the present databases, as shown below:

```sh
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 14
Server version: 5.7.42-log MySQL Community Server (GPL)

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| exampledb          |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.001 sec)
```
