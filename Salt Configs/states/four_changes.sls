configure_four_changes:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/four_changes.j2  
    - template_engine: jinja  
    - skip_verify: True  
    - replace: False
