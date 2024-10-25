configure_wan:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/configure_wan.j2  
    - template_engine: jinja  
    - replace: False  
    - skip_verify: True
