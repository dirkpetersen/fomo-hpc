# FOMO HPC
Hybrid cloud implementation of Slurm and AWS for those in 'fear of missing out'



```
export AWS_PROFILE="default"
echo -e "\nexport AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)"
echo -e "export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)"
echo -e "export AWS_DEFAULT_REGION=$(aws configure get region)"
```
