remove_one_change:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/remove_one_change.j2  
    - template_engine: jinja  
    - commit_in_isolation: True  
    - skip_verify: True  
