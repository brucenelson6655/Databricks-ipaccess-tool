#!/bin/bash

echo $adbhost
echo $commandline

noexecmode=0
service_tag_file="ServiceTags_Public_20221024.json"


execcurl() {
  jqmode=$1 #true or false
  if [ $noexecmode == 1 ]; then 
     cat api_temp
  elif [ $jqmode ]; then 
     echo "JQ Mode"
     sh api_temp | jq
  else
     echo "No JQ Mode"
     sh api_temp
  fi
}

ipaclstatus() {
  echo "curl --netrc-file ${netrcfile} -X GET ${adbhost}/api/2.0/workspace-conf?keys=enableIpAccessLists" > api_temp
  execcurl true
}

listacls() 
{
  echo "curl --netrc-file ${netrcfile} -X GET ${adbhost}/api/2.0/ip-access-lists" > api_temp 
  execcurl true
}

get_listid() {
   echo "curl --netrc-file ${netrcfile} -X GET ${adbhost}/api/2.0/ip-access-lists" > api_temp 
   list_id=`sh api_temp | jq '.ip_access_lists[] | select( .label == "'${filter_by}'")?' | jq .list_id | tr -d '"'`
   # above command shold use == not contains
   echo $list_id
}

listaclbyid() {
# ## get a specific access list 
  local list_id=$1
  echo "curl --netrc-file ${netrcfile} -X GET  ${adbhost}/api/2.0/ip-access-lists/${list_id}" > api_temp
  # sh api_temp | jq
  execcurl true
}

get_service_tag() {
  stlist=`cat ${service_tag_file} | jq '.values[] | select(.id == "'${filter_by}'")?' | jq .properties.addressPrefixes[] | grep -E "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" |paste -sd "," - | sed 's/,/,\n/g'`
  echo $stlist
}

ipaclon() {
  echo "curl --netrc-file ${netrcfile} -X PATCH ${adbhost}/api/2.0/workspace-conf?keys=enableIpAccessLists -d '{
    \"enableIpAccessLists\": \"true\"
    }'" > api_temp
  execcurl
}
ipacloff() {
  echo "curl --netrc-file ${netrcfile} -X PATCH ${adbhost}/api/2.0/workspace-conf?keys=enableIpAccessLists -d '{
     \"enableIpAccessLists\": \"false\"
    }'" > api_temp
  execcurl
}

deleteipacls()  {
   local list_id=$1
  echo "curl --netrc-file ${netrcfile} -X DELETE ${adbhost}/api/2.0/ip-access-lists/${list_id}" > api_temp
  execcurl
}

addipacls() {
## add to list
  local list_id=$1
  ipaddrs=$2
  echo "curl --netrc-file ${netrcfile} -X POST ${adbhost}/api/2.0/ip-access-lists -d '{
     \"label\": \"${ipaclname}\",
    \"list_type\": \"${ipacltype}\",
     \"ip_addresses\": [
        $ipaddrs
      ]
    }'" > api_temp
    execcurl true
}
updateipacls()  {
# update the list
  local list_id=$1
  ipaddrs=$2
  lines=0
  echo "curl --netrc-file ${netrcfile} -X PATCH ${adbhost}/api/2.0/ip-access-lists/${list_id} -d '{" > api_temp
  if [ $uipaclname ] ; then 
     echo  "\"label\": \"${ipaclname}\"" >> api_temp
     lines=$((lines+1))
  fi
  if [ $lines -eq 1 ] ; then 
    echo ","
    lines=0
  fi 
  if [ $uipacltype ] ; then 
     echo  "\"list_type\": \"${ipacltype}\"" >> api_temp
    lines=$((lines+1))
  fi
  if [ $lines -eq 1 ] ; then 
    echo ","
    lines=0
  fi 
  if [ $uipaddress ] ; then 
    echo  "\"ip_addresses\": [
          $ipaddrs
          ]" >> api_temp
    lines=$((lines+1))
  fi
  if [ $lines -eq 1 ] ; then 
    echo ","
    lines=0
  fi 
  if [ $aclenabled ] ; then 
    echo  \"enabled\": \"${aclenabled}\" >> api_temp
  fi

  echo "  }'" >> api_temp
    execcurl true
}

