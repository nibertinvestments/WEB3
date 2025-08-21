// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TimeUtils - Advanced Time and Date Calculation Library
 * @dev Comprehensive temporal utilities for smart contract applications
 * 
 * FEATURES:
 * - Unix timestamp manipulation and conversion
 * - Business day and working hours calculations
 * - Time-based access control utilities
 * - Scheduling and deadline management
 * - Time zone and calendar operations
 * 
 * USE CASES:
 * 1. Vesting schedule calculations and enforcement
 * 2. Time-locked transactions and delayed execution
 * 3. Business hours restricted operations
 * 4. Seasonal or periodic contract behavior
 * 5. Deadline-based governance and voting
 * 6. Time-weighted average calculations
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library TimeUtils {
    // Time constants
    uint256 constant SECONDS_PER_MINUTE = 60;
    uint256 constant SECONDS_PER_HOUR = 3600;
    uint256 constant SECONDS_PER_DAY = 86400;
    uint256 constant SECONDS_PER_WEEK = 604800;
    uint256 constant SECONDS_PER_YEAR = 31557600; // 365.25 days
    uint256 constant SECONDS_PER_MONTH = 2629800; // 30.44 days average
    
    // Business and calendar constants
    uint256 constant BUSINESS_HOURS_START = 9; // 9 AM
    uint256 constant BUSINESS_HOURS_END = 17;  // 5 PM
    
    /**
     * @dev Gets current block timestamp
     * Use Case: Current time reference, event timestamping
     */
    function now() internal view returns (uint256) {
        return block.timestamp;
    }
    
    /**
     * @dev Adds specified number of days to timestamp
     * Use Case: Future date calculations, vesting schedules
     */
    function addDays(uint256 timestamp, uint256 days) 
        internal pure returns (uint256) {
        return timestamp + (days * SECONDS_PER_DAY);
    }
    
    /**
     * @dev Adds specified number of weeks to timestamp
     * Use Case: Weekly recurring events, periodic calculations
     */
    function addWeeks(uint256 timestamp, uint256 weeks) 
        internal pure returns (uint256) {
        return timestamp + (weeks * SECONDS_PER_WEEK);
    }
    
    /**
     * @dev Adds specified number of months to timestamp (approximate)
     * Use Case: Monthly recurring operations, subscription cycles
     */
    function addMonths(uint256 timestamp, uint256 months) 
        internal pure returns (uint256) {
        return timestamp + (months * SECONDS_PER_MONTH);
    }
    
    /**
     * @dev Adds specified number of years to timestamp
     * Use Case: Long-term vesting, annual calculations
     */
    function addYears(uint256 timestamp, uint256 years) 
        internal pure returns (uint256) {
        return timestamp + (years * SECONDS_PER_YEAR);
    }
    
    /**
     * @dev Calculates difference in days between two timestamps
     * Use Case: Duration calculations, aging analysis
     */
    function daysBetween(uint256 start, uint256 end) 
        internal pure returns (uint256) {
        if (end <= start) return 0;
        return (end - start) / SECONDS_PER_DAY;
    }
    
    /**
     * @dev Calculates difference in weeks between two timestamps
     * Use Case: Weekly progress tracking, periodic analysis
     */
    function weeksBetween(uint256 start, uint256 end) 
        internal pure returns (uint256) {
        if (end <= start) return 0;
        return (end - start) / SECONDS_PER_WEEK;
    }
    
    /**
     * @dev Calculates difference in months between two timestamps (approximate)
     * Use Case: Monthly subscription tracking, periodic billing
     */
    function monthsBetween(uint256 start, uint256 end) 
        internal pure returns (uint256) {
        if (end <= start) return 0;
        return (end - start) / SECONDS_PER_MONTH;
    }
    
    /**
     * @dev Calculates difference in years between two timestamps
     * Use Case: Age calculations, long-term analysis
     */
    function yearsBetween(uint256 start, uint256 end) 
        internal pure returns (uint256) {
        if (end <= start) return 0;
        return (end - start) / SECONDS_PER_YEAR;
    }
    
    /**
     * @dev Checks if timestamp is in the past
     * Use Case: Deadline checking, validation logic
     */
    function isPast(uint256 timestamp) internal view returns (bool) {
        return timestamp < block.timestamp;
    }
    
    /**
     * @dev Checks if timestamp is in the future
     * Use Case: Scheduling validation, future event checking
     */
    function isFuture(uint256 timestamp) internal view returns (bool) {
        return timestamp > block.timestamp;
    }
    
    /**
     * @dev Checks if current time is within business hours
     * Use Case: Business hours restrictions, automated operations
     */
    function isBusinessHours() internal view returns (bool) {
        uint256 hour = getHour(block.timestamp);
        return hour >= BUSINESS_HOURS_START && hour < BUSINESS_HOURS_END;
    }
    
    /**
     * @dev Checks if timestamp falls within business hours
     * Use Case: Historical business hours validation
     */
    function isBusinessHoursAt(uint256 timestamp) internal pure returns (bool) {
        uint256 hour = getHour(timestamp);
        return hour >= BUSINESS_HOURS_START && hour < BUSINESS_HOURS_END;
    }
    
    /**
     * @dev Gets the hour (0-23) from timestamp
     * Use Case: Time-based logic, hourly restrictions
     */
    function getHour(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp / SECONDS_PER_HOUR) % 24;
    }
    
    /**
     * @dev Gets the day of week (0=Sunday, 6=Saturday) from timestamp
     * Use Case: Weekday restrictions, calendar operations
     */
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256) {
        // Unix epoch (Jan 1, 1970) was a Thursday (day 4)
        return (timestamp / SECONDS_PER_DAY + 4) % 7;
    }
    
    /**
     * @dev Checks if timestamp falls on a weekday (Monday-Friday)
     * Use Case: Business day restrictions, working day validation
     */
    function isWeekday(uint256 timestamp) internal pure returns (bool) {
        uint256 dayOfWeek = getDayOfWeek(timestamp);
        return dayOfWeek >= 1 && dayOfWeek <= 5; // Monday=1, Friday=5
    }
    
    /**
     * @dev Checks if timestamp falls on a weekend (Saturday-Sunday)
     * Use Case: Weekend restrictions, non-business day logic
     */
    function isWeekend(uint256 timestamp) internal pure returns (bool) {
        uint256 dayOfWeek = getDayOfWeek(timestamp);
        return dayOfWeek == 0 || dayOfWeek == 6; // Sunday=0, Saturday=6
    }
    
    /**
     * @dev Rounds timestamp down to start of day (midnight)
     * Use Case: Daily grouping, date normalization
     */
    function startOfDay(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp / SECONDS_PER_DAY) * SECONDS_PER_DAY;
    }
    
    /**
     * @dev Rounds timestamp up to end of day (23:59:59)
     * Use Case: Daily deadline calculations, day boundary logic
     */
    function endOfDay(uint256 timestamp) internal pure returns (uint256) {
        return startOfDay(timestamp) + SECONDS_PER_DAY - 1;
    }
    
    /**
     * @dev Gets the start of the week (Monday 00:00) for given timestamp
     * Use Case: Weekly grouping, week boundary calculations
     */
    function startOfWeek(uint256 timestamp) internal pure returns (uint256) {
        uint256 dayOfWeek = getDayOfWeek(timestamp);
        uint256 daysSinceMonday = (dayOfWeek + 6) % 7; // Adjust so Monday = 0
        return startOfDay(timestamp) - (daysSinceMonday * SECONDS_PER_DAY);
    }
    
    /**
     * @dev Calculates time-weighted average for values over time periods
     * Use Case: TWAP calculations, time-based analytics
     */
    function timeWeightedAverage(
        uint256[] memory values,
        uint256[] memory timestamps,
        uint256 startTime,
        uint256 endTime
    ) internal pure returns (uint256) {
        require(values.length == timestamps.length, "TimeUtils: array length mismatch");
        require(startTime < endTime, "TimeUtils: invalid time range");
        
        if (values.length == 0) return 0;
        
        uint256 totalWeightedValue = 0;
        uint256 totalTime = 0;
        
        for (uint256 i = 0; i < values.length - 1; i++) {
            uint256 currentTime = timestamps[i];
            uint256 nextTime = timestamps[i + 1];
            
            // Clip to our time range
            if (currentTime < startTime) currentTime = startTime;
            if (nextTime > endTime) nextTime = endTime;
            
            if (currentTime < nextTime) {
                uint256 duration = nextTime - currentTime;
                totalWeightedValue += values[i] * duration;
                totalTime += duration;
            }
        }
        
        return totalTime > 0 ? totalWeightedValue / totalTime : 0;
    }
    
    /**
     * @dev Checks if enough time has passed since last action
     * Use Case: Rate limiting, cooldown periods
     */
    function hasCooldownPassed(
        uint256 lastActionTime,
        uint256 cooldownPeriod
    ) internal view returns (bool) {
        return block.timestamp >= lastActionTime + cooldownPeriod;
    }
    
    /**
     * @dev Calculates remaining cooldown time
     * Use Case: UI display, user feedback
     */
    function remainingCooldown(
        uint256 lastActionTime,
        uint256 cooldownPeriod
    ) internal view returns (uint256) {
        uint256 nextAllowedTime = lastActionTime + cooldownPeriod;
        if (block.timestamp >= nextAllowedTime) return 0;
        return nextAllowedTime - block.timestamp;
    }
    
    /**
     * @dev Checks if timestamp is within a specific time window
     * Use Case: Time window validation, periodic access control
     */
    function isWithinTimeWindow(
        uint256 timestamp,
        uint256 windowStart,
        uint256 windowEnd
    ) internal pure returns (bool) {
        return timestamp >= windowStart && timestamp <= windowEnd;
    }
    
    /**
     * @dev Calculates next occurrence of specific hour on specific day of week
     * Use Case: Recurring event scheduling, automated operations
     */
    function nextOccurrence(
        uint256 dayOfWeek,
        uint256 hour,
        uint256 fromTimestamp
    ) internal pure returns (uint256) {
        require(dayOfWeek <= 6, "TimeUtils: invalid day of week");
        require(hour <= 23, "TimeUtils: invalid hour");
        
        uint256 currentDayOfWeek = getDayOfWeek(fromTimestamp);
        uint256 currentHour = getHour(fromTimestamp);
        
        // Calculate days until target day
        uint256 daysUntilTarget;
        if (dayOfWeek > currentDayOfWeek || 
            (dayOfWeek == currentDayOfWeek && hour > currentHour)) {
            daysUntilTarget = dayOfWeek - currentDayOfWeek;
        } else {
            daysUntilTarget = 7 - currentDayOfWeek + dayOfWeek;
        }
        
        // If same day but target hour has passed, move to next week
        if (dayOfWeek == currentDayOfWeek && hour <= currentHour) {
            daysUntilTarget = 7;
        }
        
        uint256 targetDay = startOfDay(fromTimestamp) + (daysUntilTarget * SECONDS_PER_DAY);
        return targetDay + (hour * SECONDS_PER_HOUR);
    }
    
    /**
     * @dev Calculates age in seconds
     * Use Case: Age-based logic, time-dependent behavior
     */
    function age(uint256 birthTimestamp) internal view returns (uint256) {
        return block.timestamp > birthTimestamp ? 
               block.timestamp - birthTimestamp : 0;
    }
    
    /**
     * @dev Checks if minimum age requirement is met
     * Use Case: Age restrictions, maturity-based access control
     */
    function hasMinimumAge(uint256 birthTimestamp, uint256 minimumAge) 
        internal view returns (bool) {
        return age(birthTimestamp) >= minimumAge;
    }
}