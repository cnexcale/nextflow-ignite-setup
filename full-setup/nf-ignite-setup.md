# Nextflow

## NF sources auf Master Node kopieren
- `git clone https://github.com/cnexcale/nextflow.git`
- Branch `nf-ignite_s3_workdir` nutzen: `git checkout nf-ignite_s3_workdir`


## NF auf die Hosts verteilen
- https://github.com/cnexcale/nextflow-ignite-setup
- `./distribute.py --help` für eine Übersicht
Hier gibt es grundlegend zwei Optionen: eine lokale Version auf den Host kopieren und die aktuellen Branches der Nextflow und Ignite Forks ziehen.
Die Variante über git ist aktuell die empfohlene.

Für git:
- `./distribute.py from-git --daemon --purge -i <worker_node_ips__comma_separated>`

Für lokale source files:
- `./distribute.py from-local <nf_source_files> --daemon --purge -i <worker_node_ips__comma_separated>`

Danach Worker überprüfen: `ssh ubuntu@<worker_ip>` -> `pgrep -a java`
- wenn _genau ein_ Process `/usr/bin/java` mit laaaanger Parameter Liste und der `nextflow.cli.Launcher` main class am Ende läuft, hat das Setup auf dem Node sehr wahrscheinlich geklappt


## NF auf Master Node installieren
Setup Script für die lokale Installation auf dem Ignite Master befindet sich auch in diesem Repo, siehe [setup-locally.sh](../setup-locally.sh)

Auch hier gibt es die Unterscheidung zwischen lokaler Installation oder der git-basierten.

Für git:
- `setup-locally.sh from-git <target_dir>`
- führt [setup-nextflow.git.sh](../setup-nextflow.git.sh) aus, basierend auf `<target_dir>`
- `<target_dir>` ist optional, default: `$HOME/nf-current`

Für lokale source files:
- `setup-locally.sh from-local <nf_source_files>`
- führt [setup-nextflow.sh](../setup-nextflow.sh) aus und nutzt `<nf_source_files>` als Basis
- `<target_dir>` ist optional, default: `$HOME/nf-current`


## Scratch Verzeichnisse anlegen
Bibigrid Master Nodes haben im default kein Scratch am Standort Bielefeld
- Worker ggf. auch nicht, individuell zu prüfen; ggf. unter `/mnt/scratch`
Daher: Verzeichnisse anlegen und soft linken auf Mounts/Verzeichnisse mit mehr Platz (z.B. ephemeral mounts unter `/mnt/scratch`) 

```
sudo mkdir /vol
sudo chown ubuntu /vol
sudo mkdir /mnt/scratch
sudo chown ubuntu /mnt/scratch
cd /mnt/scratch && umask 000
ln -s /mnt/scratch /vol/scratch
```


# Docker
Für Meta-Omics-Toolkit muss Docker auf Nodes installiert sein
- z.B. mit script [setup-docker.sh](../helper/setup-docker.sh)



# Object Storage
Bucket für WorkDir anlegen
- z.B. `mc mb <project>/nf-work-25`



# Meta-Omics-Toolkit

## Toolkit auf Master Node ziehen: `git clone` oder `scp`
Muss in einem Verzeichnis/Mount liegen, das genug Speicherplatz hat, da von hier später der Workflow gestartet wird
- z.B. scratch oder ephemeral


## Toolkit Binaries verteilen
Falls ein NFS vorhanden:
- Toolkit muss auf NFS liegen und der NF run muss von dort gestartet werden
- nur dadurch wird sichergestellt, dass Worker Nodes die Binaries im `bin/` Order finden

Falls kein NFS vorhanden:
- Toolkit Binaries (`meta-omics-toolkit/bin`) auf Worker verteilen 
- müssen auf jedem Node vorhanden sein
- Helper Script siehe [copy-meta-omics-binaries.sh](../helper/copy-meta-omics-binaries.sh)
  - kopiert `<path_to_meta_omics_bin_folder>` in `/home/ubuntu/meta-tools` auf alle Worker
  - Beispiel: `copy-meta-omics-binaries.sh <path_to_meta_omics_bin_folder> <worker_node_ips__comma_separated>`


