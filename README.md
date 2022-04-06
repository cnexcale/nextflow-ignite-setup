# nextflow-ignite-setup

Provides scripts to setup (compile + install) nextflow from source using slurms `sinfo` command for remote host discovery

# Usage

For best experience `distribute.py` provides a simple CLI interface with argument parsing and help/description texts. Use `./distribute.py --help` for an overview.
Except for the base `command` and `nf-source` all arguments come with a default value.

Example:
```
    ./distribute.py dry-run \ 
        ~/nf-fork \
        --user not-ubuntu \
        --nf-target /home/not-ubuntu/remote-nf-dir \
        --ignite-discovery /shared/nfs/for/workers/discovery \
        --daemon \
        --purge
```