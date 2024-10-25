configure_bgp:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/configure_bgp.j2  
    - template_engine: jinja  
    - skip_verify: True  
    - replace: False
