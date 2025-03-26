use std::error::Error;
use serde::{Serialize, Deserialize};

/// Represents metadata for content stored on IPFS
#[derive(Debug, Serialize, Deserialize)]
pub struct IPFSMetadata {
    pub content_type: String,
    pub name: String,
    pub size: usize,
    pub created_at: u64,
    pub encrypted: bool,
    pub encryption_algorithm: Option<String>,
    pub tags: Vec<String>,
}

/// Represents a connection to an IPFS node
pub struct IPFSClient {
    api_url: String,
    gateway_url: String,
}

impl IPFSClient {
    pub fn new(api_url: &str, gateway_url: &str) -> Self {
        IPFSClient {
            api_url: api_url.to_string(),
            gateway_url: gateway_url.to_string(),
        }
    }

    /// Add content to IPFS
    /// 
    /// This is a mock implementation as actual IPFS operations would require
    /// async code and HTTP requests to an IPFS node
    pub fn add(&self, content: &[u8], metadata: &IPFSMetadata) -> Result<String, Box<dyn Error>> {
        // In a real implementation, this would send the content to an IPFS node
        // For demonstration, we'll just create a mock CID based on the content hash
        let content_hash = crate::crypto::hash_sha256(&String::from_utf8_lossy(content));
        let cid = format!("Qm{}", &content_hash[..38]);
        
        // In a real implementation, we would also add the metadata
        let _metadata_json = serde_json::to_string(metadata)?;
        
        Ok(cid)
    }

    /// Get content from IPFS by CID
    pub fn get(&self, cid: &str) -> Result<Vec<u8>, Box<dyn Error>> {
        // In a real implementation, this would fetch the content from an IPFS node
        // For demonstration, we'll return a mock response
        if !cid.starts_with("Qm") {
            return Err("Invalid CID format".into());
        }
        
        // Mock content based on CID
        let mock_content = format!("Mock content for CID: {}", cid);
        Ok(mock_content.into_bytes())
    }

    /// Get the HTTP URL for accessing content via an IPFS gateway
    pub fn get_gateway_url(&self, cid: &str) -> String {
        format!("{}/ipfs/{}", self.gateway_url, cid)
    }

    /// Pin content to ensure it remains available
    pub fn pin(&self, cid: &str) -> Result<(), Box<dyn Error>> {
        // In a real implementation, this would pin the content on an IPFS node
        if !cid.starts_with("Qm") {
            return Err("Invalid CID format".into());
        }
        
        // Just return success for the mock implementation
        Ok(())
    }

    /// Unpin content, allowing it to be garbage collected
    pub fn unpin(&self, cid: &str) -> Result<(), Box<dyn Error>> {
        // In a real implementation, this would unpin the content on an IPFS node
        if !cid.starts_with("Qm") {
            return Err("Invalid CID format".into());
        }
        
        // Just return success for the mock implementation
        Ok(())
    }
}

/// Create new metadata for content
pub fn create_metadata(
    content_type: &str,
    name: &str,
    size: usize,
    encrypted: bool,
    encryption_algorithm: Option<&str>,
    tags: Vec<String>,
) -> IPFSMetadata {
    IPFSMetadata {
        content_type: content_type.to_string(),
        name: name.to_string(),
        size,
        created_at: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs(),
        encrypted,
        encryption_algorithm: encryption_algorithm.map(|s| s.to_string()),
        tags,
    }
}

/// Utility function to convert a CID to a gateway URL
pub fn cid_to_url(cid: &str, gateway: &str) -> String {
    format!("{}/ipfs/{}", gateway, cid)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_metadata_creation() {
        let metadata = create_metadata(
            "application/json",
            "brain_scan_data.json",
            1024,
            true,
            Some("AES-256"),
            vec!["neuroscience".to_string(), "fMRI".to_string()],
        );
        
        assert_eq!(metadata.content_type, "application/json");
        assert_eq!(metadata.name, "brain_scan_data.json");
        assert_eq!(metadata.size, 1024);
        assert!(metadata.encrypted);
        assert_eq!(metadata.encryption_algorithm, Some("AES-256".to_string()));
        assert_eq!(metadata.tags.len(), 2);
    }

    #[test]
    fn test_ipfs_client() {
        let client = IPFSClient::new(
            "http://localhost:5001/api/v0",
            "https://ipfs.io",
        );
        
        let metadata = create_metadata(
            "text/plain",
            "test.txt",
            11,
            false,
            None,
            vec!["test".to_string()],
        );
        
        let cid = client.add("Hello World".as_bytes(), &metadata).unwrap();
        assert!(cid.starts_with("Qm"));
        
        let gateway_url = client.get_gateway_url(&cid);
        assert!(gateway_url.contains("/ipfs/"));
    }

    #[test]
    fn test_cid_to_url() {
        let url = cid_to_url("QmTest123", "https://gateway.ipfs.io");
        assert_eq!(url, "https://gateway.ipfs.io/ipfs/QmTest123");
    }
} 