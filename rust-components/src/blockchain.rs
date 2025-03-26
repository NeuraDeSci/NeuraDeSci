use serde::{Serialize, Deserialize};
use std::error::Error;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::crypto;

/// 区块链中的交易类型
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TransactionType {
    DataSubmission,
    DataAccess,
    CredentialVerification,
    TokenTransfer,
    SmartContractInteraction,
    Custom(String),
}

/// 区块链交易
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub id: String,
    pub transaction_type: TransactionType,
    pub sender: String,
    pub recipient: Option<String>,
    pub timestamp: u64,
    pub data: String,
    pub signature: Option<String>,
    pub gas_fee: Option<u64>,
    pub status: TransactionStatus,
}

/// 交易状态
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum TransactionStatus {
    Pending,
    Confirmed,
    Failed,
    Rejected,
}

impl Transaction {
    /// 创建一个新交易
    pub fn new(
        transaction_type: TransactionType,
        sender: &str,
        data: &str,
    ) -> Self {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        let id = crypto::hash_sha256(&format!("{}{}{}", sender, timestamp, data));
        
        Transaction {
            id,
            transaction_type,
            sender: sender.to_string(),
            recipient: None,
            timestamp,
            data: data.to_string(),
            signature: None,
            gas_fee: None,
            status: TransactionStatus::Pending,
        }
    }
    
    /// 设置交易接收方
    pub fn with_recipient(mut self, recipient: &str) -> Self {
        self.recipient = Some(recipient.to_string());
        self
    }
    
    /// 设置交易手续费
    pub fn with_gas_fee(mut self, gas_fee: u64) -> Self {
        self.gas_fee = Some(gas_fee);
        self
    }
    
    /// 对交易进行签名
    pub fn sign(&mut self, private_key: &str) -> Result<(), Box<dyn Error>> {
        let message = self.to_signing_string();
        let signature = crypto::sign_data(&message, private_key)?;
        self.signature = Some(signature);
        Ok(())
    }
    
    /// 验证交易签名
    pub fn verify_signature(&self, public_key: &str) -> bool {
        if let Some(ref signature) = self.signature {
            let message = self.to_signing_string();
            crypto::verify_signature(&message, signature, public_key)
        } else {
            false
        }
    }
    
    /// 生成待签名的字符串
    fn to_signing_string(&self) -> String {
        format!(
            "{}:{}:{}:{}:{}",
            self.id,
            self.sender,
            self.recipient.clone().unwrap_or_default(),
            self.timestamp,
            self.data
        )
    }
    
    /// 序列化为JSON
    pub fn to_json(&self) -> Result<String, Box<dyn Error>> {
        let json = serde_json::to_string(self)?;
        Ok(json)
    }
    
    /// 从JSON反序列化
    pub fn from_json(json: &str) -> Result<Self, Box<dyn Error>> {
        let transaction: Transaction = serde_json::from_str(json)?;
        Ok(transaction)
    }
}

/// 区块结构
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Block {
    pub index: u64,
    pub timestamp: u64,
    pub transactions: Vec<Transaction>,
    pub previous_hash: String,
    pub hash: String,
    pub nonce: u64,
    pub difficulty: u8,
}

impl Block {
    /// 创建一个新区块
    pub fn new(index: u64, previous_hash: &str, transactions: Vec<Transaction>, difficulty: u8) -> Self {
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        let mut block = Block {
            index,
            timestamp,
            transactions,
            previous_hash: previous_hash.to_string(),
            hash: String::new(),
            nonce: 0,
            difficulty,
        };
        
        block.hash = block.calculate_hash();
        block
    }
    
    /// 计算区块的哈希值
    pub fn calculate_hash(&self) -> String {
        let mut tx_data = String::new();
        for tx in &self.transactions {
            tx_data.push_str(&tx.id);
        }
        
        crypto::hash_sha256(&format!(
            "{}{}{}{}{}",
            self.index,
            self.previous_hash,
            self.timestamp,
            tx_data,
            self.nonce
        ))
    }
    
