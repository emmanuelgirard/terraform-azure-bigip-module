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
    "${vlan_name1}": {
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
    "${vlan_name1}-self": {
      "class": "SelfIp",
      "address": "${self_ip1}/${self_ip1_mask}",
      "vlan": "${vlan_name1}",
      "allowService": "none",
      "trafficGroup": "traffic-group-local-only"
    },
    "default": {
      "class": "Route",
      "gw": "${gateway}",
      "network": "default",
      "mtu": 1500
    },
    "${vlan_name2}": {
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
    "${vlan_name2}-self": {
      "class": "SelfIp",
      "address": "${self_ip2}/${self_ip2_mask}",
      "vlan": "${vlan_name2}",
      "allowService": "default",
      "trafficGroup": "traffic-group-local-only"
    },
    "configsync": {
      "class": "ConfigSync",
      "configsyncIp": "/Common/${vlan_name2}-self/address"
    },
    "failoverAddress": {
      "class": "FailoverUnicast",
      "address": "/Common/${vlan_name2}-self/address"
    },
    "failoverGroup": {
      "class": "DeviceGroup",
      "type": "sync-failover",
      "members": ["${member_a}", "${member_b}"],
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
      "remoteHost": "${remote_host}",
      "remoteUsername": "${bigip_username}",
      "remotePassword": "${bigip_password}"
    }
  }
}
