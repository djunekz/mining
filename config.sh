# Konfigurasi proyek - ubah sesuai repo Anda
APP_NAME="TermuxMiner"
APP_AUTHOR="Djunekz"
REPO_URL="https://github.com/djunekz/mining"
APP_VERSION="$(cat "$ROOT/VERSION" 2>/dev/null || echo 0.0.0)"

# Data pengguna (akun, wallet) disimpan DI LUAR folder repo
# supaya "git pull" tidak menimpa data.
DATA_DIR="${MINING_HOME:-$HOME/.termuxminer}"

# Batas suhu baterai (derajat C) default; mining dihentikan jika terlewati
MAX_TEMP_DEFAULT=42

# Donasi bawaan xmrig ke pengembang xmrig (persen waktu mining). 0 = nonaktif.
# Ditulis eksplisit di sini supaya transparan; aplikasi ini sendiri TIDAK
# memiliki dev-fee atau wallet tersembunyi.
XMRIG_DONATE=1

# Tipe miner yang dikenali oleh file koin
MINER_TYPES="xmrig ccminer cpuminer none"
