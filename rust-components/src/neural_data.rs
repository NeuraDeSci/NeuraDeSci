use serde::{Serialize, Deserialize};
use std::collections::HashMap;
use std::error::Error;

/// Represents the format of neural data
#[derive(Debug, Serialize, Deserialize, PartialEq, Eq, Clone, Copy)]
pub enum NeuralDataFormat {
    EEG,
    FMRI,
    MEG,
    PET,
    MRI,
    CT,
    SPECT,
    ECOG,
    SingleUnitRecording,
    Custom,
}

/// Represents a time series of neural data
#[derive(Debug, Serialize, Deserialize)]
pub struct NeuralTimeSeries {
    pub format: NeuralDataFormat,
    pub sampling_rate: f64, // Hz
    pub channels: Vec<String>,
    pub timestamps: Vec<f64>,
    pub data: Vec<Vec<f64>>, // channel x time
    pub units: String,
    pub metadata: HashMap<String, String>,
}

impl NeuralTimeSeries {
    /// Create a new, empty neural time series
    pub fn new(format: NeuralDataFormat, sampling_rate: f64, units: &str) -> Self {
        NeuralTimeSeries {
            format,
            sampling_rate,
            channels: Vec::new(),
            timestamps: Vec::new(),
            data: Vec::new(),
            units: units.to_string(),
            metadata: HashMap::new(),
        }
    }
    
    /// Add a channel to the time series
    pub fn add_channel(&mut self, name: &str, data: Vec<f64>) -> Result<(), Box<dyn Error>> {
        if !self.timestamps.is_empty() && data.len() != self.timestamps.len() {
            return Err(format!("Channel data length ({}) does not match timestamps length ({})", 
                              data.len(), self.timestamps.len()).into());
        }
        
        self.channels.push(name.to_string());
        self.data.push(data);
        
        Ok(())
    }
    
    /// Set timestamps for the time series
    pub fn set_timestamps(&mut self, timestamps: Vec<f64>) -> Result<(), Box<dyn Error>> {
        if !self.data.is_empty() && !self.data[0].is_empty() && timestamps.len() != self.data[0].len() {
            return Err(format!("Timestamps length ({}) does not match data length ({})", 
                              timestamps.len(), self.data[0].len()).into());
        }
        
        self.timestamps = timestamps;
        Ok(())
    }
    
    /// Generate evenly spaced timestamps based on sampling rate
    pub fn generate_timestamps(&mut self, start_time: f64, num_samples: usize) {
        let dt = 1.0 / self.sampling_rate;
        self.timestamps = (0..num_samples)
            .map(|i| start_time + dt * i as f64)
            .collect();
    }
    
    /// Get data for a specific channel
    pub fn get_channel_data(&self, channel_name: &str) -> Option<&Vec<f64>> {
        let channel_idx = self.channels.iter().position(|c| c == channel_name)?;
        self.data.get(channel_idx)
    }
    
    /// Add metadata
    pub fn add_metadata(&mut self, key: &str, value: &str) {
        self.metadata.insert(key.to_string(), value.to_string());
    }
    
    /// Serialize to JSON
    pub fn to_json(&self) -> Result<String, Box<dyn Error>> {
        let json = serde_json::to_string(self)?;
        Ok(json)
    }
    
    /// Deserialize from JSON
    pub fn from_json(json: &str) -> Result<Self, Box<dyn Error>> {
        let time_series: NeuralTimeSeries = serde_json::from_str(json)?;
        Ok(time_series)
    }
    
    /// Calculate basic statistics for a channel
    pub fn calculate_channel_stats(&self, channel_name: &str) -> Option<ChannelStatistics> {
        let data = self.get_channel_data(channel_name)?;
        
        if data.is_empty() {
            return None;
        }
        
        let mut min_val = data[0];
        let mut max_val = data[0];
        let mut sum = 0.0;
        
        for &value in data {
            min_val = min_val.min(value);
            max_val = max_val.max(value);
            sum += value;
        }
        
        let mean = sum / data.len() as f64;
        
        let mut variance_sum = 0.0;
        for &value in data {
            variance_sum += (value - mean).powi(2);
        }
        
        let variance = variance_sum / data.len() as f64;
        let std_dev = variance.sqrt();
        
        Some(ChannelStatistics {
            channel: channel_name.to_string(),
            min: min_val,
            max: max_val,
            mean,
            std_dev,
        })
    }
}

