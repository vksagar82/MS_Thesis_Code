configure_loopback:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/configure_loopback.j2  
    - template_engine: jinja  
    - replace: False  
    - skip_verify: True  
    - commit_in_isolation: True
