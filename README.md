# Databricks-ipaccess-tool
Simple bash script based tool for automating Azure Databricks IP access lists add, update, replace and delete operations along with listing

## Getting started
First things first, run the ipacltool.sh script with a -h flag to show your usage : 
```
$ sh ./ipacltool.sh -h


showing usage!
./ipacltool.sh -h --> shows usage
-H <Databricks workspace URL>
-f IP list Filename
-P <Pat Token>
   (optional : used for setting up .netrc file
-c <COMMAND>
   ADD UPDATE DELETE REPLACE LIST
-A <ACLNAME>
-I <ACL ID> needed for update of acl name
-t <ACL Type>
   ALLOW DENY
-T Azure Service Tag
-d Disable ACL
-e Enable ACL
-x No Execute - for testing, returns command listing
-s IP Access List Status
-z <ON or OFF> turns on or off the IP access list feature.
   Status shown by the -s flag

```

Flags can be combined !  You will see an example of this below. 

### Setup 
The simplest way to setup __ipacltool__ for the first time is to run the tool with your Databricks url -H and pat token -P. This will setup your netrc file that is tied to your workspace so you will no longer need to use the -P pat token flag again. 

```
$ sh ./ipacltool.sh -H https://adb-6499070522450209.9.azuredatabricks.net -P dapxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


Databricks Workspace
https://adb-6499070522450209.9.azuredatabricks.net H
Pat Token
creating netrc file ./adb-6499070522450209.netrc
JQ Mode
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100     3  100     3    0     0      6      0 --:--:-- --:--:-- --:--:--     6
{}
```
You will notice a new netrc file adb-6499070522450209.netrc thats named for your Databricks workspace. 

### Enabling IP Access lists 
Before we can work with IP access lists we need to turn this feature on. Run ipacltool with the -s flag to show status

```
$ sh ./ipacltool.sh -H https://adb-6499070522450209.9.azuredatabricks.net -s
 

Databricks Workspace
https://adb-6499070522450209.9.azuredatabricks.net H
JQ Mode
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    29  100    29    0     0     55      0 --:--:-- --:--:-- --:--:--    55
{
  "enableIpAccessLists": null
}
```
IP access lists will return __null__ if its never been enabled. The -z flag turnes on or off IP access lists. You can combine the -z flag with the -s flag to show status as well. 

#### Turn "ON" IP Access Lists
```
$ sh ./ipacltool.sh -H https://adb-6499070522450209.9.azuredatabricks.net -z ON -s


Databricks Workspace
https://adb-6499070522450209.9.azuredatabricks.net H
No JQ Mode
JQ Mode
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    31  100    31    0     0    114      0 --:--:-- --:--:-- --:--:--   113
{
  "enableIpAccessLists": "true"
}
```
#### Turn "OFF" IP Access Lists
```
$ sh ./ipacltool.sh -H https://adb-6499070522450209.9.azuredatabricks.net -z OFF -s


Databricks Workspace
https://adb-6499070522450209.9.azuredatabricks.net H
No JQ Mode
JQ Mode
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    32  100    32    0     0    125      0 --:--:-- --:--:-- --:--:--   125
{
  "enableIpAccessLists": "false"
}
```
#### One more thing ... 
One additional flag you may find useful is the -x flag. If you add the -x flag before any other flags, ipacltool will not execute your commands / flags but dump out the curl command code for you to inspect or use in another application. Example running the -z flag above combined with the -x flag : 
```
$ sh ./ipacltool.sh -H https://adb-6499070522450209.9.azuredatabricks.net -x -z OFF -s


Databricks Workspace
https://adb-6499070522450209.9.azuredatabricks.net H
no exec enabled

curl --netrc-file ./adb-6499070522450209.netrc -X PATCH https://adb-6499070522450209.9.azuredatabricks.net/api/2.0/workspace-conf?keys=enableIpAccessLists -d '{
     "enableIpAccessLists": "false"
    }'

curl --netrc-file ./adb-6499070522450209.netrc -X GET https://adb-6499070522450209.9.azuredatabricks.net/api/2.0/workspace-conf?keys=enableIpAccessLists

```
## Commands (ADD UPDATE DELETE REPLACE LIST)
### IP lists and Service Tags 
For ADD, REPLACE and UPDATE, you can supply either an IP list in a file (-f filename) or an Azure Service Tag (-T Service Tag ID/Name). 
#### IP list example
```"70.93.162.189/32",
"44.230.222.179/32",
"44.228.166.17/32",
"136.226.64.0/21"
```
#### Azure Service Tags with an example 

```
$ sh ./ipacltool.sh -H https://adb-6499070522450209.9.azuredatabricks.net -c ADD -A activedir -T AzureActiveDirectory
```


### LIST

### ADD

### UPDATE

### REPLACE

### DELETE


