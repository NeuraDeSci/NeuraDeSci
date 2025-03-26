#!/bin/bash
# Build script for NeuraDeSci Rust components

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required tools
if ! command_exists cargo; then
  echo "Error: Rust and Cargo are required but not installed."
  echo "Please install Rust from https://rustup.rs/"
  exit 1
fi

if ! command_exists wasm-pack; then
  echo "wasm-pack not found, installing..."
  cargo install wasm-pack
fi

# Display banner
echo "====================================="
echo "NeuraDeSci Rust Components Build Tool"
echo "====================================="
echo ""

# Build options
echo "Select build option:"
echo "1) Standard library build"
echo "2) WebAssembly build"
echo "3) Run tests"
echo "4) Build documentation"
echo "5) Build all"
echo "q) Quit"
echo ""

read -p "Option: " option

case $option in
  1)
    echo "Building standard library..."
    cargo build --release
    echo "Build complete! Library available at target/release/"
    ;;
  2)
    echo "Building WebAssembly package..."
    wasm-pack build --target web
    
    # Copy examples to the pkg directory for easy testing
    echo "Copying examples to pkg directory..."
    mkdir -p pkg/examples
    cp -r examples/* pkg/examples/
    
    echo "WebAssembly build complete! Package available at pkg/"
    echo "To test, run a web server in the pkg directory and open examples/index.html"
    ;;
  3)
    echo "Running tests..."
    cargo test
    ;;
  4)
    echo "Building documentation..."
    cargo doc --no-deps --open
    ;;
  5)
    echo "Building everything..."
    
    echo "Standard library build..."
    cargo build --release
    
    echo "WebAssembly build..."
    wasm-pack build --target web
    
    echo "Running tests..."
    cargo test
    
    echo "Building documentation..."
    cargo doc --no-deps
    
    # Copy examples to the pkg directory
    echo "Copying examples to pkg directory..."
    mkdir -p pkg/examples
    cp -r examples/* pkg/examples/
    
    echo "All builds complete!"
    ;;
  q)
    echo "Exiting..."
    exit 0
    ;;
  *)
    echo "Invalid option."
    exit 1
    ;;
esac

# Make executable
chmod +x build.sh 