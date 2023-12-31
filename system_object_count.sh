#!/bin/bash

<< ////

The sample code described herein is provided on an "as is" basis, without warranty of any kind, to the fullest extent permitted by law. ForgeRock does not warrant or guarantee the individual success developers may have in implementing the sample code on their development platforms or in production configurations.

ForgeRock does not warrant, guarantee or make any representations regarding the use, results of use, accuracy, timeliness or completeness of any data or information relating to the sample script. ForgeRock disclaims all warranties, expressed or implied, and in particular, disclaims all warranties of merchantability, and warranties related to the script/code, or any service or software related thereto.

ForgeRock shall not be liable for any direct, indirect or consequential damages or costs of any type arising out of any action taken by you or others related to the sample script/code.

////

FQDN='XXXXXX'                #Tenant FQDN. For example openam-mytenant.forgerock.io
CONNECTOR='XXXXXX'           #IDM Connector Name. For example LDAP
ACCOUNT_IDENTIFIER='account' #IDM Connector account identifier. DS connectors by default use 'account'. DB connectors typically use '__ACCOUNT__'
PAGED_RESULTS_COOKIE=''      #Set this value to 0 without quotes for DBs
OBJECT_COUNT=0
PAGE_SIZE=100000
DEBUG=false

#Do not modify
DONE=false
COUNT=1

ADMIN_BEARER_TOKEN=$1
echo "********************"
if [ -z "${ADMIN_BEARER_TOKEN}" ]; then
  echo "No Bearer Token supplied. Acquire an admin bearer to for the environment and then execute using ./service_accounts.sh eyJ0eXAiOiJKV..."
  exit 1
fi

START_TIME=$(date +"%s")

while [ ${DONE} = false ]; do
  echo "********************"
  echo "Execution cycle: ${COUNT}"
  REQUEST_START_TIME=$(date +"%s")

  REQUEST=$(curl -s \
    -X GET \
    --header 'Authorization: Bearer '${ADMIN_BEARER_TOKEN}'' \
    --header "Content-Type: application/json" \
    'https:/'${FQDN}'/openidm/system/'${CONNECTOR}'/'${ACCOUNT_IDENTIFIER}'?_queryFilter=true&_pageSize='${PAGE_SIZE}'&_fields=_id&_pagedResultsCookie='${PAGED_RESULTS_COOKIE}'' | jq .)

  if [ "${DEBUG}" = true ]; then
    echo ${REQUEST}
  fi

  RESULT_COUNT=$(echo ${REQUEST} | jq -r .resultCount)
  echo "Result count from query: ${RESULT_COUNT}"
  OBJECT_COUNT=$(($RESULT_COUNT + $OBJECT_COUNT))
  echo "Total user count: ${OBJECT_COUNT}"
  PAGED_RESULTS_COOKIE=$(echo ${REQUEST} | jq -r .pagedResultsCookie)

  if [[ "${PAGED_RESULTS_COOKIE}" = "null" ]]; then
    echo "Count complete"
    DONE=true
  else
    echo "Continuing - All user records not returned. Current Page Results cookie value is ${PAGED_RESULTS_COOKIE}"
  fi

  END_TIME=$(date +"%s")
  REQUEST_TIME_DIFF=$((${END_TIME} - ${REQUEST_START_TIME}))
  echo "Request/response execution time: $(($REQUEST_TIME_DIFF / 60)) minutes and $(($REQUEST_TIME_DIFF % 60)) seconds"
  TIME_DIFF=$((${END_TIME} - ${START_TIME}))
  echo "Total request/response execution time: $(($TIME_DIFF / 60)) minutes and $(($TIME_DIFF % 60)) seconds"
  COUNT=$((${COUNT} + 1))
done