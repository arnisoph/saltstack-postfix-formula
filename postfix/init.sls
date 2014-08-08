#!jinja|yaml

{% from "postfix/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('postfix:lookup')) %}

include:
  - postfix._maps
{% for si in salt['pillar.get']('postfix:lookup:sls_include', []) %}
  - {{ si }}
{% endfor %}

extend: {{ salt['pillar.get']('postfix:lookup:sls_extend', '{}') }}

{% if datamap.ensure|default('installed') in ['absent', 'removed'] %}
  {% set pkgensure = 'removed' %}
{% else %}
  {% set pkgensure = 'installed' %}
{% endif %}

postfix:
  pkg:
    - {{ pkgensure }}
    - pkgs: {{ datamap.pkgs }}
  service:
    - {{ datamap.service.state|default('running') }}
    - name: {{ datamap.service.name|default('postfix') }}
    - enable: {{ datamap.service.enable|default(True) }}
    - watch:
{% for f in datamap.config.manage %}
      - file: {{ f }}
{% endfor %}


{% for a in salt['pillar.get']('postfix:aliases', []) %}
alias_{{ a.name }}:
  alias:
    - {{ a.ensure|default('present') }}
    - name: {{ a.name }}
    - target: {{ a.target|default('root') }}
    - watch_in:
      - cmd: newaliases
{% endfor %}

newaliases:
  cmd:
    - wait
    - name: /usr/bin/newaliases

{% if 'mailname' in datamap.config.manage|default([]) %}
mailname:
  file:
    - managed
    - name: {{ datamap.config.mailname.path|default('/etc/mailname') }}
    - mode: 644
    - user: root
    - group: root
    - contents: |
        {{ salt['pillar.get']('postfix:settings:mailname', salt['grains.get']('fqdn')) }}
{% endif %}

{% if 'main' in datamap.config.manage|default([]) %}
main:
  file:
    - managed
    - name: {{ datamap.config.master.path|default('/etc/postfix/main.cf') }}
    - source: salt://postfix/files/main.cf
    - mode: 644
    - user: root
    - group: postfix
    - template: jinja
{% endif %}

{% if 'master' in datamap.config.manage|default([]) %}
master:
  file:
    - managed
    - name: {{ datamap.config.master.path|default('/etc/postfix/master.cf') }}
    - source: salt://postfix/files/master.cf
    - mode: 640
    - user: root
    - group: postfix
    - template: jinja
{% endif %}

{% if 'bounce_msg' in datamap.config.manage|default([]) %}
bounce_msg:
  file:
    - managed
    - name: {{ datamap.config.bounce_msg.path|default('/etc/postfix/other/bounce_msg') }}
    - source: salt://postfix/files/bounce_msg
    - mode: 644
    - user: root
    - group: root
    - template: jinja
{% endif %}
