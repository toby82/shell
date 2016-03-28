include:
  - ncha.comm
extend:  
  /etc/rc.d/rc.local:
    file.append:
      - text:
        - "python /opt/software/ncha/timestampupdate.py  >/dev/null 2>&1 </dev/null &"
        - "python /opt/software/ncha/cchainit.py >/dev/null 2>&1 < /dev/null &"
  run_consul:
    cmd.run:
      - names:
        - "python /opt/software/ncha/lockfileinit.py  >/dev/null 2>&1 </dev/null &"
        - "python /opt/software/ncha/timestampupdate.py  >/dev/null 2>&1 </dev/null &"
        - "python /opt/software/ncha/cchainit.py >/dev/null 2>&1 < /dev/null &"
      - require:
        - file: consul
        - file: /etc/nova/ncha/netconfig.conf 
