proxy: 
  proxytype: napalm  
  driver: junos  
  host: 100.100.100.1 
  username: saltuser  
  password: admin123  

router_details:
  hostname: R1-65001
  banner: "This is a IBGP R1 Router in 65001"

loopback_configs:
  loopback0:
    - ip: 1.1.1.1  # This will be used as the router ID for BGP  
      mask: 32
      status: primary
    - ip: 11.11.11.1
      mask: 32

wan_config:  
  em2:  
    ip: 100.100.100.1  
    mask: 24  
    mtu: 1986
    description: WAN Star Interface  

network_services:  
  ssh: true  

bgp_config:  
  router_id: 1.1.1.1 
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
  area: 0  
  interfaces:
    - lo0.0
    - em2.0
