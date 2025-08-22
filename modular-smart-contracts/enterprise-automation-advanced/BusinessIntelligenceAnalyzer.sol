// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title BusinessIntelligenceAnalyzer - Enterprise Analytics Platform
 * @dev Provides advanced business intelligence and analytics
 */

contract BusinessIntelligenceAnalyzer {
    struct KPI {
        uint256 kpiId;
        string name;
        uint256 value;
        uint256 target;
        uint256 period;
        address owner;
        uint256 lastUpdate;
    }
    
    struct Dashboard {
        uint256 dashboardId;
        string name;
        uint256[] kpiIds;
        address owner;
        bool isPublic;
    }
    
    mapping(uint256 => KPI) public kpis;
    mapping(uint256 => Dashboard) public dashboards;
    uint256 public nextKpiId;
    uint256 public nextDashboardId;
    
    event KPICreated(uint256 indexed kpiId, string name);
    event KPIUpdated(uint256 indexed kpiId, uint256 value);
    event DashboardCreated(uint256 indexed dashboardId, string name);
    
    function createKPI(
        string calldata name,
        uint256 target,
        uint256 period
    ) external returns (uint256 kpiId) {
        kpiId = nextKpiId++;
        
        kpis[kpiId] = KPI({
            kpiId: kpiId,
            name: name,
            value: 0,
            target: target,
            period: period,
            owner: msg.sender,
            lastUpdate: block.timestamp
        });
        
        emit KPICreated(kpiId, name);
        return kpiId;
    }
    
    function updateKPI(uint256 kpiId, uint256 value) external {
        KPI storage kpi = kpis[kpiId];
        require(kpi.owner == msg.sender, "Not authorized");
        
        kpi.value = value;
        kpi.lastUpdate = block.timestamp;
        
        emit KPIUpdated(kpiId, value);
    }
    
    function createDashboard(
        string calldata name,
        uint256[] calldata kpiIds,
        bool isPublic
    ) external returns (uint256 dashboardId) {
        dashboardId = nextDashboardId++;
        
        dashboards[dashboardId] = Dashboard({
            dashboardId: dashboardId,
            name: name,
            kpiIds: kpiIds,
            owner: msg.sender,
            isPublic: isPublic
        });
        
        emit DashboardCreated(dashboardId, name);
        return dashboardId;
    }
}