    /// 挖掘区块以满足难度要求
    pub fn mine(&mut self) {
        let target_prefix = "0".repeat(self.difficulty as usize);
        
        while !self.hash.starts_with(&target_prefix) {
            self.nonce += 1;
            self.hash = self.calculate_hash();
        }
    }
    
    /// 验证区块是否有效
    pub fn is_valid(&self) -> bool {
        let target_prefix = "0".repeat(self.difficulty as usize);
        let calculated_hash = self.calculate_hash();
        
        calculated_hash == self.hash && self.hash.starts_with(&target_prefix)
    }
    
    /// 序列化为JSON
    pub fn to_json(&self) -> Result<String, Box<dyn Error>> {
        let json = serde_json::to_string(self)?;
        Ok(json)
    }
    
    /// 从JSON反序列化
    pub fn from_json(json: &str) -> Result<Self, Box<dyn Error>> {
        let block: Block = serde_json::from_str(json)?;
        Ok(block)
    }
}

/// 简单的区块链实现
#[derive(Debug, Serialize, Deserialize)]
pub struct Blockchain {
    pub chain: Vec<Block>,
    pub pending_transactions: Vec<Transaction>,
    pub difficulty: u8,
    pub mining_reward: u64,
}

impl Blockchain {
    /// 创建一个新的区块链，并初始化创世区块
    pub fn new(difficulty: u8, mining_reward: u64) -> Self {
        let mut blockchain = Blockchain {
            chain: Vec::new(),
            pending_transactions: Vec::new(),
            difficulty,
            mining_reward,
        };
        
        // 创建创世区块
        blockchain.create_genesis_block();
        blockchain
    }
    
    /// 创建创世区块
    fn create_genesis_block(&mut self) {
        let genesis_block = Block::new(0, "0", Vec::new(), self.difficulty);
        self.chain.push(genesis_block);
    }
    
    /// 获取最新区块
    pub fn get_latest_block(&self) -> Option<&Block> {
        self.chain.last()
    }
    
    /// 添加一个待处理交易
    pub fn add_transaction(&mut self, transaction: Transaction) -> Result<(), Box<dyn Error>> {
        // 此处可以添加更多验证逻辑
        if transaction.signature.is_none() {
            return Err("交易缺少签名".into());
        }
        
        self.pending_transactions.push(transaction);
        Ok(())
    }
    
    /// 挖掘待处理交易并创建新区块
    pub fn mine_pending_transactions(&mut self, miner_address: &str) -> Result<Block, Box<dyn Error>> {
        if self.pending_transactions.is_empty() {
            return Err("没有待处理的交易可挖掘".into());
        }
        
        // 添加奖励交易
        let reward_tx = Transaction::new(
            TransactionType::TokenTransfer,
            "System",
            &format!("Reward: {}", self.mining_reward),
        ).with_recipient(miner_address);
        
        let mut transactions_to_mine = self.pending_transactions.clone();
        transactions_to_mine.push(reward_tx);
        
        // 获取最新区块的索引和哈希
        let latest_block = self.get_latest_block().ok_or("区块链为空")?;
        let new_index = latest_block.index + 1;
        let previous_hash = latest_block.hash.clone();
        
        // 创建新区块并挖掘
        let mut new_block = Block::new(new_index, &previous_hash, transactions_to_mine, self.difficulty);
        new_block.mine();
        
        // 验证并添加区块
        if self.is_valid_new_block(&new_block, latest_block) {
            self.chain.push(new_block.clone());
            self.pending_transactions = Vec::new(); // 清空待处理交易
            Ok(new_block)
        } else {
            Err("无效的区块".into())
        }
    }
    
    /// 验证新区块是否有效
    fn is_valid_new_block(&self, new_block: &Block, previous_block: &Block) -> bool {
        if new_block.index != previous_block.index + 1 {
            return false;
        }
        
        if new_block.previous_hash != previous_block.hash {
            return false;
        }
        
        if !new_block.is_valid() {
            return false;
        }
        
        true
    }
    
