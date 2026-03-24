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
    "scopingTags": {
      "f5_cfe_label": "${cfe_label}"
    }
  },
  "failoverAddresses": {
    "enabled": true,
    "scopingTags": {
      "f5_cfe_label": "${cfe_label}"
    }
  }
}
