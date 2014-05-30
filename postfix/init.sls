#!jinja|yaml

{% from "postfix/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('postfix:lookup')) %}

include:
  - postfix._maps

{% if datamap.ensure|default('installed') in ['absent', 'removed'] %}
  {% set pkgensure = 'removed' %}
{% else %}
  {% set pkgensure = 'installed' %}
{% endif %}

postfix:
  pkg:
    - {{ pkgensure }}
    - pkgs:
{% for p in datamap.pkgs %}
      - {{ p }}
{% endfor %}


{% for a in salt['pillar.get']('postfix:aliases', []) %}
alias_{{ a.name }}:
  alias:
    - {{ a.ensure|default('present') }}
    - name: {{ a.name }}
    - target: {{ a.target|default('root') }}
{% endfor %}

{{ datamap.config.mailname.path|default('/etc/mailname') }}:
  file:
    - managed
    - mode: 644
    - user: root
    - group: root
    - contents: |
        {{ salt['pillar.get']('postfix:settings:mailname', salt['grains.get']('fqdn')) }}