    /// 验证整个区块链是否有效
    pub fn is_chain_valid(&self) -> bool {
        if self.chain.is_empty() {
            return false;
        }
        
        for i in 1..self.chain.len() {
            let current_block = &self.chain[i];
            let previous_block = &self.chain[i - 1];
            
            if !self.is_valid_new_block(current_block, previous_block) {
                return false;
            }
        }
        
        true
    }
    
    /// 根据交易ID查找交易
    pub fn find_transaction(&self, transaction_id: &str) -> Option<&Transaction> {
        // 在待处理交易中查找
        for tx in &self.pending_transactions {
            if tx.id == transaction_id {
                return Some(tx);
            }
        }
        
        // 在已确认的区块中查找
        for block in &self.chain {
            for tx in &block.transactions {
                if tx.id == transaction_id {
                    return Some(tx);
                }
            }
        }
        
        None
    }
    
    /// 序列化为JSON
    pub fn to_json(&self) -> Result<String, Box<dyn Error>> {
        let json = serde_json::to_string(self)?;
        Ok(json)
    }
    
    /// 从JSON反序列化
    pub fn from_json(json: &str) -> Result<Self, Box<dyn Error>> {
        let blockchain: Blockchain = serde_json::from_str(json)?;
        Ok(blockchain)
    }
}

/// 模拟以太坊交互
pub struct EthereumConnector {
    pub endpoint: String,
    pub chain_id: u64,
}

impl EthereumConnector {
    pub fn new(endpoint: &str, chain_id: u64) -> Self {
        EthereumConnector {
            endpoint: endpoint.to_string(),
            chain_id,
        }
    }
    
    /// 发送交易到以太坊网络（模拟）
    pub fn send_transaction(&self, transaction_data: &str, gas_limit: u64) -> Result<String, Box<dyn Error>> {
        // 此处仅为模拟，实际应用需要使用web3库连接到以太坊网络
        println!("向 {} 发送交易，链 ID：{}", self.endpoint, self.chain_id);
        println!("交易数据：{}", transaction_data);
        println!("Gas 限制：{}", gas_limit);
        
        // 模拟交易哈希
        let tx_hash = crypto::hash_sha256(&format!("{}{}{}", transaction_data, gas_limit, SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs()));
        Ok(tx_hash)
    }
    
    /// 调用智能合约（模拟）
    pub fn call_contract(&self, contract_address: &str, method_name: &str, params: &[&str]) -> Result<String, Box<dyn Error>> {
        // 此处仅为模拟，实际应用需要使用web3库调用合约
        println!("调用合约：{}", contract_address);
        println!("方法：{}", method_name);
        println!("参数：{:?}", params);
        
        // 模拟返回数据
        let result = format!("合约执行结果_{}", crypto::hash_sha256(method_name).chars().take(8).collect::<String>());
        Ok(result)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_transaction_creation_and_signing() {
        // 生成密钥对
        let (private_key, public_key) = crypto::generate_keypair();
        
        // 创建交易
        let mut tx = Transaction::new(
            TransactionType::DataSubmission,
            "sender123",
            "测试数据提交",
        ).with_recipient("recipient456")
         .with_gas_fee(21000);
        
        // 签名交易
        tx.sign(&private_key).unwrap();
        
        // 验证交易
        assert!(tx.verify_signature(&public_key));
        assert_eq!(tx.status, TransactionStatus::Pending);
    }
    
    #[test]
    fn test_block_mining() {
        let mut block = Block::new(1, "previous_hash", Vec::new(), 2);
        block.mine();
        
        // 验证挖掘结果
        assert!(block.is_valid());
        assert!(block.hash.starts_with("00"));
    }
    
    #[test]
    fn test_blockchain_creation() {
        let blockchain = Blockchain::new(2, 50);
        
        // 验证创世区块已创建
        assert_eq!(blockchain.chain.len(), 1);
        assert_eq!(blockchain.chain[0].index, 0);
        assert_eq!(blockchain.chain[0].previous_hash, "0");
    }
} 