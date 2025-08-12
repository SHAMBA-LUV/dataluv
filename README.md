# 🌟 SHAMBA LUV 0x583F6D336E777c461FbfbeE3349D7D2dA9dc5e51 - Automatic Airdrop DApp
https://polygonscan.com/token/0x1035760d0f60b35b63660ac0774ef363eaa5456e
```txt
0x583F6D336E777c461FbfbeE3349D7D2dA9dc5e51
```

SHAMBA LUV is a digital gesture designed to spread abundance, fun, joy and LUV as community vibe for social sharing building an emotional economy where gestures are stored on-chain giving attention, gestures, and community impact value from the power of LUV

![SHAMBA LUV](https://img.shields.io/badge/SHAMBA%20LUV-❤️%20Token-ff1493)
![Polygon](https://img.shields.io/badge/Polygon-Mainnet-8247E5)
![Thirdweb](https://img.shields.io/badge/Powered%20by-Thirdweb-purple)

## 🎯 Overview
0x583F6D336E777c461FbfbeE3349D7D2dA9dc5e51
<a href="https://luv.pythai.net">SHAMBA LUV</a> is LUV airdrop contract that automatically distributes **1 TRILLION SHAMBA LUV** to a maximum of 3000 new participants when they connect their social account which creates a personal wallet. Your LUV wallet is entirely under your control. You hold the private key. LUV is the answer. Built with Thirdweb SDK v5, it features:

- 🎁 **Automatic Airdrops** - 1 000 000 000 000 SHAMBA LUV tokens instantly on wallet connection
- 💎 **Reflection Rewards** - 3% of every transaction distributed to holders
- ⛽ **Sponsored Gas** - Users pay no gas fees to collect LUV (gasless transactions)
- 🔐 **Smart Account Wallets** - Email, social logins, and passkey support
- 🎨 **Trippy Landing Page** - Psychedelic animations and effects

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Smart Contracts](#smart-contracts)
- [Running the DApp](#running-the-dapp)
- [Deployment Guide](#deployment-guide)
- [Architecture](#architecture)
- [Customization](#customization)
- [Documentation](#documentation)
- [Thirdweb Documentation](#thirdweb-documentation)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

- **Node.js** (v18 or higher)
- **Yarn** or **npm**
- **Thirdweb Account** - [Create one here](https://thirdweb.com/dashboard)
- **Polygon (MATIC)** for deployment
- **MetaMask** or any Web3 wallet

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/SHAMBA-LUV/dataluv.git
   cd dataluv
   ```

2. **Install dependencies**
   ```bash
   yarn install
   # or
   npm install
   ```

3. **Set up environment variables**
   
   Create a `.env` file in the root directory:
   ```env
   VITE_TEMPLATE_CLIENT_ID=your_thirdweb_client_id
   VITE_TEMPLATE_SECRET_KEY=your_thirdweb_secret_key
   VITE_TEMPLATE_ACCOUNT_MANAGER_ADDRESS=0x_your_account_manager_address
   VITE_TEMPLATE_TOKEN_CONTRACT_ADDRESS=0x_your_token_address
   VITE_AIRDROP_CONTRACT_ADDRESS=0x_your_airdrop_address
   ```

## ⚙️ Configuration

### 1. **Thirdweb Setup**

1. Go to [Thirdweb Dashboard](https://thirdweb.com/dashboard)
2. Create a new project
3. Get your Client ID and Secret Key
4. Enable these services:
   - **In-App Wallets** for email/social login
   - **Account Abstraction** for smart accounts
   - **Bundler & Paymaster** for sponsored gas

### 2. **Contract Addresses**

You'll need to deploy two contracts:

1. **LUV Token Contract** (`LUV.sol`) - The main ERC20 token
2. **Airdrop Contract** (`ShambaLuvAirdrop.sol`) - Handles automatic distribution

### 3. **Token Configuration**

Edit `src/tokens.ts` to customize:
```typescript
export const SHAMBA_LUV_TOKEN = {
  address: "0x...", // Your token address
  name: "SHAMBA LUV",
  symbol: "LUV",
  decimals: 18,
  chain: polygon,
  icon: "❤️",
};
```

## 📜 Smart Contracts

### **LUV.sol** - Main Token Contract

- **Total Supply**: 100 Quadrillion tokens
- **Reflection Fee**: 3% (distributed to holders)
- **Liquidity Fee**: 1% 
- **Team Fee**: 1%
- **Max Transfer**: 1% of total supply

### **ShambaLuvAirdrop.sol** - Airdrop Contract

```solidity
// Key functions:
function claimAirdrop() external // Claims 1 trillion tokens
function hasUserClaimed(address) view returns (bool) // Check claim status
function setAirdropAmount(uint256) external onlyOwner // Update amount
```

## 🏃‍♂️ Running the DApp

### **Development Mode**
```bash
yarn dev
# or
npm run dev
```
Visit `http://localhost:5173`

### **Build for Production**
```bash
yarn build
# or
npm run build
```

### **Preview Production Build**
```bash
yarn preview
# or
npm run preview
```

## 🚢 Deployment Guide

### **Step 1: Deploy Smart Contracts**

1. **Deploy LUV Token** (if not already deployed)
   ```bash
   # Using Thirdweb Deploy
   npx thirdweb deploy
   ```
   Select `LUV.sol` and deploy to Polygon Mainnet

2. **Deploy Airdrop Contract**
   ```bash
   npx thirdweb deploy
   ```
   Select `ShambaLuvAirdrop.sol` and pass the token address as constructor parameter

3. **Fund the Airdrop Contract**
   - Send tokens to the airdrop contract
   - Recommended: At least 1000 trillion tokens for 1000 users

### **Step 2: Update Environment Variables**

Update your `.env` file with the deployed addresses:
```env
VITE_TEMPLATE_TOKEN_CONTRACT_ADDRESS=0x1035760d0f60B35B63660ac0774ef363eAa5456e
VITE_AIRDROP_CONTRACT_ADDRESS=0x583F6D336E777c461FbfbeE3349D7D2dA9dc5e51
```

### **Step 3: Deploy Frontend**

**Option A: Vercel** (Recommended)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel
```

**Option B: Netlify**
1. Build the project: `yarn build`
2. Drag the `dist` folder to [Netlify](https://app.netlify.com/drop)

**Option C: Traditional Hosting**
1. Build: `yarn build`
2. Upload contents of `dist` folder to your web server

## 🏗️ Architecture

```
shamba-luv/
├── src/
│   ├── App.tsx              # Main app with routing logic
│   ├── AirdropApp.tsx       # Airdrop dashboard component
│   ├── client.ts            # Thirdweb client configuration
│   ├── tokens.ts            # Token & contract configuration
│   └── index.css            # Global styles & animations
├── LUV.sol                  # Main token contract
├── ShambaLuvAirdrop.sol     # Airdrop distribution contract
└── .env                     # Environment variables
```

### **Component Flow**

1. **Landing Page** → LUV is priceless
2. **Connect Wallet** → Multiple auth options (email, Google, etc.)
3. **Auto-Airdrop** → Checks eligibility and claims automatically
4. **Dashboard** → Shows balance and token information

## 🎨 Customization

### **Change Airdrop Amount**

In `ShambaLuvAirdrop.sol`:
```solidity
uint256 public airdropAmount = 1_000_000_000_000 * 1e18; // 1 trillion
```

### **Modify Landing Page**

Edit `src/App.tsx`:
- Change colors in gradient backgrounds
- Adjust animation speeds
- Update text and emojis
- Add/remove floating particles

### **Update Token Branding**

1. Change token icon in `src/tokens.ts`
2. Update colors in Tailwind classes
3. Modify landing page text

### **Add Features**

- Staking mechanism
- Governance voting
- NFT integration
- Liquidity pools

## 📚 Documentation

### **Project Documentation**

- **[Burn Functions Guide](docs/BURN_FUNCTIONS_ADDED.md)** - Complete guide to the burn functions added to the LUV contract
- **[Database Setup](docs/DATABASE_SETUP.md)** - PostgreSQL database setup and configuration guide
- **[Deployment Guide](docs/DEPLOY.md)** - Step-by-step deployment instructions and best practices
- **[Immediate Airdrop Update](docs/IMMEDIATE_AIRDROP_UPDATE.md)** - Details about the immediate airdrop functionality
- **[License](docs/LICENSE.md)** - Project license information
- **[Supply Analysis](docs/SUPPLY_ANALYSIS.md)** - Analysis of the 100 Quadrillion token supply structure
- **[Thirdweb Setup Guide](docs/THIRDWEB_SETUP.md)** - Comprehensive Thirdweb setup guide with troubleshooting

### **Graphics & Assets**

- **[Graphics Documentation](public/gfx/README.md)** - Graphics folder structure and asset management guide

## 📚 Thirdweb Documentation

### **Core Concepts**
- [Thirdweb SDK Overview](https://portal.thirdweb.com/typescript/v5)
- [React SDK Documentation](https://portal.thirdweb.com/typescript/v5/react)
- [Client Configuration](https://portal.thirdweb.com/typescript/v5/client)

### **In-App Wallets**
- [In-App Wallet Setup](https://portal.thirdweb.com/connect/in-app-wallet/overview)
- [Authentication Methods](https://portal.thirdweb.com/connect/in-app-wallet/custom-auth)
- [Social Login Integration](https://portal.thirdweb.com/connect/in-app-wallet/social-login)

### **Account Abstraction**
- [Smart Accounts Overview](https://portal.thirdweb.com/connect/account-abstraction)
- [Sponsored Transactions](https://portal.thirdweb.com/connect/account-abstraction/sponsorship)
- [Account Factory Setup](https://portal.thirdweb.com/connect/account-abstraction/guides/deploy-account-factory)

### **Smart Contracts**
- [Deploy with Thirdweb](https://portal.thirdweb.com/deploy)
- [Contract Extensions](https://portal.thirdweb.com/contracts/build/extensions)
- [Interact with Contracts](https://portal.thirdweb.com/typescript/v5/extensions/built-in)

### **Additional Resources**
- [Thirdweb Dashboard](https://thirdweb.com/dashboard)
- [Polygon Chain Information](https://portal.thirdweb.com/chains/polygon)
- [Gas Sponsorship Guide](https://portal.thirdweb.com/connect/account-abstraction/guides/sponsor-gas)

## 🐛 Troubleshooting

### **Common Issues**

1. **"Airdrop Contract Not Deployed Yet"**
   - Deploy `ShambaLuvAirdrop.sol`
   - Update `VITE_AIRDROP_CONTRACT_ADDRESS` in `.env`

2. **"Insufficient tokens in contract"**
   - Fund the airdrop contract with tokens
   - Use `depositTokens()` function or direct transfer

3. **"Already claimed"**
   - Each wallet can only claim once
   - Check claim status with `hasUserClaimed()`

4. **Gas Sponsorship Not Working**
   - Ensure Account Abstraction is enabled in Thirdweb Dashboard
   - Check paymaster balance
   - Verify smart account configuration

### **Debug Mode**

Enable console logging:
```typescript
// In src/client.ts
export const client = createThirdwebClient({
  clientId: clientId,
  secretKey: secretKey,
  config: {
    logLevel: "debug" // Add this
  }
});
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [Thirdweb SDK v5](https://thirdweb.com)
- Deployed on [Polygon Network](https://polygon.technology)
- UI components from [Tailwind CSS](https://tailwindcss.com)

## 📞 Support

- **Discord**: [Join Thirdweb Discord](https://discord.gg/thirdweb)
- **Documentation**: [docs.thirdweb.com](https://portal.thirdweb.com)
- **GitHub Issues**: [Create an issue](https://github.com/yourusername/shamba-luv/issues)

---

**Made with ❤️ and SHAMBA LUV**
