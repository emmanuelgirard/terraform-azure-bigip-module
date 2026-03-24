{
  "$schema": "https://raw.githubusercontent.com/F5Networks/f5-cloud-failover-extension/master/src/nodejs/schema/base_schema.json",
  "schemaVersion": "2.2.0",
  "class": "Cloud_Failover",
  "environment": "azure",
  "controls": {
    "class": "Controls",
    "logLevel": "silly"
  },
  "externalStorage": {
    "scopingName": "${storage_account_name}"
  },
  "failoverAddresses": {
    "enabled": true,
    "addressGroupDefinitions": [
      {
        "type": "networkInterfaceAddress",
        "scopingAddress": "${failover_vip}"
      }
    ],
    "requireScopingTags": false
  }
}
