#! /bin/bash
format_largest_unused_block_devices() {
  # format the largest unused block device(s) and mount it to /opt or /mnt/scratch
  # if there are multiple unused devices of the same size and their combined size 
  # is larger than the largest unused single block device, they will be combined into 
  # a single RAID0 device and be mounted instead of the largest device
  #
  # Get all unformatted block devices with their sizes
  local devices=$(lsblk --json -n -b -o NAME,SIZE,FSTYPE,TYPE | jq -r '.blockdevices[] | select(.children == null and .type=="disk" and .fstype == null and (.name | tostring | startswith("loop") | not) ) | {name, size}')
  # Check if there are any devices to process
  if [[ -z "$devices" ]]; then
    echo "No unformatted block devices found."
    return
  fi
  # Group by size and sum the total size for each group, also count the number of devices in each group
  local grouped_sizes=$(echo "$devices" | jq -s 'group_by(.size) | map({size: .[0].size, total: (.[0].size * length), count: length, devices: map(.name)})')
  # Find the configuration with the largest total size
  local best_config=$(echo "$grouped_sizes" | jq 'max_by(.total)')
  # Check if best_config is empty or null
  if [[ -z "$best_config" || "$best_config" == "null" ]]; then
    echo "No suitable block devices found."
    return
  fi
  # Extract the count value
  local count=$(echo "$best_config" | jq '.count')
  # Check if the best configuration is a single device or multiple devices
  if [[ "$count" -eq 1 ]]; then
    # Single largest device
    local largest_device=$(echo "$best_config" | jq -r '.devices[0]')
    echo "/dev/$largest_device"
    mkfs -t xfs "/dev/$largest_device"
    mkdir -p $1
    mount "/dev/$largest_device" $1
    echo "/dev/$largest_device $1 auto defaults 0 0" >> /etc/fstab
    sleep 5
  elif [[ "$count" -gt 1 ]]; then
    # Multiple devices of the same size
    local devices_list=$(echo "$best_config" | jq -r '.devices[]' | sed 's/^/\/dev\//')
    echo "Devices with the largest combined size: $devices_list"
    mdadm --create /dev/md0 --level=0 --raid-devices=$count $devices_list
    mkfs -t xfs /dev/md0
    mkdir -p $1
    mount /dev/md0 $1
    echo "/dev/md0 $1 auto defaults 0 0" >> /etc/fstab
    sleep 5
  else
    echo "No uniquely largest block device found."
  fi
}
###################### 
START_TIME=$(date +%s)
PKGM=''
if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  PKGM=apt
  ${PKGM} update -y
elif command -v dnf >/dev/null 2>&1; then
  PKGM=dnf
else 
  echo "Unsupported package manager"
  exit 1
fi
${PKGM} install -y mdadm jq git
# format EBS volume 
format_largest_unused_block_devices /opt
# install common packages 
${PKGM} install -y redis6 nfs-utils openldap-clients fuse3 unzip iotop iftop mc
# activating multi-user access for fuse
sed -i 's/^# user_allow_other/user_allow_other/' /etc/fuse.conf
curl -sSL https://d.juicefs.com/install | sh -

### end of ec2-cloud-init.txt
