# ec2-cloud-init.txt is inserted here

dnf install -y g++ make autoconf automake patch
dnf install -y epel-release
/usr/bin/crb enable
dnf install -y Lmod

# mount /arc/software via nfs
mkdir -p ${FOMO_MOUNT_SOFTWARE}
mount -t nfs ${FOMO_HEAD_NODE}:${FOMO_MOUNT_SOFTWARE} ${FOMO_MOUNT_SOFTWARE}

mkdir -p ${FOMO_MOUNT_SHR} ${FOMO_JUICEFS_CACHE}
REDIS_PASSWORD=${FOMO_REDIS_PW} /usr/local/bin/juicefs mount -d --cache-dir ${FOMO_JUICEFS_CACHE} --writeback --cache-size 102400 \
      redis://${FOMO_HEAD_NODE}:6379/1 ${FOMO_MOUNT_SHARED} # --max-uploads 100 --cache-partial-only
#chown {self.cfg.defuser} /mnt/share