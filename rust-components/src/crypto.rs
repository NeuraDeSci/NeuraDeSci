use sha2::{Sha256, Digest};
use rand::{Rng, thread_rng};
use hex;
use std::error::Error;

/// Hash a string using SHA-256 and return the hex representation
pub fn hash_sha256(data: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data.as_bytes());
    let result = hasher.finalize();
    hex::encode(result)
}

/// Generate a random key for encryption
pub fn generate_key() -> String {
    let key: [u8; 32] = thread_rng().gen();
    hex::encode(key)
}

/// Simple XOR-based encryption for demonstration
/// In a real application, use a proper encryption library like AES
pub fn encrypt(data: &str, key: &str) -> Result<String, Box<dyn Error>> {
    let key_bytes = hex::decode(key)?;
    let data_bytes = data.as_bytes();
    
    let mut encrypted = Vec::with_capacity(data_bytes.len());
    for (i, &byte) in data_bytes.iter().enumerate() {
        encrypted.push(byte ^ key_bytes[i % key_bytes.len()]);
    }
    
    Ok(hex::encode(encrypted))
}

/// Simple XOR-based decryption for demonstration
pub fn decrypt(encrypted_data: &str, key: &str) -> Result<String, Box<dyn Error>> {
    let key_bytes = hex::decode(key)?;
    let data_bytes = hex::decode(encrypted_data)?;
    
    let mut decrypted = Vec::with_capacity(data_bytes.len());
    for (i, &byte) in data_bytes.iter().enumerate() {
        decrypted.push(byte ^ key_bytes[i % key_bytes.len()]);
    }
    
    String::from_utf8(decrypted).map_err(|e| e.into())
}

/// Generate a key pair for asymmetric encryption
/// This is a placeholder and would be replaced with actual crypto in production
pub fn generate_keypair() -> (String, String) {
    let private_key = generate_key();
    let public_key = hash_sha256(&private_key)[..40].to_string();
    (private_key, public_key)
}

/// Sign data with a private key
/// This is a placeholder and would be replaced with actual crypto in production
pub fn sign_data(data: &str, private_key: &str) -> Result<String, Box<dyn Error>> {
    let message = format!("{}:{}", data, private_key);
    Ok(hash_sha256(&message))
}

/// Verify a signature against a public key
/// This is a placeholder and would be replaced with actual crypto in production
pub fn verify_signature(data: &str, signature: &str, public_key: &str) -> bool {
    // This is simplified for demonstration
    // In a real application, use proper signature verification
    let derived_public = &hash_sha256(signature)[..40];
    derived_public == public_key
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_sha256() {
        let result = hash_sha256("test data");
        assert_eq!(result.len(), 64);
    }

    #[test]
    fn test_encrypt_decrypt() {
        let data = "This is a test message for the NeuraDeSci platform";
        let key = generate_key();
        
        let encrypted = encrypt(data, &key).unwrap();
        let decrypted = decrypt(&encrypted, &key).unwrap();
        
        assert_eq!(data, decrypted);
    }

    #[test]
    fn test_keypair_generation() {
        let (private_key, public_key) = generate_keypair();
        assert_eq!(private_key.len(), 64);
        assert_eq!(public_key.len(), 40);
    }

    #[test]
    fn test_signing() {
        let data = "Research data to be signed";
        let (private_key, _) = generate_keypair();
        
        let signature = sign_data(data, &private_key).unwrap();
        assert_eq!(signature.len(), 64);
    }
} 