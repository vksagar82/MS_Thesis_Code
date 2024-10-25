proxy: 
  proxytype: napalm  
  driver: eos 
  host: 100.100.100.10 
  username: saltuser  
  password: admin123  
  optional_args:
    global_delay_factor: 2
    force_cfg_session_invalid: True 

router_details:
  hostname: R10-65001
  banner: "This is a IBGP R10 Router in 65001"

loopback_configs:
  loopback0:
    - ip: 1.1.1.10  # This will be used as the router ID for BGP  
      mask: 255.255.255.255
      status: primary
  loopback1: 
    - ip: 11.11.11.10
      mask: 255.255.255.255

wan_config:  
  Ethernet2:  
    ip: 100.100.100.10
    mask: 255.255.255.0  
    mtu: 1986
    description: WAN Star Interface  

network_services:  
  ssh: true  

bgp_config:  
  router_id: 1.1.1.10
  local_as: 65001
  rr_client: false
  neighbors:  
    IBGP:  # Group name for internal BGP neighbors  
      type: internal  # Set the group type  
      peer_as: 65001
      peers:  
        1.1.1.8:  
          description: Peer with R8 - 65001  

ospf_config:  
  router_id: 1.1.1.10
  area: 0  
  networks:
    - network: 1.1.1.10
      mask: 0.0.0.0
    - network: 11.11.11.10
      mask: 0.0.0.0
    - network: 100.100.100.0 
      mask: 0.0.0.255 
  passive:
    - loopback 0
    - loopback 1
