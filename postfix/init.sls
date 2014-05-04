{% from "postfix/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('postfix:lookup')) %}

{% if datamap.ensure|default('installed') in ['absent', 'removed'] %}
  {% set pkgensure = 'removed' %}
{% endif %}

postfix:
  pkg:
    - {{ pkgensure|default('installed') }}
    - pkgs:
{% for p in datamap.pkgs %}
      - {{ p }}
{% endfor %}
