# FOMO HPC

**Hybrid cloud implementation of Slurm and AWS for those in 'fear of missing out'.**

Hybrid cloud HPC have been on people's mind for a long time. Here is how you configure this pilot 

- check out this repo and cd to fomo-hpc 
- make sure you are authenticated to AWS
- install boto3 for the local python3

```
/usr/bin/python3 -m pip install --upgrade boto3
```

configure your environment with ./config.sh

```
./config.sh

*** Reading config from /home/....../fomo-hpc/.env ...

# instance type of the FOMO head node
Enter or edit FOMO_EC2TYPE: t4g.micro

# By default the head node runs Amazon Linux
Enter or edit FOMO_AMINAME_HEADNODE: al202*-ami-*

# By default all compute nodes run Rocky 9
Enter or edit FOMO_AMINAME_NODE: Rocky-9-EC2-Base*
.....
```

Check if someone else is already running jobs in this account 

```
dp@node1:~/fomo-hpc$ bin/csqueue
JOBID                NAME         USER         STATE TIME       CPUS   MEM (GB) NODELIST
-------------------------------------------------------------------------------------
```



```
aws configure export-credentials --format env
```



