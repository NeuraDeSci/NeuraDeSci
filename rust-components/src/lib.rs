use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};

// Export all modules
pub mod crypto;
pub mod ipfs;
pub mod neural_data;
pub mod blockchain;
pub mod wasm_bridge;

// When the `wee_alloc` feature is enabled, use `wee_alloc` as the global allocator.
#[cfg(feature = "wee_alloc")]
#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;

// Initialize panic hook for better error messages when compiling to WebAssembly
#[wasm_bindgen(start)]
pub fn start() -> Result<(), JsValue> {
    #[cfg(feature = "console_error_panic_hook")]
    console_error_panic_hook::set_once();
    Ok(())
}

/// Represents a researcher's credentials in the NeuraDeSci ecosystem
#[wasm_bindgen]
#[derive(Serialize, Deserialize, Clone)]
pub struct ResearcherCredential {
    id: String,
    name: String,
    specialization: String,
    institution: String,
    publications: Vec<String>,
    #[serde(skip_serializing)]
    private_key: Option<String>,
}

#[wasm_bindgen]
impl ResearcherCredential {
    #[wasm_bindgen(constructor)]
    pub fn new(id: &str, name: &str, specialization: &str, institution: &str) -> ResearcherCredential {
        ResearcherCredential {
            id: id.to_string(),
            name: name.to_string(),
            specialization: specialization.to_string(),
            institution: institution.to_string(),
            publications: Vec::new(),
            private_key: None,
        }
    }

    pub fn add_publication(&mut self, publication_id: &str) {
        self.publications.push(publication_id.to_string());
    }

    pub fn to_json(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "{}".to_string())
    }

    #[wasm_bindgen(js_name = "fromJson")]
    pub fn from_json(json: &str) -> Result<ResearcherCredential, JsValue> {
        serde_json::from_str(json)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse JSON: {}", e)))
    }
}

/// Represents a neuroscience dataset in the NeuraDeSci ecosystem
#[wasm_bindgen]
#[derive(Serialize, Deserialize)]
pub struct NeuroscienceDataset {
    id: String,
    title: String,
    description: String,
    data_type: String,
    ipfs_hash: String,
    owner_id: String,
    timestamp: u64,
    license: String,
    keywords: Vec<String>,
    is_private: bool,
}

#[wasm_bindgen]
impl NeuroscienceDataset {
    #[wasm_bindgen(constructor)]
    pub fn new(
        id: &str,
        title: &str,
        description: &str,
        data_type: &str,
        ipfs_hash: &str,
        owner_id: &str,
        timestamp: u64,
        license: &str,
    ) -> NeuroscienceDataset {
        NeuroscienceDataset {
            id: id.to_string(),
            title: title.to_string(),
            description: description.to_string(),
            data_type: data_type.to_string(),
            ipfs_hash: ipfs_hash.to_string(),
            owner_id: owner_id.to_string(),
            timestamp,
            license: license.to_string(),
            keywords: Vec::new(),
            is_private: false,
        }
    }

    pub fn add_keyword(&mut self, keyword: &str) {
        self.keywords.push(keyword.to_string());
    }

    pub fn set_private(&mut self, is_private: bool) {
        self.is_private = is_private;
    }

    pub fn to_json(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "{}".to_string())
    }

    #[wasm_bindgen(js_name = "fromJson")]
    pub fn from_json(json: &str) -> Result<NeuroscienceDataset, JsValue> {
        serde_json::from_str(json)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse JSON: {}", e)))
    }
}

// Re-export key functions directly at the root level for easier access
// These are convenience wrappers around the module functions

/// Utility function to hash data using SHA-256
#[wasm_bindgen]
pub fn hash_data(data: &str) -> String {
    crypto::hash_sha256(data)
}

/// Utility function to encrypt data
#[wasm_bindgen]
pub fn encrypt_data(data: &str, key: &str) -> Result<String, JsValue> {
    crypto::encrypt(data, key).map_err(|e| JsValue::from_str(&e.to_string()))
}

/// Utility function to decrypt data
#[wasm_bindgen]
pub fn decrypt_data(encrypted_data: &str, key: &str) -> Result<String, JsValue> {
    crypto::decrypt(encrypted_data, key).map_err(|e| JsValue::from_str(&e.to_string()))
}

/// Utility function to upload data to IPFS (this is a stub in the WASM context)
#[wasm_bindgen]
pub fn upload_to_ipfs(_data: &str) -> String {
    "QmSampleHashIPFSStub12345".to_string()
}

/// Version information
#[wasm_bindgen]
pub fn version() -> String {
    let version = env!("CARGO_PKG_VERSION");
    let name = env!("CARGO_PKG_NAME");
    format!("{} v{}", name, version)
} 