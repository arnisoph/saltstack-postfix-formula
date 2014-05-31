postfix:
  aliases:
    - name: root
      target: root@example.com
    - name: postmaster
  maps:
    postscreen:
      - name: postscreen_client_access.cidr
        type: cidr
        pairs:
          '2a00:1450:4000::/36': DUNNO
          '2c0f:fb50:4000::/36': DUNNO
    client:
      - name: client_access
        pairs: {}
    helo:
      - name: helo_access
        pairs:
          example.com: REJECT You are not in example.tld
          localhost: REJECT You are not me
    sender:
      - name: sender_access
        pairs:
          '{{ grains['fqdn'] }}': REJECT You are not me
    recipient:
      - name: recipient_access-rfc.pcre
        type: pcre
        pairs:
          '/^abuse\@/': permit_auth_destination
          '/^postmaster\@/': permit_auth_destination
          '/^webmaster\@/': permit_auth_destination
    other:
      - name: block_user
        pairs:
          john: "# he is spamming, let's block him"
          chuck: ''
  master:
    - service: smtp
      type: inet
      private: n
      command: smtpd
    - service: submission
      type: inet
      private: n
      command: smtpd
      cmdargs:
        - '-o syslog_name=postfix-submission'
    - service: pickup
      type: fifo
      private: n
      wakeup: 60
      maxproc: 1
    - service: cleanup
      private: n
      maxproc: 0
    - service: qmgr
      type: fifo
      private: n
      chroot: n
      wakeup: 300
      maxproc: 1
    - service: tlsmgr
      wakeup: 1000?
      maxproc: 1
    - service: rewrite
      command: trivial-rewrite
    - service: bounce
      maxproc: 0
    - service: defer
      maxproc: 0
      command: bounce
    - service: trace
      maxproc: 0
      command: bounce
    - service: verify
      maxproc: 1
    - service: flush
      private: n
      wakeup: 1000?
      maxproc: 0
    - service: proxymap
      chroot: n
    - service: proxywrite
      chroot: n
      maxproc: 1
      command: proxymap
    - service: smtp
      cmdargs:
        - '-o smtp_bind_address=<smtp_bind_address_here>'
        - '-o smtp_bind_address6=<smtp_bind_address6_here>'
    - service: relay
      command: smtp
    - service: showq
      private: n
    - service: error
    - service: retry
      command: error
    - service: discard
    - service: local
      unpriv: n
      chroot: n
    - service: virtual
      unpriv: n
      chroot: n
    - service: lmtp
    - service: anvil
      maxproc: 1
    - service: scache
      maxproc: 1
    - service: maildrop
      unpriv: n
      chroot: n
      command: pipe
      cmdargs:
        - 'flags=DRhu user=vmail argv=/usr/bin/maildrop -d ${recipient}'
    - service: uucp
      unpriv: n
      chroot: n
      command: pipe
      cmdargs:
        - 'flags=Fqhu user=uucp argv=uux -r -n -z -a$sender - $nexthop!rmail ($recipient)'
    - service: ifmail
      unpriv: n
      chroot: n
      command: pipe
      cmdargs:
        - 'flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r $nexthop ($recipient)'
    - service: bsmtp
      unpriv: n
      chroot: n
      command: pipe
      cmdargs:
        - 'flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t$nexthop -f$sender $recipient'
    - service: scalemail-backend
      unpriv: n
      chroot: n
      maxproc: 2
      command: pipe
      cmdargs:
        - 'flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store ${nexthop} ${user} ${extension}'
    - service: mailman
      unpriv: n
      chroot: n
      command: pipe
      cmdargs:
        - 'flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py ${nexthop} ${user}'
