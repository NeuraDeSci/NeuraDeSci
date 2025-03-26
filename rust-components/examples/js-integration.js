// Example JavaScript integration with NeuraDeSci Rust components
// This demonstrates how to use the WebAssembly-compiled Rust components in a web application

// Import the NeuraDeSci WebAssembly module
// Note: In a real application, you would use a proper import path
import * as neuradesci from '../pkg/neuradesci_core.js';

// Main function to demonstrate usage
async function demonstrateNeuraDeSci() {
  console.log("Initializing NeuraDeSci Core...");
  console.log(`Version: ${neuradesci.version()}`);

  // 1. Create a researcher credential
  const researcher = new neuradesci.ResearcherCredential(
    "r1001",
    "Dr. Alice Johnson",
    "Computational Neuroscience",
    "Neuroscience Institute"
  );
  
  researcher.add_publication("pub-10.1001/journal.neuro.2023001");
  console.log("Researcher created:", JSON.parse(researcher.to_json()));

  // 2. Generate encryption keys
  const keys = neuradesci.generate_keys();
  console.log("Generated keys:", keys);

  // 3. Create and encrypt neural data
  console.log("Creating EEG dataset...");
  const eegData = await neuradesci.create_eeg_data(
    256.0, // sampling rate in Hz
    "patient-p2001", 
    researcher.id
  );
  
  // Convert to JSON for storage/transmission
  const eegJson = JSON.stringify(eegData);
  console.log("EEG data created with channels:", eegData.channels);
  
  // Encrypt sensitive data
  const encryptedData = await neuradesci.encrypt_data(eegJson, keys.privateKey);
  console.log("Data encrypted, length:", encryptedData.length);

  // 4. Store on IPFS
  console.log("Uploading to IPFS...");
  try {
    const ipfsResult = await neuradesci.upload_to_ipfs(
      encryptedData,
      "eeg_study_encrypted.json"
    );
    console.log("IPFS upload result:", ipfsResult);

    // 5. Create a dataset record
    const dataset = new neuradesci.NeuroscienceDataset(
      "ds-" + Date.now(),
      "Cognitive Function EEG Study",
      "Analysis of EEG patterns during cognitive tasks",
      "EEG/TimeSeries",
      ipfsResult.cid,
      researcher.id,
      Date.now(),
      "CC-BY-NC-4.0"
    );
    
    dataset.add_keyword("cognition");
    dataset.add_keyword("eeg");
    dataset.add_keyword("working-memory");
    
    // Set as private - requires authorization to access
    dataset.set_private(true);
    
    console.log("Dataset created:", JSON.parse(dataset.to_json()));

    // 6. Create a blockchain transaction for data access
    console.log("Creating data access transaction...");
    const transaction = await neuradesci.create_neural_data_transaction(
      researcher.id,
      "r1002", // collaborator ID
      ipfsResult.cid,
      keys.privateKey
    );
    
    console.log("Transaction created:", transaction);
    
    // 7. Analyze the neural data
    console.log("Analyzing EEG data...");
    const analysisResults = await neuradesci.analyze_eeg_data(JSON.stringify(eegData));
    console.log("Analysis results:", analysisResults);
    
  } catch (error) {
    console.error("Error in NeuraDeSci operations:", error);
  }
}

// Run the demonstration when the page loads
window.onload = () => {
  // Add UI elements
  const container = document.createElement('div');
  container.innerHTML = `
    <h1>NeuraDeSci Rust Components Demo</h1>
    <p>This page demonstrates the integration of Rust components compiled to WebAssembly.</p>
    <button id="startDemo">Run Demonstration</button>
    <div id="output" style="margin-top: 20px; padding: 10px; background-color: #f3f3f3; height: 400px; overflow: auto;"></div>
  `;
  document.body.appendChild(container);
  
  // Redirect console output to the UI
  const outputDiv = document.getElementById('output');
  const originalConsoleLog = console.log;
  const originalConsoleError = console.error;
  
  console.log = function(...args) {
    originalConsoleLog.apply(console, args);
    const message = args.map(arg => 
      typeof arg === 'object' ? JSON.stringify(arg, null, 2) : arg
    ).join(' ');
    const logElement = document.createElement('div');
    logElement.textContent = message;
    outputDiv.appendChild(logElement);
    outputDiv.scrollTop = outputDiv.scrollHeight;
  };
  
  console.error = function(...args) {
    originalConsoleError.apply(console, args);
    const message = args.map(arg => 
      typeof arg === 'object' ? JSON.stringify(arg, null, 2) : arg
    ).join(' ');
    const logElement = document.createElement('div');
    logElement.style.color = 'red';
    logElement.textContent = message;
    outputDiv.appendChild(logElement);
    outputDiv.scrollTop = outputDiv.scrollHeight;
  };
  
  // Hook up the start button
  document.getElementById('startDemo').addEventListener('click', async () => {
    outputDiv.innerHTML = ''; // Clear previous output
    console.log("Starting NeuraDeSci demonstration...");
    await demonstrateNeuraDeSci();
    console.log("Demonstration complete!");
  });
}; 