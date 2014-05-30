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
