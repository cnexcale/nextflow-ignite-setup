# Nextflow

NF sources auf Master Node kopieren
- `git clone https://github.com/cnexcale/nextflow.git`
- Branch `nf-ignite_s3_workdir` nutzen: `git checkout nf-ignite_s3_workdir`

NF verteilen
- https://github.com/cnexcale/nextflow-ignite-setup
- `./distribute.py --help` für eine Übersicht
- `./distribute.py --daemon --purge -i <worker_node_ips__comma_separated>  dry-run ~/nf-current`
- Worker überprüfen: `ssh ubuntu@<worker_ip>` -> `pgrep -a java`

NF auf Master Node installieren
- hier enthalten: https://github.com/cnexcale/nextflow-ignite-setup
- `./setup-locally.sh <nf-directory>`

Scratch Verzeichnisse anlegen
- bibigrid-master hat im default kein Scratch in BI
- Worker ggf. auch nicht
- Verzeichnisse anlegen und soft linken (wenn z.B. auf `/mnt` etwas platz ist) 

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
- z.B. mit script `scripts/setup-docker.sh` (s.u.)


# Object Storage
Bucket für WorkDir anlegen
- z.B. `mc mb <project>/nf-work-25`


# Meta-Omics-Toolkit
Toolkit auf Master Node: `git clone` oder `scp`
- muss in einem Verzeichnis liegen, das genug Speicherplatz hat auf dem Master Node!
- z.B. scratch oder ephemeral

Toolkit Binaries verteilen (`meta-omics-toolkit/bin` Ordner)
- müssen auf jedem Node vorhanden sein
- siehe `scripts/copy-meta-omics-binaries.sh` Script
    - `copy-meta-omics-binaries.sh <path_to_meta_omics_bin_folder> <worker_node_ips__comma_separated>`

Anpassungen der `nextflow.config`
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

(optional) Parameterdatei kürzen (`example_params/fullPipeline.yml`)
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
- aus Verzeichnis des meta-omics-toolkits heraus ausführen (da dort teilweise relative Pfade verwendet werden)
```
<nextflow-folder>/nextflow run <meta-omics-toolkit_folder>/main.nf \
                                  -work-dir "s3://<work-dir-bucket>" \
                                  -profile slurm \
                                  -c <adjusted_config>/nextflow.config \
                                  -entry wPipeline \
                                  -params-file <adjusted_param_files>/fullPipeline.yml \
                                  -cluster.join ip:<list_of_ignite_workers__comma_separated>
```
