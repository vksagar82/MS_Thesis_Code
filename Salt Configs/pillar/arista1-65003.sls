proxy: 
  proxytype: napalm  
  driver: eos 
  host: 20.20.20.1 
  username: saltuser  
  password: admin123  
  optional_args:
    global_delay_factor: 2
    force_cfg_session_invalid: True 

router_details:
  hostname: R1-65003
  banner: "This is a IBGP R1 Router in 65003"

loopback_configs:
  loopback0:
    - ip: 80.80.80.1  # This will be used as the router ID for BGP  
      mask: 255.255.255.255
      status: primary
  loopback1: 
    - ip: 88.88.88.1
      mask: 255.255.255.255

wan_config:  
  Ethernet2:  
    ip: 20.20.20.1
    mask: 255.255.255.0  
    mtu: 1986
    description: WAN Star Interface  
  Ethernet3:  
    ip: 90.90.90.92
    mask: 255.255.255.0  
    mtu: 1500
    description: EBGP WAN Interface 

network_services:  
  ssh: true  

bgp_config:  
  router_id: 80.80.80.1 
  local_as: 65003
  rr_client: false
  neighbors:  
    IBGP:  # Group name for internal BGP neighbors  
      type: internal  # Set the group type  
      peer_as: 65003
      peers:  
        80.80.80.8:  
          description: Peer with R8 - 65003  
    EBGP_65002:
      type: external
      peer_as: 65002
      next_hop: 90.90.90.91
      peers:
        50.50.50.8:
          description: Peer with R8 - 65002

ospf_config:  
  router_id: 80.80.80.1
  area: 0  
  networks:
    - network: 80.80.80.1
      mask: 0.0.0.0
    - network: 88.88.88.1 
      mask: 0.0.0.0
    - network: 20.20.20.0 
      mask: 0.0.0.255
  passive:
    - loopback 0
    - loopback 1
