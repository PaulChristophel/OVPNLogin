"""This provides the encoded hash of the private key."""
import hashlib
import os
import base64
import salt.utils.files


def get_b85_key():
    """
    Get the sha224 of the minion pem and base85 encode it.
    This provides a 70 character password that is very close to the
    72 character limit of bcrypt, is unique, and deterministic,
    and also fairly randomized (insofar as it uses a fair number
    of different chars).
    """
    # Set the path to the minion public key
    pub_key_path = os.path.join(__opts__["pki_dir"], "minion.pem")

    # Check if the file exists
    if not os.path.isfile(pub_key_path):
        return {"ovpn_error": "Minion key not found"}

    # Read the public key
    with salt.utils.files.fopen(pub_key_path, "rb") as kp_:
        sha224_hash = hashlib.sha224(kp_.read()).hexdigest()

    # Compute the SHA-224 hash
    encoded_sha224 = sha224_hash.encode("utf-8")

    # Compute the b85 encoding of the hash
    b85encoding = base64.b85encode(encoded_sha224).decode("utf-8")
    # Return the result as a dictionary
    return {
        "ovpn": b85encoding,
    }
