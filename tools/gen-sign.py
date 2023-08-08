from starkware.crypto.signature.signature import private_to_stark_key, pedersen_hash, sign, get_random_private_key

priv_key = get_random_private_key()
print("priv_key:", hex(priv_key))

pub_key = private_to_stark_key(priv_key)
print("pub_key", pub_key)

hashed = pedersen_hash(pedersen_hash(pedersen_hash(pedersen_hash(1, 0), 1), 1), 123)
sig = sign(hashed, priv_key)
print("sig", sig)