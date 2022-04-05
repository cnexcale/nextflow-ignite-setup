#!/usr/bin/env python3

import argparse
import sys
import subprocess


# Constants for the script

default_nf_target_dir = "/home/ubuntu/nf-ignite"
default_setup_script = "./setup-nextflow.sh"
default_user = "ubuntu"
default_daemon_flag = False
default_ignite_discovery_dir = "/vol/spool/nf-ignite-cluster"
default_purge_flag = False

ignite_purge_flag = "purge"
ignite_daemon_flag = "daemon"

distribute_script = "./distribute-nextflow.sh"


# Setup argparse arguments

parser = argparse.ArgumentParser(description="Helper script to setup nextflow from source on a range of remote hosts.\n")

parser.add_argument("nf_source",
                    metavar="nf-source",
                    help="Directory containing the nextflow repository folder. Do NOT specify the nextflow repository root"
                          + "directory/folder directly but its parent! The setup script will thank you.",
                    type=str)

parser.add_argument("--nf-target", "-t",
                    metavar="DIR",
                    help=f"Target directory (absolute path) on remote host where nextflow should be installed. Default: {default_nf_target_dir}",
                    type=str,
                    default=default_nf_target_dir)

parser.add_argument("--setup-script", "-s",
                    metavar="FILE",
                    help=f"Setup script to run on remote host.\n  Default: {default_setup_script}",
                    type=str,
                    default=default_setup_script)

parser.add_argument("--user", "-u",
                    help=f"Specify ssh/unix user for target host. Default: {default_user}",
                    type=str,
                    default=default_user)

parser.add_argument("--ignite-discovery", "-i",
                    metavar="NFS_DIR",
                    help=f"Specify directory on a shared NFS thats accessible on all nodes for node discovery of the ignite cluster. Default: {default_ignite_discovery_dir}",
                    type=str,
                    default=default_ignite_discovery_dir)

parser.add_argument("--daemon", "-d",
                    help="If specified a nextflow ignite daemon will be launched on remote host after setup",
                    action="store_true",
                    default=default_daemon_flag)

parser.add_argument("--purge", "-p",
                    help="If specified the existing nextflow installation on a remote host will be deleted before running the setup",
                    action="store_true",
                    default=default_purge_flag)

# Parse and validate commands

args = parser.parse_args()
print(args)

# TODO - validate script (file exists), nf-source (dir exists), nf-target (absolute path) and ignite discovery (dir exists)


# Generate command from arguments

daemon_param = ignite_daemon_flag if args.daemon else "no-daemon"
purge_param = ignite_purge_flag if args.purge else "no-purge"

cmd = [distribute_script, args.nf_source, args.nf_target, args.setup_script, args.user, daemon_param, args.ignite_discovery, purge_param]

print("Will execute:", " ".join(cmd))


# Finally execute and capture stdout (redirect stderr to stdout)

process = subprocess.Popen(cmd, shell=False, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
# print("setting up process stdout capture")
# proc_stdout, proc_stderr = process.communicate()
# print("listen for streamed stdout")

while True:
    out = process.stdout.readline()

    if not out and process.poll() is not None:
        break

    print(out.decode("utf8").strip())
    

