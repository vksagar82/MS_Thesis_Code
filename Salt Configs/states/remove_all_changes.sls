{# This will remove all except WAN IP details else will lose reachability #}  

remove_configurations:  
  netconfig.managed:  
    - template_name: /etc/salt/templates/remove_all_changes.j2  
    - template_engine: jinja  
    - commit_in_isolation: True  
    - skip_verify: True  
