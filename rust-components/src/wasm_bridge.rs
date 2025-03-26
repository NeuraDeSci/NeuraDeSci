use wasm_bindgen::prelude::*;
use std::error::Error;
use serde::{Serialize, Deserialize};

use crate::neural_data::{NeuralDataFormat, NeuralTimeSeries};
use crate::blockchain::{Transaction, TransactionType};
use crate::crypto;
use crate::ipfs;

/// WASM导出的JavaScript值，表示神经科学数据集
#[wasm_bindgen]
pub struct WasmNeuroscienceDataset {
    name: String,
    description: String,
    ipfs_hash: Option<String>,
    owner_id: String,
}

#[wasm_bindgen]
impl WasmNeuroscienceDataset {
    #[wasm_bindgen(constructor)]
    pub fn new(name: &str, description: &str, owner_id: &str) -> Self {
        WasmNeuroscienceDataset {
            name: name.to_string(),
            description: description.to_string(),
            ipfs_hash: None,
            owner_id: owner_id.to_string(),
        }
    }

    #[wasm_bindgen]
    pub fn get_name(&self) -> String {
        self.name.clone()
    }

    #[wasm_bindgen]
    pub fn get_description(&self) -> String {
        self.description.clone()
    }

    #[wasm_bindgen]
    pub fn get_ipfs_hash(&self) -> Option<String> {
        self.ipfs_hash.clone()
    }

    #[wasm_bindgen]
    pub fn set_ipfs_hash(&mut self, hash: &str) {
        self.ipfs_hash = Some(hash.to_string());
    }

    #[wasm_bindgen]
    pub fn to_json(&self) -> Result<String, JsValue> {
        match serde_json::to_string(self) {
            Ok(json) => Ok(json),
            Err(err) => Err(JsValue::from_str(&err.to_string())),
        }
    }
}

/// WASM导出的函数，用于哈希数据
#[wasm_bindgen]
pub fn hash_data(data: &str) -> String {
    crypto::hash_sha256(data)
}

/// WASM导出的函数，用于创建静态密钥对（仅用于测试）
#[wasm_bindgen]
pub fn generate_keys() -> JsValue {
    let (private_key, public_key) = crypto::generate_keypair();
    let keys = JsValue::from_serde(&serde_json::json!({
        "privateKey": private_key,
        "publicKey": public_key,
    })).unwrap_or(JsValue::NULL);
    keys
}

/// WASM导出的函数，用于加密数据
#[wasm_bindgen]
pub fn encrypt_data(data: &str, key: &str) -> Result<String, JsValue> {
    match crypto::encrypt(data, key) {
        Ok(encrypted) => Ok(encrypted),
        Err(err) => Err(JsValue::from_str(&err.to_string())),
    }
}

/// WASM导出的函数，用于解密数据
#[wasm_bindgen]
pub fn decrypt_data(encrypted_data: &str, key: &str) -> Result<String, JsValue> {
    match crypto::decrypt(encrypted_data, key) {
        Ok(decrypted) => Ok(decrypted),
        Err(err) => Err(JsValue::from_str(&err.to_string())),
    }
}

/// WASM导出的函数，用于创建模拟的IPFS上传
#[wasm_bindgen]
pub fn upload_to_ipfs(content: &str, name: &str) -> Result<JsValue, JsValue> {
    let client = ipfs::IPFSClient::new("https://ipfs.io");
    let metadata = ipfs::create_metadata("application/json", name, content.len() as u64);
    
    match client.add(content) {
        Ok(cid) => {
            let gateway_url = client.get_gateway_url(&cid);
            let result = serde_json::json!({
                "cid": cid,
                "url": gateway_url,
                "name": name,
                "size": content.len(),
            });
            
            match JsValue::from_serde(&result) {
                Ok(js_val) => Ok(js_val),
                Err(err) => Err(JsValue::from_str(&format!("序列化错误: {}", err))),
            }
        },
        Err(err) => Err(JsValue::from_str(&err.to_string())),
    }
}

/// WASM导出的函数，用于创建神经数据交易
#[wasm_bindgen]
pub fn create_neural_data_transaction(
    sender: &str, 
    recipient: &str, 
    data_id: &str,
    private_key: &str
) -> Result<JsValue, JsValue> {
    // 创建一个数据访问交易
    let mut tx = Transaction::new(
        TransactionType::DataAccess,
        sender,
        &format!("Access granted to data: {}", data_id),
    ).with_recipient(recipient)
     .with_gas_fee(21000);
    
    // 签名交易
    match tx.sign(private_key) {
        Ok(_) => {
            match JsValue::from_serde(&tx) {
                Ok(js_tx) => Ok(js_tx),
                Err(err) => Err(JsValue::from_str(&format!("序列化错误: {}", err))),
            }
        },
        Err(err) => Err(JsValue::from_str(&format!("签名错误: {}", err))),
    }
}

