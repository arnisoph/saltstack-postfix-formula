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
          john: REJECT Stop spamming
          chuck: REJECT Stop spamming
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
  main:
    sections:
      - name: GENERAL
        myhostname: mymailhostname
        myorigin: $myhostname
        mydestination: $myorigin, localhost, localhost.$mydomain, {{ salt['grains.get']('fqdn') }}
        mynetworks: 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
        inet_interfaces: all
        inet_protocols: ipv4
      - name: MAPS AND TRANSPORT SETTINGS
        alias_maps: hash:/etc/aliases
        alias_database: $alias_maps
      - name: MAIL AND CONNECTION LIMITATIONS
        message_size_limit: 67108864 {#- 64 MB #}
        mailbox_size_limit: 0
      - name: SMTP(D) RESTRICTIONS AND POLICIES
        smtpd_helo_required: 'yes'
        disable_vrfy_command: 'yes'
        smtpd_discard_ehlo_keywords: silent-discard, dsn
        smtpd_recipient_restrictions:
          reject_unauth_destination
          reject_non_fqdn_sender
          reject_non_fqdn_recipient
          reject_unknown_client_hostname
          reject_unknown_reverse_client_hostname
          reject_unverified_recipient
      - name: CODES AND REASONS
        unverified_recipient_reject_code: 557
        unverified_recipient_reject_reason: User unknown
      - name: AUTHENTICATION
        #smtp_sasl_auth_enable      = yes
        #smtp_sasl_security_options = noanonymous
        #smtp_sasl_mechanism_filter = plain, login
        #smtp_sasl_password_maps    = btree:/etc/postfix/sender/sasl_passwd
      - name: MISC
        smtpd_banner: $myhostname ESMTP $mail_name
        biff: 'no'
        debugger_command: PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin ddd $daemon_directory/$process_name $process_id & sleep 5
        append_dot_mydomain: 'no'
        append_at_myorigin: 'yes'
        readme_directory: 'no'
        recipient_delimiter: +
        soft_bounce: 'no'
#      - name: TRANSPORT SECURITY
#        smtpd_tls_loglevel: 1
#        smtpd_tls_dh1024_param_file: /etc/postfix/dh_2048.pem
#        smtpd_tls_dh512_param_file: /etc/postfix/dh_512.pem
#        smtpd_tls_eecdh_grade: strong
#        tls_preempt_cipherlist: 'yes'
