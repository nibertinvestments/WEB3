// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DecentralizedTaskScheduler - Automated Task Execution System
 * @dev Schedules and executes tasks automatically based on conditions
 */

contract DecentralizedTaskScheduler {
    struct ScheduledTask {
        uint256 taskId;
        address executor;
        bytes4 functionSelector;
        bytes parameters;
        uint256 executionTime;
        uint256 interval; // 0 for one-time, >0 for recurring
        bool isActive;
        address creator;
    }
    
    mapping(uint256 => ScheduledTask) public tasks;
    uint256 public nextTaskId;
    
    event TaskScheduled(uint256 indexed taskId, address executor, uint256 executionTime);
    event TaskExecuted(uint256 indexed taskId, bool success);
    
    function scheduleTask(
        address executor,
        bytes4 functionSelector,
        bytes calldata parameters,
        uint256 executionTime,
        uint256 interval
    ) external returns (uint256 taskId) {
        require(executionTime > block.timestamp, "Invalid execution time");
        
        taskId = nextTaskId++;
        
        tasks[taskId] = ScheduledTask({
            taskId: taskId,
            executor: executor,
            functionSelector: functionSelector,
            parameters: parameters,
            executionTime: executionTime,
            interval: interval,
            isActive: true,
            creator: msg.sender
        });
        
        emit TaskScheduled(taskId, executor, executionTime);
        return taskId;
    }
    
    function executeTask(uint256 taskId) external returns (bool success) {
        ScheduledTask storage task = tasks[taskId];
        require(task.isActive, "Task not active");
        require(block.timestamp >= task.executionTime, "Too early");
        
        bytes memory callData = abi.encodePacked(task.functionSelector, task.parameters);
        (success,) = task.executor.call(callData);
        
        if (task.interval > 0) {
            task.executionTime += task.interval;
        } else {
            task.isActive = false;
        }
        
        emit TaskExecuted(taskId, success);
        return success;
    }
}