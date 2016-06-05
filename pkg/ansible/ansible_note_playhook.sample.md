---
- hosts: droplets
  tasks:
    - name: Installs nginx web server
      apt: pkg=nginx state=installed update_cache=true
    # ansible -m apt -a 'whatever' all
    # simular apt-get  install nginx , and should be already `installed` , and `apt-get update` this package in this time

      notify: # contains a list with one item
        - <handler name>
  handlers:
    - name: start nginx
      sudo: true
      service: name=nginx state=started
      # as `service <service_name> <status>`