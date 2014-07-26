#!jinja|yaml

{% from "postfix/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('postfix:lookup')) %}

include:
  - postfix

{% for class, maps in salt['pillar.get']('postfix:maps', {}).items() %}
/etc/postfix/{{ class }}:
  file:
    - directory
    - mode: 755
    - user: root
    - group: postfix
    - require:
      - pkg: postfix

  {% for m in maps|default([]) %}
/etc/postfix/{{ class }}/{{ m.name }}:
  file:
    - managed
    - mode: {{ m.mode|default(644) }}
    - user: root
    - group: postfix
    - require:
      - pkg: postfix
    - contents: |
    {% for k, v in m.pairs.items()|default({}) %}
        {{ k ~ '\t\t\t' ~ v }}
    {%- endfor %}
    {% if not m.type|default('btree') in ['btree'] %}
    - watch_in:
      - service: postfix
    {% else %}
/etc/postfix/{{ class }}/{{ m.name }}.db:
  cmd:
    - wait
    - name: '/usr/sbin/postmap {{ m.type|default('btree') }}:/etc/postfix/{{ class }}/{{ m.name }} && chgrp postfix /etc/postfix/{{ class }}/{{ m.name }}.db'
    - watch:
      - file: /etc/postfix/{{ class }}/{{ m.name }}
    {% endif %}
  {% endfor %}
{% endfor %}
