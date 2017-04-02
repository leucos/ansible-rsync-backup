rbackup Ansible playbook
========================

Requirements
------------

None

Role Variables
--------------

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

There is a sample Guardfile if you want to work on the role in TDD mode. You need to install guard and guard-shell gems, and then run guard:

    gem install guard
    gem install guard-shell
    guard

Now the specs will run whenever you save a file in the role, the specs will be run.

License
-------

MIT

Author Information
------------------

@leucos.

