# ec2-cloud-init.txt is inserted here 
if systemctl is-active --quiet redis6 || systemctl is-active --quiet redis; then
  curl -sSL https://d.juicefs.com/install | sh -
  mkdir -p ${FOMO_MOUNT_SHR}
  /usr/local/bin/juicefs mount -d --cache-dir ${FOMO_JUICEFS_CACHE} --writeback --cache-size 102400 \
       redis://:${FOMO_REDIS_PW}@${FOMO_HEAD_NODE}:6379 ${FOMO_MOUNT_SHR} # --max-uploads 100 --cache-partial-only
  #chown {self.cfg.defuser} /mnt/share       
fi