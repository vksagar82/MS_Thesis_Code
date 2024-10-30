# include:
#   - configure_loopback
#   - configure_wan
#   - configure_services
#   - configure_bgp
#   - configure_ospf
#   - configure_host_details

configure_all:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/all_changes.j2  
    - template_engine: jinja  
    - skip_verify: True  
    - replace: False
