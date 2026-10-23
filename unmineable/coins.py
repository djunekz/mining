from __future__ import annotations

import re

QUICK = ("BTC", "DOGE", "TRX", "LTC", "ETH", "SHIB", "SOL", "XRP", "BNB", "USDT", "ADA")

BASE58 = "[1-9A-HJ-NP-Za-km-z]"
EVM = r"^0x[0-9a-fA-F]{40}$"

CATALOG = {
    "BTC": ("Bitcoin", rf"^(bc1[a-z0-9]{{25,87}}|[13]{BASE58}{{25,34}})$", "bc1... / 1... / 3..."),
    "DOGE": ("Dogecoin", rf"^D{BASE58}{{33}}$", "diawali D, 34 karakter"),
    "LTC": ("Litecoin", rf"^(ltc1[a-z0-9]{{20,90}}|[LM3]{BASE58}{{26,33}})$", "ltc1... / L... / M..."),
    "TRX": ("TRON", rf"^T{BASE58}{{33}}$", "diawali T, 34 karakter"),
    "ETH": ("Ethereum", EVM, "0x + 40 heksadesimal"),
    "SHIB": ("Shiba Inu", EVM, "0x + 40 heksadesimal (ERC20)"),
    "BNB": ("BNB", EVM, "0x + 40 heksadesimal (BEP20)"),
    "MATIC": ("Polygon", EVM, "0x + 40 heksadesimal"),
    "LINK": ("Chainlink", EVM, "0x + 40 heksadesimal"),
    "UNI": ("Uniswap", EVM, "0x + 40 heksadesimal"),
    "SOL": ("Solana", rf"^{BASE58}{{32,44}}$", "base58, 32-44 karakter"),
    "XRP": ("XRP", rf"^r{BASE58}{{24,34}}$", "diawali r"),
    "ADA": ("Cardano", r"^addr1[a-z0-9]{40,120}$", "addr1..."),
    "BCH": ("Bitcoin Cash", rf"^((bitcoincash:)?[qp][a-z0-9]{{41}}|[13]{BASE58}{{25,34}})$", "bitcoincash:q... / 1..."),
    "DASH": ("Dash", rf"^X{BASE58}{{33}}$", "diawali X"),
    "ZEC": ("Zcash", rf"^t1{BASE58}{{33}}$", "transparent t1..."),
    "XLM": ("Stellar", r"^G[A-Z2-7]{55}$", "diawali G, 56 karakter"),
    "USDT": ("Tether", rf"^(0x[0-9a-fA-F]{{40}}|T{BASE58}{{33}})$", "0x... (ERC20/BEP20) atau T... (TRC20)"),
}


def normalize(coin):
    return re.sub(r"[^A-Z0-9:_-]", "", str(coin).upper())


def base(coin):
    return normalize(coin).split(":")[0]


def name(coin):
    entry = CATALOG.get(base(coin))
    return entry[0] if entry else base(coin) or "-"


def hint(coin):
    entry = CATALOG.get(base(coin))
    if entry:
        return f"{entry[0]}: alamat {entry[2]}. Cek jaringan di unmineable.com/coins"
    return "Koin tidak ada di katalog lokal. Pastikan alamat valid di unmineable.com/coins"


def validate(coin, address):
    address = str(address).strip()
    if not address:
        return False, "Alamat tidak boleh kosong"
    if re.search(r"\s", address):
        return False, "Alamat tidak boleh mengandung spasi"
    entry = CATALOG.get(base(coin))
    if entry:
        if re.match(entry[1], address):
            return True, "Format alamat valid"
        return False, f"Bukan alamat {entry[0]} yang valid. Contoh: {entry[2]}"
    if len(address) < 20:
        return False, "Alamat terlalu pendek"
    return None, "Koin di luar katalog lokal, format alamat tidak bisa diperiksa"
