configure_ospf:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/configure_ospf.j2  
    - template_engine: jinja  
    - replace: False  
    - skip_verify: True
