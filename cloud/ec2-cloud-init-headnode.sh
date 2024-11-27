# ec2-cloud-init.txt is inserted here 

dnf install -y openldap-servers rsync

if [[ -d "/etc/redis6" ]]; then
  echo "Config redis"
  # requirepass xxxxxx
  # protected-mode no
  # #bind 127.0.0.1 -::1
fi

# Configure exports if directories exist
if [[ -d "/opt" ]]; then
  echo "Configuring exports..."    
  echo "/opt *(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
  # Apply exports
  sudo exportfs -ra
fi

systemctl enable nfs-server redis6 slapd
systemctl restart nfs-server redis6 slapd

if ! systemctl is-active --quiet redis6 && ! systemctl is-active --quiet redis; then
  echo "Redis is not running"
  exit 1
fi

juicefs format --storage s3 --bucket https://s3.${FOMO_AWS_REGION}.amazonaws.com/${FOMO_S3_BUCKET} \
    --access-key=${FOMO_AWS_ACCESS_KEY_ID} --secret-key=${FOMO_AWS_SECRET_ACCESS_KEY} \
    --storage-class ${FOMO_S3_STORAGE_CLASS} --compress lz4 \
    redis://:${FOMO_REDIS_PW}@${FOMO_HEAD_NODE}:6379/1 ${FOMO_JUICEID}
juicefs config -y --access-key=${FOMO_AWS_ACCESS_KEY_ID} --secret-key=${FOMO_AWS_SECRET_ACCESS_KEY} \
    --storage-class ${FOMO_S3_STORAGE_CLASS} --trash-days 0 redis://:${FOMO_REDIS_PW}@${FOMO_HEAD_NODE}:6379/1
mkdir -p ${FOMO_MOUNT_SHR}
juicefs mount -d --cache-dir ${FOMO_JUICEFS_CACHE} --writeback --cache-size 102400 \
      redis://:${FOMO_REDIS_PW}@${FOMO_HEAD_NODE}:6379/1 ${FOMO_MOUNT_SHR} # --max-uploads 100 --cache-partial-only
#chown {self.cfg.defuser} /mnt/share       
#juicefs destroy -y redis://localhost:6379 {juiceid}
#sed -i 's/--access-key=[^ ]*/--access-key=xxx /' {bscript}
#sed -i 's/--secret-key=[^ ]*/--secret-key=yyy /' {bscript}
#sed -i 's/^  juicefs config /#&/' {bscript}

