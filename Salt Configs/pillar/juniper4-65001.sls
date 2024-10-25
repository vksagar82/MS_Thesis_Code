proxy: 
  proxytype: napalm  
  driver: junos  
  host: 100.100.100.4 
  username: saltuser  
  password: admin123  

router_details:
  hostname: R4-65001
  banner: "This is a IBGP R4 Router in 65001"

loopback_configs:
  loopback0:
    - ip: 1.1.1.4  # This will be used as the router ID for BGP
      mask: 32
      status: primary
    - ip: 11.11.11.4
      mask: 32

wan_config:  
  em2:  
    ip: 100.100.100.4  
    mask: 24  
    mtu: 1986
    description: WAN Star Interface  
  em3:  
    ip: 70.70.70.41  
    mask: 24  
    description: EBGP WAN Interface  

network_services:  
  ssh: true  

bgp_config:  
  router_id: 1.1.1.4 
  local_as: 65001  
  rr_client: false
  neighbors:  
    IBGP:  # Group name for internal BGP neighbors  
      type: internal  # Set the group type  
      peer_as: 65001
      peers:  
        1.1.1.8:  
          description: Peer with R8 - 65001
    EBGP_65002:
      type: external
      peer_as: 65002
      next_hop: 70.70.70.14
      peers:
        50.50.50.11:
          description: Peer with R11 - 65002  

ospf_config:  
  area: 0  
  interfaces:
    - lo0.0
    - em2.0