/// Statistics for a neural data channel
#[derive(Debug, Serialize, Deserialize)]
pub struct ChannelStatistics {
    pub channel: String,
    pub min: f64,
    pub max: f64,
    pub mean: f64,
    pub std_dev: f64,
}

/// Represents metadata for a brain imaging study
#[derive(Debug, Serialize, Deserialize)]
pub struct BrainStudyMetadata {
    pub subject_id: String,
    pub age: Option<u8>,
    pub sex: Option<String>,
    pub diagnosis: Option<String>,
    pub study_date: String,
    pub experiment_type: String,
    pub institution: String,
    pub researchers: Vec<String>,
    pub equipment: HashMap<String, String>,
    pub notes: Option<String>,
    pub protocol_id: Option<String>,
}

impl BrainStudyMetadata {
    pub fn new(subject_id: &str, experiment_type: &str, institution: &str) -> Self {
        BrainStudyMetadata {
            subject_id: subject_id.to_string(),
            age: None,
            sex: None,
            diagnosis: None,
            study_date: chrono::Local::now().format("%Y-%m-%d").to_string(),
            experiment_type: experiment_type.to_string(),
            institution: institution.to_string(),
            researchers: Vec::new(),
            equipment: HashMap::new(),
            notes: None,
            protocol_id: None,
        }
    }
    
    pub fn add_researcher(&mut self, name: &str) {
        self.researchers.push(name.to_string());
    }
    
    pub fn add_equipment(&mut self, name: &str, details: &str) {
        self.equipment.insert(name.to_string(), details.to_string());
    }
    
    pub fn to_json(&self) -> Result<String, Box<dyn Error>> {
        let json = serde_json::to_string(self)?;
        Ok(json)
    }
    
    pub fn from_json(json: &str) -> Result<Self, Box<dyn Error>> {
        let metadata: BrainStudyMetadata = serde_json::from_str(json)?;
        Ok(metadata)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_neural_time_series() {
        let mut ts = NeuralTimeSeries::new(NeuralDataFormat::EEG, 256.0, "microvolts");
        
        // Add timestamps
        ts.generate_timestamps(0.0, 5);
        assert_eq!(ts.timestamps, vec![0.0, 0.00390625, 0.0078125, 0.01171875, 0.015625]);
        
        // Add a channel
        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        ts.add_channel("Fz", data.clone()).unwrap();
        
        assert_eq!(ts.channels.len(), 1);
        assert_eq!(ts.data.len(), 1);
        assert_eq!(ts.get_channel_data("Fz").unwrap(), &data);
        
        // Add metadata
        ts.add_metadata("subject", "S001");
        assert_eq!(ts.metadata.get("subject").unwrap(), "S001");
    }
    
    #[test]
    fn test_calculate_statistics() {
        let mut ts = NeuralTimeSeries::new(NeuralDataFormat::EEG, 256.0, "microvolts");
        
        // Add a channel
        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        ts.add_channel("Fz", data).unwrap();
        
        let stats = ts.calculate_channel_stats("Fz").unwrap();
        
        assert_eq!(stats.min, 1.0);
        assert_eq!(stats.max, 5.0);
        assert_eq!(stats.mean, 3.0);
        assert!(stats.std_dev - 1.4142135 < 0.0001);
    }

    #[test]
    fn test_brain_study_metadata() {
        let mut metadata = BrainStudyMetadata::new("S001", "EEG Study", "University Hospital");
        
        metadata.add_researcher("Dr. Jane Smith");
        metadata.add_equipment("EEG Device", "BrainAmp 64 Channel");
        metadata.age = Some(45);
        metadata.sex = Some("M".to_string());
        
        assert_eq!(metadata.subject_id, "S001");
        assert_eq!(metadata.researchers.len(), 1);
        assert_eq!(metadata.equipment.len(), 1);
        assert_eq!(metadata.age, Some(45));
    }
} 