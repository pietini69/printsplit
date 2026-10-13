#!/usr/bin/env python3
import sys
import random

salt = "PRINTSPLIT_PRO_LIFETIME_SALT_2026_NIKO"
allowed = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

def calc_checksum(b1, b2):
    combined = f"{b1}{salt}{b2}"
    h = 5381
    for char in combined:
        h = ((h << 5) + h + ord(char)) & 0xFFFFFFFF
    return f"{h & 0xFFFF:04X}"

def generate_key(customer_email="customer"):
    b1 = ''.join(random.choice(allowed) for _ in range(4))
    b2 = ''.join(random.choice(allowed) for _ in range(4))
    b3 = calc_checksum(b1, b2)
    return f"PSPL-{b1}-{b2}-{b3}"

if __name__ == '__main__':
    email = sys.argv[1] if len(sys.argv) > 1 else "Direct Buyer"
    key = generate_key(email)
    print(f"==================================================")
    print(f" PrintSplit Pro Lifetime License Key")
    print(f" Customer: {email}")
    print(f" Key:      {key}")
    print(f"==================================================")
