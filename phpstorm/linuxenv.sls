{% from "phpstorm/map.jinja" import phpstorm with context %}

{% if grains.os not in ('MacOS', 'Windows',) %}

phpstorm-home-symlink:
  file.symlink:
    - name: '{{ phpstorm.jetbrains.home }}/phpstorm'
    - target: '{{ phpstorm.jetbrains.realhome }}'
    - onlyif: test -d {{ phpstorm.jetbrains.realhome }}
    - force: True

# Update system profile with PATH
phpstorm-config:
  file.managed:
    - name: /etc/profile.d/phpstorm.sh
    - source: salt://phpstorm/files/phpstorm.sh
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - context:
      home: '{{ phpstorm.jetbrains.home|json }}/phpstorm'

  # Linux alternatives
  {% if phpstorm.linux.altpriority > 0 and grains.os_family not in ('Arch',) %}

# Add phpstorm-home to alternatives system
phpstorm-home-alt-install:
  alternatives.install:
    - name: phpstorm-home
    - link: '{{ phpstorm.jetbrains.home }}/phpstorm'
    - path: '{{ phpstorm.jetbrains.realhome }}'
    - priority: {{ phpstorm.linux.altpriority }}
    - retry:
        attempts: 2
        until: True

phpstorm-home-alt-set:
  alternatives.set:
    - name: phpstorm-home
    - path: {{ phpstorm.jetbrains.realhome }}
    - onchanges:
      - alternatives: phpstorm-home-alt-install
    - retry:
        attempts: 2
        until: True

# Add to alternatives system
phpstorm-alt-install:
  alternatives.install:
    - name: phpstorm
    - link: {{ phpstorm.linux.symlink }}
    - path: {{ phpstorm.jetbrains.realcmd }}
    - priority: {{ phpstorm.linux.altpriority }}
    - require:
      - alternatives: phpstorm-home-alt-install
      - alternatives: phpstorm-home-alt-set
    - retry:
        attempts: 2
        until: True

phpstorm-alt-set:
  alternatives.set:
    - name: phpstorm
    - path: {{ phpstorm.jetbrains.realcmd }}
    - onchanges:
      - alternatives: phpstorm-alt-install
    - retry:
        attempts: 2
        until: True

  {% endif %}

  {% if phpstorm.linux.install_desktop_file %}
phpstorm-global-desktop-file:
  file.managed:
    - name: {{ phpstorm.linux.desktop_file }}
    - source: salt://phpstorm/files/phpstorm.desktop
    - template: jinja
    - context:
      home: {{ phpstorm.jetbrains.realhome|json }}
      command: {{ phpstorm.command|json }}
      edition: {{ phpstorm.jetbrains.edition|json }}
    - onlyif: test -f {{ phpstorm.jetbrains.realhome }}/{{ phpstorm.command }}
  {% endif %}

{% endif %}
