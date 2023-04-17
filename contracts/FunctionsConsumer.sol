// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Functions, FunctionsClient} from "./dev/functions/FunctionsClient.sol";
// import "@chainlink/contracts/src/v0.8/dev/functions/FunctionsClient.sol"; // Once published
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Functions Consumer contract
 * @notice This contract is a demonstration of using Functions.
 * @notice NOT FOR PRODUCTION USE
 */
contract FunctionsConsumer is FunctionsClient, ConfirmedOwner, ERC721, ERC721URIStorage {
  using Functions for Functions.Request;
  using Counters for Counters.Counter;
  using Address for string;

  Counters.Counter private _tokenIdCounter;

  bytes32 public latestRequestId;
  bytes public latestResponse;
  bytes public latestError;

  // map of request ID to token ID
  mapping(bytes32 => uint256) requestIdToTokenId;
  // map tokenId to github count
  mapping(uint256 => uint256) tokenIdToGithubCount;

  event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);
  // mint token event
  event MintedToken(address indexed minter, uint256 tokenId);

  /**
   * @notice Executes once when a contract is created to initialize state variables
   *
   * @param oracle - The FunctionsOracle contract
   */
  // https://github.com/protofire/solhint/issues/242
  // solhint-disable-next-line no-empty-blocks
  constructor(address oracle) FunctionsClient(oracle) ConfirmedOwner(msg.sender) ERC721("AWSDevDayTrophy", "ADDT") {}

  /**
   * @notice Send a simple request
   *
   * @param source JavaScript source code
   * @param secrets Encrypted secrets payload
   * @param args List of arguments accessible from within the source code
   * @param subscriptionId Funtions billing subscription ID
   * @param gasLimit Maximum amount of gas used to call the client contract's `handleOracleFulfillment` function
   * @return Functions request ID
   */
  function executeRequest(
    string calldata source,
    bytes calldata secrets,
    string[] calldata args,
    uint64 subscriptionId,
    uint32 gasLimit
  ) public returns (bytes32) {
    //require that the user has no nfts minted
    require(balanceOf(msg.sender) == 0, "User already has an NFT");
    Functions.Request memory req;
    req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, source);
    if (secrets.length > 0) {
      req.addRemoteSecrets(secrets);
    }
    if (args.length > 0) req.addArgs(args);

    bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
    latestRequestId = assignedReqID;
    // map request ID to token ID
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    requestIdToTokenId[assignedReqID] = tokenId;
    // map token ID to github count
    tokenIdToGithubCount[tokenId] = 0;
    // mint token
    _safeMint(msg.sender, tokenId);
    emit MintedToken(msg.sender, tokenId);

    return assignedReqID;
  }

  /**
   * @notice Callback that is invoked once the DON has resolved the request or hit an error
   *
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    latestResponse = response;
    latestError = err;
    emit OCRResponse(requestId, response, err);
    // update token URI
    uint256 tokenId = requestIdToTokenId[requestId];
    tokenIdToGithubCount[tokenId] = abi.decode(response, (uint256));
  }

  /**
   * @notice Allows the Functions oracle address to be updated
   *
   * @param oracle New oracle address
   */
  function updateOracleAddress(address oracle) public onlyOwner {
    setOracle(oracle);
  }

  function addSimulatedRequestId(address oracleAddress, bytes32 requestId) public onlyOwner {
    addExternalRequest(oracleAddress, requestId);
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    // get github count for token ID
    uint256 githubCount = tokenIdToGithubCount[tokenId];
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "AWS Dev Day NFT",',
            '"description": "A token of your participation in the demo day.", '
            '"image": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/',
            string(Strings.toString(githubCount)),
            '.png",',
            '"attributes": [',
            '{"trait_type": "Github Count", "value": ',
            string(Strings.toString(githubCount)),
            "}",
            "]",
            "}"
          )
        )
      )
    );
    string memory finalTokenURI = string(abi.encodePacked("data:application/json;base64,", json));
    return finalTokenURI;
  }
}
