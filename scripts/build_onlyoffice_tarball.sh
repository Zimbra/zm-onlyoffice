#!/usr/bin/env bash
set -eo pipefail

# 1. Source release.env if present, allow CLI override
if [ -f "release.env" ]; then
  source release.env
fi

VERSION="${1:-${ONLYOFFICE_VERSION:-v7.2.2.56}}"
TARGET_OS="${2:-u14}"
ARCH="${3:-linux_64}"

OUT_TARBALL_NAME="zimbra-onlyoffice-${VERSION}.tar.gz"
WORKSPACE_DIST="$(pwd)/build/dist_tarball"
mkdir -p "${WORKSPACE_DIST}"

echo "=========================================================================="
echo " Starting OnlyOffice Source Compilation Job"
echo " Target Version : ${VERSION}"
echo " Tarball Name   : ${OUT_TARBALL_NAME}"
echo " Target OS      : ${TARGET_OS}"
echo "=========================================================================="

BUILD_TOOLS_DIR="${HOME}/build_tools"

# 2. Install prerequisites
sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git python3 python3-pip curl wget tar zip ca-certificates jq

# 3. Clone ONLYOFFICE upstream build_tools
if [ -d "${BUILD_TOOLS_DIR}" ]; then
  rm -rf "${BUILD_TOOLS_DIR}"
fi

echo "Cloning ONLYOFFICE/build_tools..."
git clone --depth 1 -b master https://github.com/ONLYOFFICE/build_tools.git "${BUILD_TOOLS_DIR}"

# 4. Patch build_tools to point DocumentServer to Zimbra fork
echo "Patching scripts/base.py to point to Zimbra/zm-onlyoffice fork..."
cd "${BUILD_TOOLS_DIR}"

if grep -q "github.com/ONLYOFFICE/DocumentServer.git" scripts/base.py; then
  sed -i 's|github.com/ONLYOFFICE/DocumentServer.git|github.com/Zimbra/zm-onlyoffice.git|g' scripts/base.py
  echo "Successfully pointed DocumentServer to Zimbra/zm-onlyoffice."
else
  echo "Notice: Verbatim upstream URL not found; proceeding with base.py."
fi

# 5. Run compilation with heartbeat logger (prevents CircleCI timeout on quiet stdout)
heartbeat() {
  while true; do
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] OnlyOffice compilation in progress..."
    sleep 300
  done
}
heartbeat &
HEARTBEAT_PID=$!
trap "kill -9 $HEARTBEAT_PID 2>/dev/null || true" EXIT

echo "Running automate.py for DocumentServer (branch: tags/${VERSION})..."
python3 ./automate.py server --branch="tags/${VERSION}"

kill -9 "${HEARTBEAT_PID}" 2>/dev/null || true

# 6. Verify build output & create tarball
OUTPUT_DIR="${BUILD_TOOLS_DIR}/out/${ARCH}/onlyoffice/documentserver"
if [ ! -d "${OUTPUT_DIR}" ]; then
  echo "ERROR: Compilation output directory not found at: ${OUTPUT_DIR}"
  exit 1
fi

echo "Packaging compiled output into ${OUT_TARBALL_NAME}..."
cd "${BUILD_TOOLS_DIR}/out/${ARCH}/onlyoffice"
tar -czvf "${WORKSPACE_DIST}/${OUT_TARBALL_NAME}" documentserver

cd "${WORKSPACE_DIST}"
sha256sum "${OUT_TARBALL_NAME}" > "${OUT_TARBALL_NAME}.sha256"

echo "=== Generated Tarball Artifacts ==="
ls -lh "${WORKSPACE_DIST}"

# 7. Upload tarball to OCI Object Storage
if [ -n "${OCI_PAR_URL:-}" ]; then
  DEST_PATH="${CIRCLE_PROJECT_REPONAME}/tarballs/${TARGET_OS}/${OUT_TARBALL_NAME}"
  echo "Uploading tarball to OCI Storage: ${DEST_PATH}..."
  curl -X PUT "${OCI_PAR_URL}${DEST_PATH}" -T "${WORKSPACE_DIST}/${OUT_TARBALL_NAME}"
  curl -X PUT "${OCI_PAR_URL}${DEST_PATH}.sha256" -T "${WORKSPACE_DIST}/${OUT_TARBALL_NAME}.sha256"
  echo "Upload complete."
else
  echo "Notice: OCI_PAR_URL is not set. Tarball retained in workspace/artifacts."
fi

echo "=========================================================================="
echo " OnlyOffice Tarball Build Completed Successfully!"
echo "=========================================================================="
