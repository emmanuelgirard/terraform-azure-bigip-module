{
  "schemaVersion": "1.0.0",
  "class": "Device",
  "async": true,
  "label": "Onboard BIG-IP",
  "Common": {
    "class": "Tenant",
    "mySystem": {
      "class": "System",
      "hostname": "${hostname}"
    },
    "dbVars": {
      "class": "DbVariables",
      "config.allow.rfc3927": "enable"
    },
    "myDns": {
      "class": "DNS",
      "nameServers": [
        ${name_servers}
      ],
      "search": [
        "f5.com"
      ]
    },
    "myNtp": {
      "class": "NTP",
      "servers": [
         ${ntp_servers}
      ],
      "timezone": "UTC"
    },
    "${vlan-name1}": {
      "class": "VLAN",
      "tag": 4093,
      "mtu": 1500,
      "interfaces": [
        {
          "name": "1.1",
          "tagged": false
        }
      ],
      "cmpHash": "dst-ip"
    },
    "${vlan-name1}-self": {
      "class": "SelfIp",
      "address": "${self-ip1}/24",
      "vlan": "${vlan-name1}",
      "allowService": "none",
      "trafficGroup": "traffic-group-local-only"
    },
      "default": {
      "class": "Route",
      "gw": "${gateway}",
      "network": "default",
      "mtu": 1500
     },
    "${vlan-name2}": {
      "class": "VLAN",
      "tag": 4094,
      "mtu": 1500,
      "interfaces": [
        {
          "name": "1.2",
          "tagged": false
        }
      ],
      "cmpHash": "dst-ip"
    },
    "${vlan-name2}-self": {
      "class": "SelfIp",
      "address": "${self-ip2}/24",
      "vlan": "${vlan-name2}",
      "allowService": "default",
      "trafficGroup": "traffic-group-local-only"
    },
    "configsync": {
            "class": "ConfigSync",
            "configsyncIp": "/Common/internal-subnet-self/address"
        },
        "failoverAddress": {
            "class": "FailoverUnicast",
            "address": "/Common/internal-subnet-self/address"
        },
        "failoverGroup": {
            "class": "DeviceGroup",
            "type": "sync-failover",
            "members": ["10.2.1.5","10.2.1.4"],
            "owner": "/Common/failoverGroup/members/0",
            "autoSync": true,
            "saveOnAutoSync": false,
            "networkFailover": true,
            "fullLoadOnSync": false,
            "asmSync": false
        },
        "trust": {
            "class": "DeviceTrust",
            "localUsername": "${bigip_username}",
            "localPassword": "${bigip_password}",
            "remoteHost": "/Common/failoverGroup/members/0",
            "remoteUsername": "${bigip_username}",
            "remotePassword": "${bigip_password}"
        }
  }
}
