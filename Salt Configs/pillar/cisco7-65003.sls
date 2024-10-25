proxy: 
  proxytype: napalm  
  driver: ios 
  host: 20.20.20.7 
  username: saltuser  
  password: admin123  
  optional_args:
    disk_file_system: 'flash:'
    global_delay_factor: 2  
    fast_cli: True
    read_timeout: 90

router_details:
  hostname: R7-65003
  banner: "This is a IBGP R7 Router in 65003"

loopback_configs:
  loopback0:
    - ip: 80.80.80.7  # This will be used as the router ID for BGP  
      mask: 255.255.255.255
      status: primary
  loopback1: 
    - ip: 88.88.88.7
      mask: 255.255.255.255

wan_config:  
  GigabitEthernet0/2:  
    ip: 20.20.20.7
    mask: 255.255.255.0  
    mtu: 1986
    description: WAN Star Interface  

network_services:  
  ssh: true  

bgp_config:  
  router_id: 80.80.80.7
  local_as: 65003
  rr_client: false
  neighbors:  
    IBGP:  # Group name for internal BGP neighbors  
      type: internal  # Set the group type  
      peer_as: 65003
      peers:  
        80.80.80.8:  
          description: Peer with R8 - 65003  

ospf_config:  
  router_id: 80.80.80.7
  area: 0  
  networks:
    - network: 80.80.80.7
      mask: 0.0.0.0
    - network: 88.88.88.7 
      mask: 0.0.0.0
    - network: 20.20.20.0 
      mask: 0.0.0.255
  passive:
    - loopback 0
    - loopback 1
