proxy: 
  proxytype: napalm  
  driver: junos  
  host: 10.10.10.3 
  username: saltuser  
  password: admin123  

router_details:
  hostname: R3-65002
  banner: "This is a IBGP R3 Router in 65002"

loopback_configs:
  loopback0:
    - ip: 50.50.50.3  # This will be used as the router ID for BGP
      mask: 32
      status: primary
    - ip: 55.55.55.3
      mask: 32

wan_config:  
  em2:  
    ip: 10.10.10.3  
    mask: 24  
    mtu: 1986
    description: WAN Star Interface  

network_services:  
  ssh: true  

bgp_config:  
  router_id: 50.50.50.3 
  local_as: 65002
  rr_client: false
  neighbors:  
    IBGP:  # Group name for internal BGP neighbors  
      type: internal  # Set the group type  
      peer_as: 65002
      peers:  
        50.50.50.11:  
          description: Peer with R11 - 65002 

ospf_config:  
  area: 0  
  interfaces:
    - lo0.0
    - em2.0
