configure_host_details:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/configure_host_details.j2  
    - template_engine: jinja  
    - replace: False  
    - skip_verify: True
