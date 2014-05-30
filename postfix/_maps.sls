#!jinja|yaml

{% from "postfix/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('postfix:lookup')) %}

include:
  - postfix

{% for class, maps in salt['pillar.get']('postfix:maps', {}).items() %}
/etc/postfix/{{ class }}:
  file:
    - directory
    - mode: 750
    - user: root
    - group: postfix

  {% for m in maps|default([]) %}
/etc/postfix/{{ class }}/{{ m.name }}:
  file:
    - managed
    - mode: 640
    - user: root
    - group: postfix
    - contents: |
    {% for k, v in m.pairs.items()|default({}) %}
        {{ k ~ '\t\t\t' ~ v }}
    {%- endfor %}

    {% if m.type|default('btree') in ['btree'] %}
/etc/postfix/{{ class }}/{{ m.name }}.db:
  cmd:
    - wait
    - name: '/usr/sbin/postmap {{ m.type|default('btree') }}:/etc/postfix/{{ class }}/{{ m.name }} && chgrp postfix /etc/postfix/{{ class }}/{{ m.name }}.db'
    - watch:
      - file: /etc/postfix/{{ class }}/{{ m.name }}
    {% else %}
    {# TODO: reload/restart postfix #}
    {% endif %}
  {% endfor %}
{% endfor %}