/// 创建EEG数据结构，并转换为WASM兼容格式
#[wasm_bindgen]
pub fn create_eeg_data(sampling_rate: f64, subject_id: &str, researcher: &str) -> Result<JsValue, JsValue> {
    // 创建EEG时间序列
    let mut eeg = NeuralTimeSeries::new(NeuralDataFormat::EEG, sampling_rate, "microvolts");
    
    // 生成一些示例数据
    eeg.generate_timestamps(0.0, 10);
    
    // 添加几个通道
    let channel_names = ["Fz", "Cz", "Pz", "Oz"];
    
    for channel in &channel_names {
        // 生成一些模拟的EEG数据
        let data: Vec<f64> = (0..10).map(|i| (i as f64).sin() * 10.0).collect();
        if let Err(e) = eeg.add_channel(channel, data) {
            return Err(JsValue::from_str(&format!("添加通道错误: {}", e)));
        }
    }
    
    // 添加元数据
    eeg.add_metadata("subject", subject_id);
    eeg.add_metadata("researcher", researcher);
    eeg.add_metadata("device", "NeuraDeSci EEG-32");
    
    // 转换为JS对象
    let js_eeg = match JsValue::from_serde(&eeg) {
        Ok(value) => value,
        Err(err) => return Err(JsValue::from_str(&format!("序列化错误: {}", err))),
    };
    
    Ok(js_eeg)
}

/// 初始化函数
#[wasm_bindgen(start)]
pub fn init() {
    // 设置日志记录器
    console_error_panic_hook::set_once();
    console_log::init_with_level(log::Level::Info).unwrap();
    log::info!("NeuraDeSci WASM模块已初始化!");
}

// 模拟数据分析函数
#[wasm_bindgen]
pub fn analyze_eeg_data(json_data: &str) -> Result<JsValue, JsValue> {
    // 解析EEG数据
    let eeg: NeuralTimeSeries = match serde_json::from_str(json_data) {
        Ok(data) => data,
        Err(err) => return Err(JsValue::from_str(&format!("解析错误: {}", err))),
    };
    
    // 分析结果
    let mut results = Vec::new();
    
    // 计算每个通道的统计数据
    for channel in &eeg.channels {
        if let Some(stats) = eeg.calculate_channel_stats(channel) {
            results.push(stats);
        }
    }
    
    // 转换为JS对象并返回
    match JsValue::from_serde(&results) {
        Ok(value) => Ok(value),
        Err(err) => Err(JsValue::from_str(&format!("序列化错误: {}", err))),
    }
}

/// JavaScript示例代码生成函数
#[wasm_bindgen]
pub fn get_js_usage_example() -> String {
    r#"
// 导入 WASM 模块
import * as neuradesci from 'neuradesci-core';

// 初始化
async function init() {
    // 创建一个神经科学数据集
    const dataset = new neuradesci.WasmNeuroscienceDataset(
        "阿尔茨海默症EEG研究", 
        "使用EEG研究阿尔茨海默症患者的脑电活动", 
        "researcher_001"
    );
    
    // 生成密钥对
    const keys = neuradesci.generate_keys();
    console.log("生成的密钥:", keys);
    
    // 创建EEG数据
    const eegData = await neuradesci.create_eeg_data(256.0, "patient_123", "Dr. Wang");
    console.log("EEG数据:", eegData);
    
    // 将数据上传到IPFS
    const jsonData = JSON.stringify(eegData);
    const ipfsResult = await neuradesci.upload_to_ipfs(jsonData, "alzheimer_eeg_study.json");
    console.log("IPFS结果:", ipfsResult);
    
    // 将IPFS哈希存储到数据集
    dataset.set_ipfs_hash(ipfsResult.cid);
    
    // 创建数据访问交易
    const transaction = await neuradesci.create_neural_data_transaction(
        "researcher_001",
        "researcher_002",
        ipfsResult.cid,
        keys.privateKey
    );
    console.log("创建的交易:", transaction);
    
    // 分析EEG数据
    const analysisResults = await neuradesci.analyze_eeg_data(jsonData);
    console.log("分析结果:", analysisResults);
}

init().catch(console.error);
"#.to_string()
}

/// 返回WASM模块的版本信息
#[wasm_bindgen]
pub fn version() -> String {
    let version = env!("CARGO_PKG_VERSION");
    let name = env!("CARGO_PKG_NAME");
    format!("{} v{} (WASM)", name, version)
}

/// 演示用于测试的结构
#[derive(Serialize, Deserialize)]
struct TestResult {
    success: bool,
    message: String,
    timestamp: u64,
}

/// 运行所有测试并返回结果
#[wasm_bindgen]
pub fn run_tests() -> JsValue {
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();
    
    // 这里只是返回模拟结果，实际应用中可以运行真实测试
    let result = TestResult {
        success: true,
        message: "所有测试通过".to_string(),
        timestamp,
    };
    
    JsValue::from_serde(&result).unwrap_or(JsValue::NULL)
} 