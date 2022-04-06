# nextflow-ignite-setup

Provides scripts to setup (compile + install) nextflow from source using slurms `sinfo` command for remote host discovery.

`setup-nextflow.sh` is used to prepare, compile and install nextflow on a host and conditionally start an ignite daemon on the host.

`distribute-nextflow.sh` will handle remote host resolution, possible cleanup prior to setup and executing the 

# Usage

For a more convenient usage `distribute.py` provides a simple CLI interface with argument parsing and help/description texts. Use `./distribute.py --help` for an overview.
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

This example uses the `dry-run` command and prints the parametrized bash script call that could be used directly for execution. When using `live` command the built script call will be executed. 