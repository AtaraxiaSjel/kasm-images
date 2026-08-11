#!/usr/bin/env bash
set -ex

CERT_DIR="${INST_SCRIPTS}/certificates"

apt-get update
apt-get install -y libnss3-tools p11-kit-modules

CERT_NAME="Russian Trusted Root CA"
CERT_FILE="${CERT_DIR}/russian_trusted_root_ca.pem"
SUB_CERT_NAME="Russian Trusted Sub CA"
SUB_CERT_FILE="${CERT_DIR}/russian_trusted_sub_ca.pem"

# Install the certs into the system cert store
cp "${CERT_FILE}" /usr/local/share/ca-certificates/russian-trusted-root-ca.crt
cp "${SUB_CERT_FILE}" /usr/local/share/ca-certificates/russian-trusted-sub-ca.crt
update-ca-certificates

# Create an empty cert9.db. This will be used by applications like Chrome
if [ ! -d $HOME/.pki/nssdb/ ]; then
    mkdir -p $HOME/.pki/nssdb/
    certutil -N -d sql:$HOME/.pki/nssdb/ --empty-password
    chown 1000:1000 $HOME/.pki/nssdb/
fi

# Update all cert9.db instances with the CAs
while IFS= read -r -d '' certDB; do
    certdir=$(dirname "${certDB}");
    echo "Updating $certdir"
    certutil -A -n "${CERT_NAME}" -t "TCu,," -i ${CERT_FILE} -d "sql:${certdir}"
    certutil -A -n "${SUB_CERT_NAME}" -t "TCu,," -i ${SUB_CERT_FILE} -d "sql:${certdir}"
done < <(find / -name "cert9.db" -print0 2>/dev/null)