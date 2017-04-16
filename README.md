rsync_backup Ansible playbook
=============================

This role will deploy rbackup.sh, a simple rsync-based differential backup script with history purge.

Requirements
------------

None

Role Variables
--------------

Beside deploying the script, this role will manage your backup crontab for you if you populate `rsync_backup_crons`:

  - `rsync_backup_crons`: list of dicts containing the following items:
    - `name`: a unique name for the backup
    - `source`: a rsync-compatible source to backup
    - `destination`: a rsync-compatible destination directory to put
      backups in
    - `keep`: number of previous backups to keep
    - `day`: cron-compatible day specification
    - `hour`: cron-compatible hour specification
    - `minute`: cron-compatible minute specification
    - `log`: log file name (will be written in  /var/log/rbackup/ and rotated)

Example
-------

```
rsync_backup_crons:
  - name: Some files
    source: /vagrant
    destination: /backupvagrant
    keep: 5
    day: "*"
    hour: 1
    minute: 5
  - name: Some other files
    source: /etc/logrotate.d
    destination: /backuplogrotate
    keep: 3
    day: "*"
    hour: 5
    minute: 15
    log: backuplogrotate.log
```

Tags
----

  - rbackup

Dependencies
------------

None

Example Playbook
----------------

Specs
-----

To run tests locally in a Vagrant machine, just hit:

    vagrant up
    vagrant ssh -c specs

If you want to run the test playbook fast (i.e., without re-installing Ansible),
just run:

    vagrant ssh -c 'specs -p'

License
-------

MIT

Author Information
------------------

@leucos.

