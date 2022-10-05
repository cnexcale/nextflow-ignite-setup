# nextflow-ignite-setup

Provides scripts to setup (compile + install) nextflow from source using a predefined list of hosts.

`distribute.py` is the main cli while using the the setup and distribute scripts of this repo under the hood.

`setup-nextflow.sh`/`setup-nextflow.git.sh` are used to prepare, compile and install nextflow on a host and conditionally start an ignite daemon on the host.

`distribute-nextflow.sh` will handle remote host resolution, possible cleanup and execute one of the setup scripts depending on the chosen mode.

`run-remote.sh` is used as a general script to execute other scripts on a list of remote hosts.

`setup-docker.sh` will install and setup Docker on a given host.


# Full setup

For full setup tutorial please see [full setup guide](full-setup/nf-ignite-setup.md) (atm: german only) for required steps and preparation to setup an Ignite based nextflow pipeline run.


# Usage

For a more convenient usage `distribute.py` provides a simple CLI interface with argument parsing and help/description texts. Use `./distribute.py --help` for an overview.
Except for the base `command` and `nf-source` all arguments come with a default value.

Example: Command `from-git`:
```
    ./distribute.py from-git \ 
        --user not-ubuntu \
        --nf-target /home/not-ubuntu/nf-install-dir \
        --ignite-discovery /shared/nfs/for/workers/discovery \
        --daemon \
        --purge
```

Example: command `from-local`:
```
    ./distribute.py from-local \ 
        --user ubuntu \
        --nf-source /home/ubuntu/local-nf-source \
        --nf-target /home/ubuntu/nf-install-dir \
        --ignite-discovery 192.168.0.1,192.168.0.2,192.168.0.3 \
        --daemon \
        --purge
```

Example: command `docker`
```
    ./distribute.py docker --hosts 192.168.0.1,192.168.0.2,192.168.0.3
```

# Note

The distribution and setup script execution require and assume `ssh` access to remote hosts.

The `setup-nextflow.sh` or `setup-nextflow.git.sh` script will require/install `Java` (version determined by variable in script), `unzip` and `make` in order to build nextflow from source. When using the `from-git` command mode `git` has to be present on the node as well and will not be installed as of now.  

