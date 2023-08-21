#!/bin/bash -e

if [ -z "$3" ]
then
    echo '{"error": "provide all args: $0 $orgname $patname $scopes $outfile"}'
else
    org=$1
    name=$2
    scopes=$3
    outfile=$4
    aztoken=$(timeout 30 az account get-access-token --scope "499b84ac-1321-427f-aa17-267ca6975798/user_impersonation" --query accessToken --output tsv);
    patreq="{\"displayName\": \"$name\", \"scope\": \"$scopes\", \"validTo\": \"9999-12-31 23:59:59Z\", \"allOrgs\": true}"
    
    adopat=$(timeout 30 curl --silent --request POST -H "Authorization: Bearer $aztoken" -H "Content-Type: application/json" -d "$patreq" "https://vssps.dev.azure.com/$org/_apis/tokens/pats?api-version=7.1-preview.1" | jq --compact-output --monochrome-output --ascii-output .patToken)
    rm -f $outfile
    echo $adopat > $outfile
    chmod 0400 $outfile
fi
