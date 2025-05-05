// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 ADDPHO

pragma solidity 0.8.25;

library DateTimeLib {
    error InvalidTimestamp();

    function timestampToDate(
        uint256 timestamp
    ) internal pure returns (string memory) {
        if (timestamp == 0 || timestamp > type(uint256).max) {
            revert InvalidTimestamp();
        }

        // Convert timestamp to UTC date components
        uint256 year;
        uint256 month;
        uint256 day;

        unchecked {
            uint256 _days = timestamp / 86400;

            // Algorithm from https://howardhinnant.github.io/date_algorithms.html
            uint256 z = _days + 719468;
            uint256 era = (z >= 0 ? z : z - 146096) / 146097;
            uint256 doe = z - era * 146097;
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
            year = yoe + era * 400;
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            month = (5 * doy + 2) / 153;
            day = doy - (153 * month + 2) / 5 + 1;

            // Adjust month and year
            if (month < 10) {
                month = month + 3;
            } else {
                month = month - 9;
            }
            year = year + (month <= 2 ? 1 : 0);
        }

        // Format the date as YYYY-MM-DD
        return
            string(
                abi.encodePacked(
                    _uintToString(year),
                    "-",
                    _padZero(_uintToString(month)),
                    "-",
                    _padZero(_uintToString(day))
                )
            );
    }

    function _uintToString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function _padZero(string memory str) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length >= 2) return str;

        return string(abi.encodePacked("0", str));
    }
}
