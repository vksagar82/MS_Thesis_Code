configure_services:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/configure_services.j2  
    - template_engine: jinja  
    - replace: False  
    - skip_verify: True
