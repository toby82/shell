limits.optimization:
  file.append:
    - name: /etc/security/limits.conf
    - text:
      - "* soft nofile 40960"
      - "* hard nofile 40960"