## Anpassungen der `nextflow.config`
Für ein Beispiel siehe [nextflow.config](configs/nextflow.config)

TODOs:
- Object Storage konfigurieren: `aws {}` Sektion auf top level hinzufügen
- Executor setzen: `profiles { slurm { process { executor = 'ignite' } } }`
- Binaries Ordner des Toolkits muss in jeden Container gemounted werden und dieser muss zur `PATH` Variable vorhanden sein
  - dafür z.B. `profiles { slurm { docker {} } }` anpassen
  - ```
    docker {
      fixOwnership = true
      enabled = true
      runOptions = "-v /home/ubuntu/meta-tools:/meta-tools"
    }

    env {
      PATH = "/meta-tools:$PATH"
    }
    ```

## (optional) Parameterdatei kürzen (`example_params/fullPipeline.yml`)
- siehe [fullPipeline.yml](configs/fullPipeline.yml)
- unter `steps` alle Schritte nach `binning` rausnehmen (`binning` aber behalten)
- `scratch: /vol/scratch` kontrolliert
- input definition angepasst: SRA IDs aus S3 buckets
  - ```
    input:
      SRA:
        S3:
          path: test_data/SRA/samples.tsv 
          bucket: "s3://ftp.era.ebi.ac.uk" 
          prefix: "/vol1/fastq/"
          watch: false
    ```


# Start des Toolkits
Wie Nextflow mit einem Ignite Master als Executor gestartet wird, hängt etwas von der Pipeline und den Anforderungen ab.
Unbedingt notwendig ist der `-cluster.join ip:<list_of_ignite_workers__comma_separated>` Parameter, da sich nur damit der Ignite Master in den Cluster einklinken kann.
Auch der `-profile` Parameter muss so konfiguriert sein, dass in dem Profil der Executor auf Ignite gesetzt ist (`process { executor = 'ignite' }`). Die Ausführung mit den gepatchten Nextflow/Ignit Versionen erlaubt zudem ein working directory im ObjectStorage (`-work-dir "s3://<bucket>"`)

Ggf. kann es notwendig sein, Nextflow aus dem Verzeichnis des meta-omics-toolkits heraus ausführen (da dort teilweise relative Pfade verwendet werden, z.B. ggf. für `tmp` oder `output`), v.a. muss dann darauf geachtet werden, dass dort genug Speicher vorhanden ist für evtl finale Ergebnisse des Workflows.

Beispiel:
```
<nextflow-folder>/nextflow run <meta-omics-toolkit_folder>/main.nf \
                                  -work-dir "s3://<work-dir-bucket>" \
                                  -profile slurm \
                                  -c <adjusted_config>/nextflow.config \
                                  -entry wPipeline \
                                  -params-file <adjusted_param_files>/fullPipeline.yml \
                                  -cluster.join ip:<list_of_ignite_workers__comma_separated>
```

# Konfigurationen
Mit den Anpassungen aus dem Branch `https://github.com/cnexcale/nextflow/tree/nf-ignite_s3_workdir` oder der Installation über `distribute.py from-git [...]` gibt es verschiedene neue Parameter für das Verhalten des Ignite Plugins. Alle Parameter müssen auf der Toplevel Ebene der `nextflow.config` unter der Sektion `cluster {}` festgelegt werden. Beispiele siehe [nextflow.config](configs/nextflow.config)

**useMasterAsCompute**
- Werte: `true` | `false`
- Default: `true`
- Wenn ~ auf `false` gesetzt wird, nimmt der Ignite Master Node (von welchem der Workflow gestartet) wird keine Jobs an

**localStorageRoot**
- Werte: Dateisystem Pfad
- Default: null
- Wenn ~ auf einen (absoluten) Pfad konfiguriert wird, wird dieser Pfad als Präfix für die Node-lokalen `workDir` oder `cache` Verzeichnisse verwendet. Überschreibt sämtliche Scratch/Temp Konfigurationen bzw. hängt diese an den konfigurierten Rootpfad an  