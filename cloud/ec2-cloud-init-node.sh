# ec2-cloud-init.txt is inserted here

mkdir -p ${FOMO_MOUNT_SHR} ${FOMO_JUICEFS_CACHE}
/usr/local/bin/juicefs mount -d --cache-dir ${FOMO_JUICEFS_CACHE} --writeback --cache-size 102400 \
      redis://:${FOMO_REDIS_PW}@${FOMO_HEAD_NODE}:6379 ${FOMO_MOUNT_SHR} # --max-uploads 100 --cache-partial-only
#chown {self.cfg.defuser} /mnt/share