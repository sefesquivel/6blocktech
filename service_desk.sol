// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ServiceFeeQuiz
 * @notice A simple worksheet-style contract for fee calculation, message construction, and hashing.
 *
 * Scenario Inputs:
 *  - First name: Maria
 *  - Middle name: Santos
 *  - Last name: Cruz
 *  - Service code: 1 or 2
 *
 * Pricing Rules:
 *  - Code 1 (Consultation): 10,000 + 12% tax = 11,200
 *  - Code 2 (Documents): 2,000 + 10% service charge, then 12% tax on subtotal = 2,464
 *
 * Message Format (no separators, 5 chars):
 *  [first char of FirstName] + [last char of MiddleName] + [first char of LastName] + [serviceCode digit] + [first digit of total fee]
 *
 * Hashing Rule:
 *  - serviceCode == 1 => keccak256(abi.encodePacked(message))
 *  - serviceCode == 2 => keccak256(abi.encode(message))
 *
 * Exercises: Use the provided functions to compute and verify your answers.
 */
contract ServiceFeeQuiz {
    uint256 private constant BASE_CONSULT = 10_000;
    uint256 private constant BASE_DOCS = 2_000;
    uint256 private constant TAX_BPS = 1200;        // 12%
    uint256 private constant SVC_BPS = 1000;        // 10%
    uint256 private constant BPS_DENOM = 10_000;

    struct Result {
        uint256 serviceFee;
        string message;
        bytes32 messageHash;
    }

    /// @notice Returns the fee, constructed message, and hash given names and a service code (1 or 2).
    function quote(
        string memory firstName,
        string memory middleName,
        string memory lastName,
        uint8 serviceCode
    ) public pure returns (Result memory) {
        require(serviceCode == 1 || serviceCode == 2, "serviceCode must be 1 or 2");
        require(bytes(firstName).length > 0, "firstName required");
        require(bytes(middleName).length > 0, "middleName required");
        require(bytes(lastName).length > 0, "lastName required");

        uint256 fee = _computeFee(serviceCode);

        // Build the 5-character message
        bytes1 a = _firstChar(firstName);
        bytes1 b = _lastChar(middleName);
        bytes1 c = _firstChar(lastName);
        bytes1 d = _toAsciiDigit(serviceCode);      // '1' or '2'
        bytes1 e = _toAsciiDigit(_firstDigit(fee)); // first digit of fee

        bytes memory packed = new bytes(5);
        packed[0] = a;
        packed[1] = b;
        packed[2] = c;
        packed[3] = d;
        packed[4] = e;

        string memory message = string(packed);

        bytes32 h = (serviceCode == 1)
            ? keccak256(abi.encodePacked(message))
            : keccak256(abi.encode(message));

        return Result({ serviceFee: fee, message: message, messageHash: h });
    }

    // Convenience function for the quiz scenario: Maria Santos Cruz
    function quoteMariaSantosCruz(uint8 serviceCode) external pure returns (Result memory) {
        return quote("Maria", "Santos", "Cruz", serviceCode);
    }

    // ---------- Helpers ----------

    function _computeFee(uint8 serviceCode) internal pure returns (uint256) {
        if (serviceCode == 1) {
            // 10,000 + 12% tax
            uint256 tax = (BASE_CONSULT * TAX_BPS) / BPS_DENOM; // 1,200
            return BASE_CONSULT + tax; // 11,200
        } else {
            // 2,000 + 10% svc = 2,200; then +12% tax on subtotal = +264 => 2,464
            uint256 svc = (BASE_DOCS * SVC_BPS) / BPS_DENOM; // 200
            uint256 subtotal = BASE_DOCS + svc; // 2,200
            uint256 tax = (subtotal * TAX_BPS) / BPS_DENOM; // 264
            return subtotal + tax; // 2,464
        }
    }

    function _firstChar(string memory s) internal pure returns (bytes1) {
        bytes memory b = bytes(s);
        return b[0];
    }

    function _lastChar(string memory s) internal pure returns (bytes1) {
        bytes memory b = bytes(s);
        return b[b.length - 1];
    }

    function _firstDigit(uint256 n) internal pure returns (uint8) {
        while (n >= 10) {
            n /= 10;
        }
        return uint8(n);
    }

    function _toAsciiDigit(uint8 d) internal pure returns (bytes1) {
        require(d <= 9, "digit out of range");
        return bytes1(uint8(48) + d); // '0' + d
    }
}
