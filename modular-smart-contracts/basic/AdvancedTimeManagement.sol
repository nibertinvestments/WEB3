// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AdvancedTimeManagement - Sophisticated Time-Based Operations
 * @dev Comprehensive time utilities for complex scheduling and temporal logic
 * 
 * AOPB COMPATIBILITY: ✅ Fully compatible with Advanced Opportunity Blockchain
 * EVM COMPATIBILITY: ✅ Ethereum, Polygon, BSC, Arbitrum, Optimism, Base
 * 
 * USE CASES:
 * 1. Complex vesting schedules with milestone-based unlocks
 * 2. Multi-timezone business hours for global DeFi protocols
 * 3. Automated recurring payment systems with smart scheduling
 * 4. Time-weighted average price (TWAP) calculations
 * 5. Temporal access control with dynamic permissions
 * 6. Compound interest calculations with variable rates
 * 7. Subscription management with automatic renewals
 * 8. Event-driven time locks with conditional releases
 * 
 * @author Nibert Investments - Advanced Opportunity Blockchain Team
 */
contract AdvancedTimeManagement {
    uint256 constant PRECISION = 1e18;
    uint256 constant SECONDS_PER_DAY = 86400;
    uint256 constant SECONDS_PER_HOUR = 3600;
    uint256 constant DAYS_PER_YEAR = 365;
    
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 startTime;
        uint256 duration;
        uint256 cliffPeriod;
        uint256 releasedAmount;
        uint256[] milestones;
        uint256[] milestoneAmounts;
        bool isActive;
    }
    
    struct RecurringPayment {
        address payer;
        address payee;
        uint256 amount;
        uint256 interval;
        uint256 nextPayment;
        uint256 maxPayments;
        uint256 paymentCount;
        bool isActive;
    }
    
    struct BusinessHours {
        uint256 timezone; // UTC offset in hours * 100 (e.g., 500 = +5:00)
        uint256 openHour;
        uint256 closeHour;
        uint256 workDays; // Bitmap: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64
        uint256[] holidays; // Array of timestamps
        bool isActive;
    }
    
    struct TimeWeightedPrice {
        uint256 cumulativePrice;
        uint256 lastPrice;
        uint256 lastUpdateTime;
        uint256 duration;
        bool isInitialized;
    }
    
    event VestingCreated(bytes32 indexed vestingId, address indexed beneficiary, uint256 totalAmount);
    event VestingReleased(bytes32 indexed vestingId, uint256 amount, uint256 timestamp);
    event RecurringPaymentExecuted(bytes32 indexed paymentId, uint256 amount, uint256 paymentNumber);
    event BusinessHoursUpdated(bytes32 indexed entityId, uint256 timezone, uint256 openHour, uint256 closeHour);
    event TWAPUpdated(bytes32 indexed priceId, uint256 newPrice, uint256 twap);
    
    mapping(bytes32 => VestingSchedule) public vestingSchedules;
    mapping(bytes32 => RecurringPayment) public recurringPayments;
    mapping(bytes32 => BusinessHours) public businessHours;
    mapping(bytes32 => TimeWeightedPrice) public twapData;
    mapping(address => uint256) public userTimezones;
    
    /**
     * @notice Create complex vesting schedule with milestones
     */
    function createVestingSchedule(
        bytes32 vestingId,
        uint256 totalAmount,
        uint256 duration,
        uint256 cliffPeriod,
        uint256[] calldata milestones,
        uint256[] calldata milestoneAmounts
    ) external {
        require(totalAmount > 0, "Invalid amount");
        require(duration > 0, "Invalid duration");
        require(milestones.length == milestoneAmounts.length, "Array length mismatch");
        
        vestingSchedules[vestingId] = VestingSchedule({
            totalAmount: totalAmount,
            startTime: block.timestamp,
            duration: duration,
            cliffPeriod: cliffPeriod,
            releasedAmount: 0,
            milestones: milestones,
            milestoneAmounts: milestoneAmounts,
            isActive: true
        });
        
        emit VestingCreated(vestingId, msg.sender, totalAmount);
    }
    
    /**
     * @notice Calculate vested amount including milestone bonuses
     */
    function calculateVestedAmount(bytes32 vestingId) external view returns (uint256 vestedAmount) {
        VestingSchedule memory schedule = vestingSchedules[vestingId];
        
        if (!schedule.isActive || block.timestamp < schedule.startTime + schedule.cliffPeriod) {
            return 0;
        }
        
        uint256 timeElapsed = block.timestamp - schedule.startTime;
        if (timeElapsed >= schedule.duration) {
            vestedAmount = schedule.totalAmount;
        } else {
            vestedAmount = (schedule.totalAmount * timeElapsed) / schedule.duration;
        }
        
        // Add milestone bonuses
        for (uint256 i = 0; i < schedule.milestones.length; i++) {
            if (block.timestamp >= schedule.startTime + schedule.milestones[i]) {
                vestedAmount += schedule.milestoneAmounts[i];
            }
        }
    }
    
    /**
     * @notice Set up recurring payment schedule
     */
    function setupRecurringPayment(
        bytes32 paymentId,
        address payee,
        uint256 amount,
        uint256 interval,
        uint256 maxPayments
    ) external {
        require(payee != address(0), "Invalid payee");
        require(amount > 0, "Invalid amount");
        require(interval > 0, "Invalid interval");
        
        recurringPayments[paymentId] = RecurringPayment({
            payer: msg.sender,
            payee: payee,
            amount: amount,
            interval: interval,
            nextPayment: block.timestamp + interval,
            maxPayments: maxPayments,
            paymentCount: 0,
            isActive: true
        });
    }
    
    /**
     * @notice Check if current time is within business hours
     */
    function isBusinessHours(bytes32 entityId) external view returns (bool) {
        BusinessHours memory hours = businessHours[entityId];
        if (!hours.isActive) return false;
        
        uint256 currentTime = block.timestamp;
        uint256 adjustedTime = currentTime + (hours.timezone * 36); // Convert to entity timezone
        
        uint256 dayOfWeek = ((adjustedTime / SECONDS_PER_DAY) + 4) % 7; // Thursday = 0
        uint256 hourOfDay = (adjustedTime % SECONDS_PER_DAY) / SECONDS_PER_HOUR;
        
        // Check if it's a working day
        if ((hours.workDays & (1 << dayOfWeek)) == 0) return false;
        
        // Check if it's within working hours
        if (hourOfDay < hours.openHour || hourOfDay >= hours.closeHour) return false;
        
        // Check if it's a holiday
        for (uint256 i = 0; i < hours.holidays.length; i++) {
            if (isSameDay(currentTime, hours.holidays[i])) return false;
        }
        
        return true;
    }
    
    /**
     * @notice Update time-weighted average price
     */
    function updateTWAP(bytes32 priceId, uint256 newPrice) external returns (uint256 twap) {
        TimeWeightedPrice storage twapInfo = twapData[priceId];
        
        if (!twapInfo.isInitialized) {
            twapInfo.cumulativePrice = newPrice * PRECISION;
            twapInfo.lastPrice = newPrice;
            twapInfo.lastUpdateTime = block.timestamp;
            twapInfo.duration = 0;
            twapInfo.isInitialized = true;
            return newPrice;
        }
        
        uint256 timeElapsed = block.timestamp - twapInfo.lastUpdateTime;
        twapInfo.cumulativePrice += twapInfo.lastPrice * timeElapsed * PRECISION;
        twapInfo.duration += timeElapsed;
        
        twap = twapInfo.cumulativePrice / (twapInfo.duration * PRECISION);
        
        twapInfo.lastPrice = newPrice;
        twapInfo.lastUpdateTime = block.timestamp;
        
        emit TWAPUpdated(priceId, newPrice, twap);
    }
    
    /**
     * @notice Calculate compound interest with time-based parameters
     */
    function calculateCompoundInterest(
        uint256 principal,
        uint256 annualRate,
        uint256 compoundingFrequency,
        uint256 timeInSeconds
    ) external pure returns (uint256 finalAmount) {
        uint256 rate = (annualRate * PRECISION) / (compoundingFrequency * 100);
        uint256 periods = (timeInSeconds * compoundingFrequency) / (DAYS_PER_YEAR * SECONDS_PER_DAY);
        
        finalAmount = principal;
        for (uint256 i = 0; i < periods; i++) {
            finalAmount = (finalAmount * (PRECISION + rate)) / PRECISION;
        }
    }
    
    /**
     * @notice Get next business day after given timestamp
     */
    function getNextBusinessDay(bytes32 entityId, uint256 timestamp) external view returns (uint256) {
        BusinessHours memory hours = businessHours[entityId];
        
        uint256 currentDay = timestamp;
        for (uint256 i = 0; i < 7; i++) { // Max 7 days to find next business day
            currentDay += SECONDS_PER_DAY;
            uint256 dayOfWeek = ((currentDay / SECONDS_PER_DAY) + 4) % 7;
            
            if ((hours.workDays & (1 << dayOfWeek)) != 0) {
                // Check if it's not a holiday
                bool isHoliday = false;
                for (uint256 j = 0; j < hours.holidays.length; j++) {
                    if (isSameDay(currentDay, hours.holidays[j])) {
                        isHoliday = true;
                        break;
                    }
                }
                
                if (!isHoliday) {
                    return currentDay;
                }
            }
        }
        
        return currentDay; // Fallback
    }
    
    /**
     * @notice Calculate time until next milestone
     */
    function timeToNextMilestone(bytes32 vestingId) external view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[vestingId];
        
        for (uint256 i = 0; i < schedule.milestones.length; i++) {
            uint256 milestoneTime = schedule.startTime + schedule.milestones[i];
            if (block.timestamp < milestoneTime) {
                return milestoneTime - block.timestamp;
            }
        }
        
        return 0; // No upcoming milestones
    }
    
    /**
     * @notice Check if subscription is due for renewal
     */
    function isSubscriptionDue(bytes32 paymentId) external view returns (bool) {
        RecurringPayment memory payment = recurringPayments[paymentId];
        return payment.isActive && 
               block.timestamp >= payment.nextPayment &&
               payment.paymentCount < payment.maxPayments;
    }
    
    function configureBusinessHours(
        bytes32 entityId,
        uint256 timezone,
        uint256 openHour,
        uint256 closeHour,
        uint256 workDays,
        uint256[] calldata holidays
    ) external {
        require(openHour < 24 && closeHour < 24, "Invalid hours");
        require(openHour < closeHour, "Open must be before close");
        
        businessHours[entityId] = BusinessHours({
            timezone: timezone,
            openHour: openHour,
            closeHour: closeHour,
            workDays: workDays,
            holidays: holidays,
            isActive: true
        });
        
        emit BusinessHoursUpdated(entityId, timezone, openHour, closeHour);
    }
    
    function isSameDay(uint256 timestamp1, uint256 timestamp2) internal pure returns (bool) {
        return (timestamp1 / SECONDS_PER_DAY) == (timestamp2 / SECONDS_PER_DAY);
    }
}