remove_four_changes:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/remove_four_changes.j2  
    - template_engine: jinja  
    - commit_in_isolation: True  
    - skip_verify: True  
