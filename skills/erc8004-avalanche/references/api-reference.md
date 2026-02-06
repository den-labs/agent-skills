# ERC-8004 API Reference for Avalanche

## TypeScript/JavaScript Examples (using viem)

### Setup

```typescript
import { createPublicClient, createWalletClient, http, parseAbi } from 'viem';
import { avalanche, avalancheFuji } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

// Choose network
const chain = avalanche; // or avalancheFuji for testnet

const IDENTITY_REGISTRY = chain.id === 43114
  ? '0x8004A169FB4a3325136EB29fA0ceB6D2e539a432'
  : '0x8004A818BFB912233c491871b3d84c89A494BD9e';

const REPUTATION_REGISTRY = chain.id === 43114
  ? '0x8004BAa17C55a88189AE136b182e5fdA19dE9b63'
  : '0x8004B663056A597Dffe9eCcC1965A193B7388713';

const publicClient = createPublicClient({
  chain,
  transport: http(),
});

const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
const walletClient = createWalletClient({
  account,
  chain,
  transport: http(),
});
```

### Identity Registry

```typescript
const identityAbi = parseAbi([
  'function register(string agentURI) external returns (uint256 agentId)',
  'function register() external returns (uint256 agentId)',
  'function tokenURI(uint256 tokenId) external view returns (string)',
  'function ownerOf(uint256 tokenId) external view returns (address)',
  'function setAgentURI(uint256 agentId, string newURI) external',
  'function getAgentWallet(uint256 agentId) external view returns (address)',
  'function getMetadata(uint256 agentId, string metadataKey) external view returns (bytes)',
  'function setMetadata(uint256 agentId, string metadataKey, bytes metadataValue) external',
  'function setAgentWallet(uint256 agentId, address newWallet, uint256 deadline, bytes signature) external',
  'function getVersion() external pure returns (string)',
  'event Registered(uint256 indexed agentId, string agentURI, address indexed owner)',
  'event URIUpdated(uint256 indexed agentId, string newURI, address indexed updatedBy)',
]);

// Register an agent
const hash = await walletClient.writeContract({
  address: IDENTITY_REGISTRY,
  abi: identityAbi,
  functionName: 'register',
  args: ['https://myagent.xyz/agent.json'],
});
console.log('Registration tx:', hash);

// Read agent URI
const uri = await publicClient.readContract({
  address: IDENTITY_REGISTRY,
  abi: identityAbi,
  functionName: 'tokenURI',
  args: [1n],
});
console.log('Agent URI:', uri);

// Get agent owner
const owner = await publicClient.readContract({
  address: IDENTITY_REGISTRY,
  abi: identityAbi,
  functionName: 'ownerOf',
  args: [1n],
});
console.log('Owner:', owner);

// Update agent URI
await walletClient.writeContract({
  address: IDENTITY_REGISTRY,
  abi: identityAbi,
  functionName: 'setAgentURI',
  args: [1n, 'ipfs://NewCID'],
});

// Set metadata
await walletClient.writeContract({
  address: IDENTITY_REGISTRY,
  abi: identityAbi,
  functionName: 'setMetadata',
  args: [1n, 'website', '0x' + Buffer.from('https://myagent.xyz').toString('hex')],
});
```

### Reputation Registry