replaceipacls()  {
# update the list
  local list_id=$1
  ipaddrs=$2
  echo "curl --netrc-file ${netrcfile} -X PUT ${adbhost}/api/2.0/ip-access-lists/${list_id} -d '{
    \"label\": \"${ipaclname}\",
    \"list_type\": \"${ipacltype}\",
    \"ip_addresses\": [
        $ipaddrs
      ],
    \"enabled\": \"${aclenabled}\"
    }'" > api_temp
    execcurl true
}

usage() {
        echo "./$(basename $0) -h --> shows usage"
        echo "-H <Databricks workspace URL>"
        echo "-f IP list Filename"
        echo "-P <Pat Token>"
        echo "   (optional : used for setting up .netrc file"
        echo "-c <COMMAND>"
        echo "   ADD UPDATE DELETE REPLACE LIST"
        echo "-A <ACLNAME>"
        echo "-I <ACL ID> needed for update of acl name"
        echo "-t <ACL Type>"
        echo "   ALLOW DENY"
        echo "-T Azure Service Tag"
        echo "-d Disable ACL"
        echo "-e Enable ACL"
        echo "-x No Execute - for testing, returns command listing"
        echo "-s IP Access List Status"
        echo "-z <ON or OFF> turns on or off the IP access list feature."
        echo "   Status shown by the -s flag"
        exit
}

# #######################################
# Body                                  #
# #######################################
# adbhost=$1




commandline="LIST"
adbhost="https://adb-7804143827420294.14.azuredatabricks.net"
ipacltype="ALLOW"
aclenabled="true"

# payloadfile=$3

# # ## list current access lists
# filter_by=$4

# service_tag_file=SeviceTags_Public_20220912.json


# mylistid=$(get_listid)

# echo "IP Access List ID : " $mylistid

optstring=":hH:P:Ddec:T:A:I:t:f:xsz:"

if [ $# -eq 0 ] ; then 
  usage
  exit
fi

while getopts ${optstring} arg; do
  case ${arg} in
    h)
      echo "showing usage!"
      usage
      ;;
    d)
      disableacl=1
      aclenabled="false"
      uaclenabled=1
      ;;
    e)
      disableacl=0
      aclenabled="true"
      uaclenabled=1
      ;;
    f)
      payloadfile="${OPTARG}"
      uipaddress=1
      ;;
    c)
      echo "Command"
      commandline="${OPTARG}"
      ;;
    A)
      ipaclname="${OPTARG}"
      uipaclname=1
      ;;
    I)
      ipaclid="${OPTARG}"
      ;;
    t)
      ipacltype="${OPTARG}"
      uipacltype=1
      ;;
    T)
      sevice_tag_id="${OPTARG}"
      uipaddress=1
      ;;
    D)
      set -x 
      DEBUG=true
      ;;
    H)
      echo "Databricks Workspace"
      echo "${OPTARG} $arg"
      adbhost="${OPTARG}"
      trimmed_host=`echo $adbhost | awk -F/ '{print $3}'`
      hostbasename=`echo $adbhost | awk -F/ '{print $3}' | awk -F. '{print $1}'`
      netrcfile="./${hostbasename}.netrc"
      ;;
    P)
      echo "Pat Token"
      pat_token="${OPTARG}"
      ;;
    z)
      action="${OPTARG}"
      if [ $action = "ON" ] ; then 
        ipaclon
      elif [ $action = "OFF" ] ; then 
        ipacloff
      else
         echo " -z needs ON or OFF "
      fi
      ;;
    x)
      echo "no exec enabled"
      noexecmode=1
      ;;
    s)
      ipaclstatus
      exit 0
      ;;
    :)
      echo "$0: Must supply an argument to -$OPTARG." >&2
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 2
      ;;
  esac
done

if [ $DEBUG ] ; then 
  echo "URL " $adbhost
  echo "Hostname" $trimmed_host
  echo "PAT token " $pat_token
  echo "Command " $commandline
  echo "Service Tag " $sevice_tag_id
  echo "ACL Name " $ipaclname
  echo "ACL Type " $ipacltype
  echo "IP File " $payloadfile
  echo "NETRC File " $netrcfile
fi

if [ -s $netrcfile ] ; then 
  echo "Using NETRC " $netrcfile
