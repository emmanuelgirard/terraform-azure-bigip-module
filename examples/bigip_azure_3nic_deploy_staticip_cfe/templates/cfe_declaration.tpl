{
  "class": "Cloud_Failover",
  "environment": "azure",
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
  },
  "failoverRoutes": {
    "enabled": false
  },
  "controls": {
    "class": "Controls",
    "logLevel": "silly"
  }
}
