# Infrastructure as Code — Ansible Reference

## Role Structure
```
roles/myapp/
├── tasks/main.yml
├── handlers/main.yml
├── templates/         # Jinja2 .j2 files
├── files/
├── vars/main.yml
├── defaults/main.yml  # overridable defaults
└── meta/main.yml
```

## Playbook Pattern
```yaml
# playbooks/deploy.yml
---
- name: Deploy myapp
  hosts: app_servers
  become: true
  vars_files:
    - ../vars/{{ env }}.yml
  roles:
    - common
    - myapp
  tags: [deploy]
```

## Inventory (INI + Group Vars)
```ini
# inventory/production/hosts
[app_servers]
app1.example.com ansible_user=ubuntu
app2.example.com ansible_user=ubuntu

[db_servers]
db1.example.com

[all:vars]
ansible_ssh_private_key_file=~/.ssh/deploy_key
```

## Task Patterns
```yaml
# roles/myapp/tasks/main.yml
---
- name: Install required packages
  ansible.builtin.package:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - python3-pip
  notify: Restart nginx

- name: Deploy application config
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/myapp/app.conf
    owner: myapp
    group: myapp
    mode: '0640'
  notify: Restart myapp

- name: Ensure service is running
  ansible.builtin.systemd:
    name: myapp
    state: started
    enabled: true
    daemon_reload: true
```

## Handlers
```yaml
# roles/myapp/handlers/main.yml
---
- name: Restart nginx
  ansible.builtin.systemd:
    name: nginx
    state: restarted

- name: Restart myapp
  ansible.builtin.systemd:
    name: myapp
    state: restarted
```

## Vault for Secrets
```bash
# Encrypt a value
ansible-vault encrypt_string 'super_secret' --name 'db_password'

# Encrypt a file
ansible-vault encrypt vars/secrets.yml

# Run playbook with vault
ansible-playbook deploy.yml --vault-password-file ~/.vault_pass
```

## Common Commands
```bash
# Syntax check
ansible-playbook deploy.yml --syntax-check

# Dry run
ansible-playbook deploy.yml --check --diff

# Run specific tags
ansible-playbook deploy.yml --tags deploy

# Limit to specific hosts
ansible-playbook deploy.yml --limit app1.example.com

# Ad-hoc command
ansible app_servers -m ansible.builtin.command -a "uptime"
```
