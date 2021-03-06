# Nextflow

NF sources auf Master Node kopieren
- `git clone https://github.com/cnexcale/nextflow.git`
- Branch `nf-ignite_s3_workdir` nutzen: `git checkout nf-ignite_s3_workdir`

NF verteilen
- https://github.com/cnexcale/nextflow-ignite-setup
- `./distribute.py --help` für eine Übersicht
- `./distribute.py --daemon --purge -i <worker_node_ips__comma_separated> live ~/nf-current`
- Worker überprüfen: `ssh ubuntu@<worker_ip>` -> `pgrep -a java`

NF auf Master Node installieren
- hier enthalten: https://github.com/cnexcale/nextflow-ignite-setup
- siehe  [setup-locally.sh \<nf-directory\>](../setup-locally.sh)

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
- z.B. mit script [setup-docker.sh](scripts/setup-docker.sh)


# Object Storage
Bucket für WorkDir anlegen
- z.B. `mc mb <project>/nf-work-25`


# Meta-Omics-Toolkit
Toolkit auf Master Node ziehen: `git clone` oder `scp`
- muss in einem Verzeichnis/Mount liegen, das genug Speicherplatz hat, da von hier später der Workflow gestartet wird
- z.B. scratch oder ephemeral

Toolkit Binaries
- (falls NFS vorhanden) Toolkit muss auf NFS liegen und der NF run muss von dort gestartet werden
  - nur dadurch wird sichergestellt, dass Worker Nodes die Binaries im `bin/` Order finden

- (falls kein NFS vorhanden) Toolkit Binaries auf Worker verteilen (`meta-omics-toolkit/bin` Ordner)
  - müssen auf jedem Node vorhanden sein
  - siehe [copy-meta-omics-binaries.sh](scripts/copy-meta-omics-binaries.sh)
    - kopiert `<path_to_meta_omics_bin_folder>` in `/home/ubuntu/meta-tools` auf alle Worker
    - `copy-meta-omics-binaries.sh <path_to_meta_omics_bin_folder> <worker_node_ips__comma_separated>`

Anpassungen der `nextflow.config`
- siehe [nextflow.config](configs/nextflow.config) für Beispiele
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
- aus Verzeichnis des meta-omics-toolkits heraus ausführen (da dort teilweise relative Pfade verwendet werden, z.B. ggf. für `tmp` oder `output`)
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
Mit den Anpassungen aus dem Branch `https://github.com/cnexcale/nextflow/tree/nf-ignite_s3_workdir` gibt es verschiedene neue Parameter für das Verhalten des Ignite Plugins. Alle Parameter müssen auf der Toplevel Ebene der `nextflow.config` unter der Sektion `cluster {}` festgelegt werden. Beispiele siehe [nextflow.config](configs/nextflow.config)

**useMasterAsCompute**
- Werte: `true` | `false`
- Default: `true`
- Wenn ~ auf `false` gesetzt wird, nimmt der Ignite Master Node (von welchem der Workflow gestartet) wird keine Jobs an

**localStorageRoot**
- Werte: Dateisystem Pfad
- Default: null
- Wenn ~ auf einen (absoluten) Pfad konfiguriert wird, wird dieser Pfad als Präfix für die Node-lokalen `workDir` oder `cache` Verzeichnisse verwendet. Überschreibt sämtliche Scratch/Temp Konfigurationen bzw. hängt diese an den konfigurierten Rootpfad an  