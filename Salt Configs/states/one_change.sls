configure_one_change:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/one_change.j2  
    - template_engine: jinja  
    - skip_verify: True  
    - replace: False
