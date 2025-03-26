import Head from 'next/head';
import Link from 'next/link';
import { useState, useEffect } from 'react';
import styles from '../styles/Home.module.css';

export default function Home() {
  const [isConnected, setIsConnected] = useState(false);
  const [address, setAddress] = useState('');
  
  // Check if wallet is connected
  useEffect(() => {
    const checkConnection = async () => {
      if (window.ethereum) {
        try {
          const accounts = await window.ethereum.request({ method: 'eth_accounts' });
          if (accounts.length > 0) {
            setIsConnected(true);
            setAddress(accounts[0]);
          }
        } catch (error) {
          console.error("Error checking connection:", error);
        }
      }
    };
    
    checkConnection();
  }, []);
  
  // Connect wallet
  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        setIsConnected(true);
        setAddress(accounts[0]);
      } catch (error) {
        console.error("Error connecting wallet:", error);
      }
    } else {
      alert("Please install MetaMask or another Ethereum wallet");
    }
  };
  
  return (
    <div className={styles.container}>
      <Head>
        <title>NeuraDeSci - Decentralized Neuroscience Research Platform</title>
        <meta name="description" content="NeuraDeSci is a Web3 platform for decentralized neuroscience research" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <header className={styles.header}>
          <div className={styles.logo}>
            <h1>NeuraDeSci</h1>
          </div>
          <nav className={styles.nav}>
            <Link href="/">
              <a>Home</a>
            </Link>
            <Link href="/research">
              <a>Research</a>
            </Link>
            <Link href="/datasets">
              <a>Datasets</a>
            </Link>
            <Link href="/collaborate">
              <a>Collaborate</a>
            </Link>
            <Link href="/governance">
              <a>Governance</a>
            </Link>
            <Link href="/about">
              <a>About</a>
            </Link>
          </nav>
          <div className={styles.connect}>
            {isConnected ? (
              <div className={styles.connected}>
                <span className={styles.address}>
                  {`${address.slice(0, 6)}...${address.slice(-4)}`}
                </span>
              </div>
            ) : (
              <button onClick={connectWallet} className={styles.connectButton}>
                Connect Wallet
              </button>
            )}
          </div>
        </header>

        <section className={styles.hero}>
          <div className={styles.heroContent}>
            <h1>Revolutionizing Neuroscience with Decentralized Science</h1>
            <p>
              NeuraDeSci connects neuroscientists globally, creating an open, transparent
              and collaborative research ecosystem powered by Web3 technology.
            </p>
            <div className={styles.cta}>
              <Link href="/research">
                <a className={styles.primaryButton}>Explore Research</a>
              </Link>
              <Link href="/contribute">
                <a className={styles.secondaryButton}>Contribute</a>
              </Link>
            </div>
          </div>
          <div className={styles.heroImage}>
            <img src="/images/brain-network.svg" alt="Neural Network Visualization" />
          </div>
        </section>

        <section className={styles.features}>
          <h2>Our Core Features</h2>
          <div className={styles.featureGrid}>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>🔄</div>
              <h3>Decentralized Data Sharing</h3>
              <p>Store and share research data securely using IPFS and blockchain technology</p>
            </div>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>👥</div>
              <h3>Open Collaboration</h3>
              <p>Connect with researchers worldwide for cross-disciplinary projects</p>
            </div>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>💰</div>
              <h3>Tokenized Incentives</h3>
              <p>Earn rewards for your contributions to the scientific community</p>
            </div>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>📝</div>
              <h3>Open Publishing</h3>
              <p>Publish results transparently with blockchain verification</p>
            </div>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>🏛️</div>
              <h3>Community Governance</h3>
              <p>Participate in shaping research priorities and funding allocations</p>
            </div>
            <div className={styles.featureCard}>
              <div className={styles.featureIcon}>🧠</div>
              <h3>AI-Powered Analysis</h3>
              <p>Access cutting-edge tools for collaborative data analysis</p>
            </div>
          </div>
        </section>

        <section className={styles.stats}>
          <div className={styles.statItem}>
            <h3>50+</h3>
            <p>Research Projects</p>
          </div>
          <div className={styles.statItem}>
            <h3>200+</h3>
            <p>Researchers</p>
          </div>
          <div className={styles.statItem}>
            <h3>1TB+</h3>
            <p>Research Data</p>
          </div>
          <div className={styles.statItem}>
            <h3>30+</h3>
            <p>Published Papers</p>
          </div>
        </section>

        <section className={styles.roadmap}>
          <h2>Project Roadmap</h2>
          <div className={styles.timeline}>
            <div className={styles.timelineItem}>
              <div className={styles.timelineContent}>
                <h3>Phase 1: Foundation</h3>
                <p>Core platform development, team building, and concept validation</p>
                <span className={styles.timelineBadge}>Completed</span>
              </div>
            </div>
            <div className={styles.timelineItem}>
              <div className={styles.timelineContent}>
                <h3>Phase 2: Testnet</h3>
                <p>Smart contract development, user testing, and interface refinement</p>
                <span className={styles.timelineBadge}>In Progress</span>
              </div>
            </div>
            <div className={styles.timelineItem}>
              <div className={styles.timelineContent}>
                <h3>Phase 3: Mainnet Launch</h3>
                <p>Platform launch, token generation, and initial research grants</p>
                <span className={styles.timelineBadge}>Upcoming</span>
              </div>
            </div>
            <div className={styles.timelineItem}>
              <div className={styles.timelineContent}>
                <h3>Phase 4: Ecosystem Expansion</h3>
                <p>Integration of AI tools, mobile apps, and expanded research areas</p>
                <span className={styles.timelineBadge}>Planned</span>
              </div>
            </div>
          </div>
        </section>

        <section className={styles.join}>
          <h2>Join the Community</h2>
          <p>
            Connect with neuroscientists, developers, and enthusiasts to shape the
            future of decentralized neuroscience research.
          </p>
          <div className={styles.socialLinks}>
            <a href="https://twitter.com/NeuraDeSci" target="_blank" rel="noopener noreferrer" className={styles.socialLink}>
              Twitter
            </a>
            <a href="https://discord.gg/neuradesci" target="_blank" rel="noopener noreferrer" className={styles.socialLink}>
              Discord
            </a>
            <a href="https://github.com/neuradeSci" target="_blank" rel="noopener noreferrer" className={styles.socialLink}>
              GitHub
            </a>
          </div>
        </section>
      </main>

      <footer className={styles.footer}>
        <div className={styles.footerContent}>
          <div className={styles.footerLogo}>
            <h2>NeuraDeSci</h2>
            <p>Unlocking the Brain's Code, Building Science's Future</p>
          </div>
          <div className={styles.footerLinks}>
            <div className={styles.footerLinkGroup}>
              <h3>Platform</h3>
              <Link href="/research"><a>Research</a></Link>
              <Link href="/datasets"><a>Datasets</a></Link>
              <Link href="/collaborate"><a>Collaborate</a></Link>
              <Link href="/governance"><a>Governance</a></Link>
            </div>
            <div className={styles.footerLinkGroup}>
              <h3>Resources</h3>
              <Link href="/docs"><a>Documentation</a></Link>
              <Link href="/tutorials"><a>Tutorials</a></Link>
              <Link href="/faq"><a>FAQ</a></Link>
              <Link href="/support"><a>Support</a></Link>
            </div>
            <div className={styles.footerLinkGroup}>
              <h3>Community</h3>
              <a href="https://twitter.com/NeuraDeSci" target="_blank" rel="noopener noreferrer">Twitter</a>
              <a href="https://discord.gg/neuradesci" target="_blank" rel="noopener noreferrer">Discord</a>
              <a href="https://github.com/neuradeSci" target="_blank" rel="noopener noreferrer">GitHub</a>
              <a href="mailto:info@neuradesci.io">Contact</a>
            </div>
          </div>
        </div>
        <div className={styles.copyright}>
          <p>&copy; {new Date().getFullYear()} NeuraDeSci. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
} 