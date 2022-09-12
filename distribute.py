#!/usr/bin/env python3

import argparse
import sys
import subprocess
import os


# Constants for the script

ignite_purge_flag = "purge"
ignite_daemon_flag = "daemon"

distribute_script = "./distribute-nextflow.sh"

command_dry_run = "dry-run"
command_dist_from_local = "from-local"
command_dist_from_git = "from-git"

setup_script_git = "./setup-nextflow.git.sh"
setup_script_local = "./setup-nextflow.sh"

# Argument defaults

default_command = command_dry_run
default_nf_target_dir = "/home/ubuntu/nf-ignite"
default_setup_script = setup_script_local
default_user = "ubuntu"
default_daemon_flag = False
default_ignite_discovery_dir = "/vol/spool/nf-ignite-cluster"
default_purge_flag = False



# Setup argparse arguments

parser = argparse.ArgumentParser(description="Helper script to setup nextflow from source on a range of remote hosts.\n")

parser.add_argument("command",
                    help="Mode of action for this script. "
                          + f"{command_dist_from_local} := will setup nextflow on hosts based on local nextflow source files"
                          + f"{command_dist_from_git} := will setup nextflow on hosts based on current version from forked git repo"
                          + f"{command_dry_run} := will only print generated command for the distribute script",
                    type=str,
                    choices=[command_dist_from_local, command_dist_from_git, command_dry_run])

parser.add_argument("--nf-source", "-s",
                    metavar="DIR",
                    help=f"Required if command is '{command_dist_from_local}'! Directory containing the nextflow repository folder. "
                          + " Do NOT specify the nextflow repository root"
                          + f"directory/folder directly but its parent! The setup script will thank you. Default: {None}",
                    default=None,
                    required=len(sys.argv) > 1 and sys.argv[1] == command_dist_from_local,
                    type=str)

parser.add_argument("--nf-target", "-t",
                    metavar="DIR",
                    help=f"Target directory (absolute path) on remote host where nextflow should be installed. Default: {default_nf_target_dir}",
                    type=str,
                    default=default_nf_target_dir)

parser.add_argument("--setup-script",
                    metavar="FILE",
                    help=f"Setup script to run on remote host.\n  Default: {default_setup_script}",
                    type=str,
                    default=default_setup_script)

parser.add_argument("--user", "-u",
                    help=f"Specify ssh/unix user for target host. Default: {default_user}",
                    type=str,
                    default=default_user)

parser.add_argument("--ignite-discovery", "-i",
                    metavar="NFS_OR_IP",
                    help=f"Specify directory on a shared NFS thats accessible on all nodes "
                          + "OR a comma (,) separated list of IP4 addresses with or without ports  for node discovery of the ignite cluster. "
                          + f"Default: {default_ignite_discovery_dir}",
                    type=str,
                    default=default_ignite_discovery_dir)

parser.add_argument("--daemon", "-d",
                    help=f"A nextflow ignite daemon will be launched on remote host after setup. Default: {default_daemon_flag}",
                    action="store_true",
                    default=default_daemon_flag)

parser.add_argument("--purge", "-p",
                    help=f"The existing nextflow installation on a remote host will be deleted before running the setup. Default: {default_purge_flag}",
                    action="store_true",
                    default=default_purge_flag)


def get_setup_script(parsed_args):
    if parsed_args.setup_script != default_setup_script:
        return parsed_args.setup_script

    elif parsed_args.command == command_dist_from_local:
        return setup_script_local

    elif parsed_args.command == command_dist_from_git:
        return setup_script_git
    
    else:
        return None

def get_dist_source(parse_args):
    if parse_args.command == command_dist_from_local:
        return parse_args.nf_source

    elif parse_args.command == command_dist_from_git:
        return "FROM_GIT"
    
    else:
        return None

def validate_args(parsed_args):
    # TODO - validate script (file exists),
    #                 nf-source (dir exists)
    #                 nf-target (absolute path)
    #                 ignite discovery (dir exists or valid ip format)
    
    
    return (get_dist_source(parsed_args) is not None
            and get_setup_script(parsed_args) is not None)

def build_command(parsed_args):
    daemon_param = ignite_daemon_flag if parsed_args.daemon else "no-daemon"
    purge_param = ignite_purge_flag if parsed_args.purge else "no-purge"
    setup_script_param = get_setup_script(parsed_args)
    source_param = get_dist_source(parsed_args)

    return [distribute_script, source_param, parsed_args.nf_target, setup_script_param, parsed_args.user, purge_param, daemon_param, parsed_args.ignite_discovery ]  


# Parse and validate commands

args = parser.parse_args()

if not validate_args(args):
    sys.exit(1)


# Generate command from arguments

cmd = build_command(args)


# Check for dry-run

if args.command == command_dry_run:
    print(f"\nDry run specified, built the following command. You can directly use this command with {distribute_script}")
    print("\n  ", " ".join(cmd), "\n")
    sys.exit(0)


    
print("Command for live execution was provided. The following command would be executed:\n")
print ("  ", " ".join(cmd), "\n")
confirmation = input("Continue? (y/Y)")

if confirmation != "y" and confirmation != "Y":
    print("Distibute canceled")
    sys.exit(1)

# use redirected stderr for simplicity

process = subprocess.Popen(cmd, shell=False, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

while True:
    out = process.stdout.readline()

    if not out and process.poll() is not None:
        break

    print(out.decode("utf8").strip().strip("\t"))
    

