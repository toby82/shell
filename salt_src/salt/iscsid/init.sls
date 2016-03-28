iscsid.installed:
  pkg.installed:
    - pkgs: 
      - iscsi-initiator-utils
    - skip_verify: True
  service.running:
    - name: iscsid
    - enable: True
    - require:
      - pkg: iscsid.installed
