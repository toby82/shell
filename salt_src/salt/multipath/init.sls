multipath.installed:
  pkg.installed:
    - pkgs:
      - device-mapper
      - device-mapper-multipath
  service.running:
    - name: multipathd
    - enable: True
    - watch:
      - file: /etc/multipath.conf
    - require:
      - pkg: multipath.installed
      - cmd: multipath.modprobe
  file.managed:
    - name: /etc/multipath.conf
    - source: salt://multipath/etc/multipath.conf
    - require:
      - pkg: multipath.installed

multipath.modprobe:
  cmd.run:
    - names:
      - "modprobe dm-multipath"
      - "modprobe dm-round-robin"