```typescript
const reputationAbi = parseAbi([
  'function giveFeedback(uint256 agentId, int128 value, uint8 valueDecimals, string tag1, string tag2, string endpoint, string feedbackURI, bytes32 feedbackHash) external',
  'function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external',
  'function appendResponse(uint256 agentId, address clientAddress, uint64 feedbackIndex, string responseURI, bytes32 responseHash) external',
  'function readFeedback(uint256 agentId, address clientAddress, uint64 feedbackIndex) external view returns (int128 value, uint8 valueDecimals, string tag1, string tag2, bool isRevoked)',
  'function readAllFeedback(uint256 agentId, address[] clientAddresses, string tag1, string tag2, bool includeRevoked) external view returns (address[] clients, uint64[] feedbackIndexes, int128[] values, uint8[] valueDecimals, string[] tag1s, string[] tag2s, bool[] revokedStatuses)',
  'function getSummary(uint256 agentId, address[] clientAddresses, string tag1, string tag2) external view returns (uint64 count, int128 summaryValue, uint8 summaryValueDecimals)',
  'function getClients(uint256 agentId) external view returns (address[])',
  'function getLastIndex(uint256 agentId, address clientAddress) external view returns (uint64)',
  'event NewFeedback(uint256 indexed agentId, address indexed clientAddress, uint64 feedbackIndex, int128 value, uint8 valueDecimals, string indexed indexedTag1, string tag1, string tag2, string endpoint, string feedbackURI, bytes32 feedbackHash)',
]);

// Give feedback (rating: 85/100)
await walletClient.writeContract({
  address: REPUTATION_REGISTRY,
  abi: reputationAbi,
  functionName: 'giveFeedback',
  args: [
    1n,                    // agentId
    85n,                   // value
    0,                     // valueDecimals
    'starred',             // tag1
    '',                    // tag2
    '',                    // endpoint
    '',                    // feedbackURI
    '0x0000000000000000000000000000000000000000000000000000000000000000', // feedbackHash
  ],
});

// Read feedback
const feedback = await publicClient.readContract({
  address: REPUTATION_REGISTRY,
  abi: reputationAbi,
  functionName: 'readFeedback',
  args: [1n, '0xClientAddress', 1n],
});
console.log('Feedback:', feedback);

// Get reputation summary (filtered by reviewers)
const summary = await publicClient.readContract({
  address: REPUTATION_REGISTRY,
  abi: reputationAbi,
  functionName: 'getSummary',
  args: [1n, ['0xTrustedReviewer1', '0xTrustedReviewer2'], 'starred', ''],
});
console.log(`Count: ${summary[0]}, Average: ${summary[1]}, Decimals: ${summary[2]}`);

// Get all clients who gave feedback
const clients = await publicClient.readContract({
  address: REPUTATION_REGISTRY,
  abi: reputationAbi,
  functionName: 'getClients',
  args: [1n],
});
console.log('Clients:', clients);
```

### Validation Registry

```typescript
const validationAbi = parseAbi([
  'function validationRequest(address validatorAddress, uint256 agentId, string requestURI, bytes32 requestHash) external',
  'function validationResponse(bytes32 requestHash, uint8 response, string responseURI, bytes32 responseHash, string tag) external',
  'function getValidationStatus(bytes32 requestHash) external view returns (address validatorAddress, uint256 agentId, uint8 response, bytes32 responseHash, string tag, uint256 lastUpdate)',
  'function getSummary(uint256 agentId, address[] validatorAddresses, string tag) external view returns (uint64 count, uint8 avgResponse)',
  'function getAgentValidations(uint256 agentId) external view returns (bytes32[])',
  'function getValidatorRequests(address validatorAddress) external view returns (bytes32[])',
]);

// Request validation
const requestHash = keccak256(toBytes(JSON.stringify({ input: 'test', output: 'result' })));
await walletClient.writeContract({
  address: VALIDATION_REGISTRY,
  abi: validationAbi,
  functionName: 'validationRequest',
  args: ['0xValidatorAddress', 1n, 'ipfs://requestData', requestHash],
});

// Check validation status
const status = await publicClient.readContract({
  address: VALIDATION_REGISTRY,
  abi: validationAbi,
  functionName: 'getValidationStatus',
  args: [requestHash],
});
console.log('Validation:', status);
```

### ethers.js Alternative

```typescript
import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider('https://api.avax.network/ext/bc/C/rpc');
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

const identityRegistry = new ethers.Contract(
  '0x8004A169FB4a3325136EB29fA0ceB6D2e539a432',
  ['function register(string) returns (uint256)', 'function tokenURI(uint256) view returns (string)'],
  wallet
);

// Register
const tx = await identityRegistry.register('https://myagent.xyz/agent.json');
const receipt = await tx.wait();
console.log('Registered! TX:', receipt.hash);

// Read
const uri = await identityRegistry.tokenURI(1);
console.log('Agent URI:', uri);
```