elif [ $pat_token ] ; then 
  echo "creating netrc file $netrcfile"
  echo "machine ${trimmed_host}
login token
password ${pat_token}" > $netrcfile
else
  echo "Need to create an Netrc file interface"
  echo "Rerun with -P <PAT Token option>"
  exit
fi


## commands ###

if [ $commandline ] ; then 
  if [ $commandline = "LIST" ] ; then 
      if [ $ipaclname ] ; then 
        filter_by=$ipaclname
        mylistid=$(get_listid)
        echo "IP Access List ID : " $mylistid

        if [ -z "$mylistid" ] ; then
            echo "No ACLs Found"
            exit
        fi
        listaclbyid $mylistid
        exit
      else
        listacls
        exit
      fi 
  fi 
  
  if [ $commandline = "ADD" ] ; then 
     echo $commandline
     if [ $ipaclname ] ; then 
        filter_by=$ipaclname
        mylistid=$(get_listid)
        
        if [ -z "$mylistid" ] ; then
            echo "Name is Unique"
        else
            echo "ACL name $commandline is already taken. Please choose a different name"
            exit
        fi
     else 
        echo "Need an ACL name by adding -A <ACL>"
        exit
    fi
    if [ $payloadfile ] ; then 
        echo "Payload"
        addlist=`cat $payloadfile`
        echo $addlist
    elif [ $sevice_tag_id ] ; then 
        echo "Service Tag"
        filter_by=$sevice_tag_id
        addlist=$(get_service_tag)
    else
        echo "No IP file or Service Tag, Use -f for ip list file or -T for Service Tag"
    fi

    if [ -z $addlist ] ; then 
      echo "No IP list was created - check your source !"
      exit
    fi 

    addipacls $ipaclname "${addlist}"
    exit
  fi


  if [ $commandline = "UPDATE" ] ; then 
     echo $commandline
     if [ $ipaclname ] ; then 
        filter_by=$ipaclname
        mylistid=$(get_listid)
        echo "IP Access List ID : " $mylistid

        if [ -z "$mylistid" ] ; then
            echo "No ACLs Found"
            exit
        fi
     else 
        echo "Need an ACL name by adding -A <ACL>"
        exit
    fi
    if [ $payloadfile ] ; then 
        addlist=`cat $payloadfile`
        echo $addlist
    elif [ $sevice_tag_id ] ; then 
        filter_by=$sevice_tag_id
        addlist=$(get_service_tag)
    fi

    if [ -z $addlist ] ; then 
      echo "No IP list was created"
    fi 

    updateipacls $mylistid "${addlist}"
    exit
  fi

  if [ $commandline = "DELETE" ] ; then 
     echo $commandline 
     if [ $ipaclname ] ; then 
        filter_by=$ipaclname
        mylistid=$(get_listid)
        echo "IP Access List ID : " $mylistid

        if [ -z "$mylistid" ] ; then
            echo "No ACLs Found"
            exit
        fi
      elif [ ipaclid ] ; then 
         mylistid=$ipaclid
     else 
        echo "Need an ACL name by adding -A <ACL>"
        exit
    fi
     deleteipacls $mylistid
     exit
  fi

  if [ $commandline = "REPLACE" ] ; then 
     echo $commandline
     if [ $ipaclname ] ; then 
        filter_by=$ipaclname
        mylistid=$(get_listid)
        echo "IP Access List ID : " $mylistid

        if [ -z "$mylistid" ] ; then
            echo "No ACLs Found"
            exit
        fi
     else 
        echo "Need an ACL name by adding -A <ACL>"
        exit
    fi
    if [ $payloadfile ] ; then 
        addlist=`cat $payloadfile`
        echo $addlist
    elif [ $sevice_tag_id ] ; then 
        filter_by=$sevice_tag_id
        addlist=$(get_service_tag)
    else
        echo "No IP file or Service Tag, Use -f for ip list file or -T for Service Tag"
    fi

    if [ -z $addlist ] ; then 
      echo "No IP list was created - check your source !"
      exit
    fi 

    replaceipacls $mylistid "${addlist}"
    exit
  fi
  echo "Command $commandline not found"
  exit 
fi
# updateipacls $mylistid $payloadfile

# cat api_temp
# listaclbyid $mylistid
# exit

