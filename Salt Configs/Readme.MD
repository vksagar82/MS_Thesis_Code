The entire tree is shown here, which are needed for salt to work properly.

/etc/salt/  
├── master  
├── pillar  
│ ├── arista10-65001.sls  
│ ├── arista10-65002.sls  
│ ├── arista11-65001.sls  
│ ├── arista11-65002.sls  
│ ├── arista1-65003.sls  
│ ├── arista2-65003.sls  
│ ├── arista3-65003.sls  
│ ├── arista4-65003.sls  
│ ├── arista9-65001.sls  
│ ├── arista9-65002.sls  
│ ├── cisco4-65002.sls  
│ ├── cisco5-65001.sls  
│ ├── cisco5-65002.sls  
│ ├── cisco6-65001.sls  
│ ├── cisco6-65002.sls  
│ ├── cisco7-65001.sls  
│ ├── cisco7-65002.sls  
│ ├── cisco7-65003.sls  
│ ├── cisco8-65002.sls  
│ ├── cisco8-65003.sls  
│ ├── juniper1-65001.sls  
│ ├── juniper1-65002.sls  
│ ├── juniper2-65001.sls  
│ ├── juniper2-65002.sls  
│ ├── juniper3-65001.sls  
│ ├── juniper3-65002.sls  
│ ├── juniper4-65001.sls  
│ ├── juniper5-65003.sls  
│ ├── juniper6-65003.sls  
│ ├── juniper8-65001.sls  
│ └── top.sls  
├── states  
│ ├── configure_all.sls  
│ ├── configure_all_test.sls  
│ ├── configure_bgp.sls  
│ ├── configure_host_details.sls  
│ ├── configure_loopback.sls  
│ ├── configure_ospf.sls  
│ ├── configure_services.sls  
│ ├── configure_wan.sls  
│ ├── remove_all_configs.sls  
│ └── test_loopbacks.sls  
└── templates  
 ├── configure_bgp.j2  
 ├── configure_host_details.j2  
 ├── configure_loopback.j2  
 ├── configure_ospf.j2  
 ├── configure_services.j2  
 ├── configure_wan.j2  
 └── remove_config.j2
