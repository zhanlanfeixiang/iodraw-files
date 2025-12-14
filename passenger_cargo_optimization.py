#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
客货一体化农村公交协同优化系统
Integrated Passenger-Cargo Rural Transportation Optimization System

基于大语言模型AI协同的乘客-配送客户协同优化
AI-Enhanced Collaborative Optimization for Passengers and Delivery Customers

数学模型 (Mathematical Model):
==================================

决策变量 (Decision Variables):
- x_ij: 车辆i是否服务节点j (二进制变量)
- t_ij: 车辆i到达节点j的时间
- l_ij: 车辆i在节点j的载客量
- c_ij: 车辆i在节点j的载货量

目标函数 (Objective Functions):
1. 最小化总成本 (Minimize Total Cost):
   min Z1 = α₁·C_transport + α₂·C_time + α₃·C_waiting

2. 最大化服务质量 (Maximize Service Quality):
   max Z2 = β₁·S_passenger + β₂·S_cargo + β₃·S_coordination

约束条件 (Constraints):
1. 车辆容量约束: l_ij + c_ij ≤ Q_i
2. 时间窗约束: e_j ≤ t_ij ≤ l_j
3. 需求满足约束: Σ_i x_ij = 1, ∀j
4. 流量守恒约束: Σ_j x_ij = Σ_k x_ik, ∀i
5. 乘客舒适度约束: l_ij/Q_i ≥ threshold_passenger
6. 货物完整性约束: c_ij不超过专用货物区域
"""

import numpy as np
import pandas as pd
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass, field
from datetime import datetime, timedelta
import json
import random
from enum import Enum
import matplotlib.pyplot as plt
import seaborn as sns


class NodeType(Enum):
    """节点类型"""
    DEPOT = "depot"  # 车站
    PASSENGER = "passenger"  # 乘客节点
    CARGO = "cargo"  # 货物节点
    MIXED = "mixed"  # 混合节点


@dataclass
class Node:
    """节点信息"""
    id: int
    name: str
    node_type: NodeType
    location: Tuple[float, float]  # (经度, 纬度)
    demand_passenger: int = 0  # 乘客需求
    demand_cargo: float = 0.0  # 货物需求 (kg)
    time_window: Tuple[int, int] = (0, 1440)  # 时间窗 (分钟)
    service_time: int = 5  # 服务时间 (分钟)
    priority: float = 1.0  # 优先级


@dataclass
class Vehicle:
    """车辆信息"""
    id: int
    name: str
    capacity_passenger: int  # 乘客容量
    capacity_cargo: float  # 货物容量 (kg)
    speed: float = 60.0  # 平均速度 (km/h)
    cost_per_km: float = 2.0  # 每公里成本
    cost_per_hour: float = 50.0  # 每小时成本
    start_location: Tuple[float, float] = (0.0, 0.0)


@dataclass
class Route:
    """路线信息"""
    vehicle_id: int
    nodes: List[int] = field(default_factory=list)
    arrival_times: List[float] = field(default_factory=list)
    passenger_load: List[int] = field(default_factory=list)
    cargo_load: List[float] = field(default_factory=list)
    total_distance: float = 0.0
    total_time: float = 0.0
    total_cost: float = 0.0


class AICoordinationEngine:
    """
    AI协同引擎
    模拟大语言模型进行乘客-货物协调决策
    """
    
    def __init__(self, alpha: float = 0.6, beta: float = 0.4):
        """
        初始化AI协同引擎
        
        Args:
            alpha: 乘客优先权重
            beta: 货物优先权重
        """
        self.alpha = alpha  # 乘客优先权重
        self.beta = beta    # 货物优先权重
        self.decision_history = []
    
    def evaluate_coordination_score(self, 
                                     passenger_satisfaction: float,
                                     cargo_satisfaction: float,
                                     route_efficiency: float) -> float:
        """
        评估协调得分
        
        Args:
            passenger_satisfaction: 乘客满意度 [0, 1]
            cargo_satisfaction: 货物满意度 [0, 1]
            route_efficiency: 路线效率 [0, 1]
            
        Returns:
            协调得分
        """
        score = (self.alpha * passenger_satisfaction + 
                 self.beta * cargo_satisfaction +
                 0.2 * route_efficiency)
        return score
    
    def suggest_priority_adjustment(self, 
                                    passenger_wait_time: float,
                                    cargo_urgency: float) -> Dict[str, float]:
        """
        建议优先级调整 (模拟LLM决策)
        
        Args:
            passenger_wait_time: 乘客等待时间
            cargo_urgency: 货物紧急度
            
        Returns:
            调整后的权重
        """
        # 模拟AI智能决策
        if passenger_wait_time > 30:  # 乘客等待超过30分钟
            alpha_adjusted = min(0.8, self.alpha + 0.2)
            beta_adjusted = 1.0 - alpha_adjusted
        elif cargo_urgency > 0.8:  # 货物非常紧急
            beta_adjusted = min(0.6, self.beta + 0.2)
            alpha_adjusted = 1.0 - beta_adjusted
        else:
            alpha_adjusted = self.alpha
            beta_adjusted = self.beta
        
        decision = {
            'alpha': alpha_adjusted,
            'beta': beta_adjusted,
            'reasoning': self._generate_reasoning(passenger_wait_time, cargo_urgency)
        }
        
        self.decision_history.append(decision)
        return decision
    
    def _generate_reasoning(self, passenger_wait: float, cargo_urgency: float) -> str:
        """生成决策推理 (模拟LLM生成解释)"""
        if passenger_wait > 30:
            return f"乘客等待时间({passenger_wait:.1f}分钟)过长，提高乘客优先级以改善用户体验"
        elif cargo_urgency > 0.8:
            return f"货物紧急度({cargo_urgency:.2f})较高，需要优先配送以保证服务质量"
        else:
            return "当前状态平衡，维持标准优先级配置"


class PassengerCargoOptimizer:
    """
    客货协同优化器
    """
    
    def __init__(self, 
                 nodes: List[Node],
                 vehicles: List[Vehicle],
                 ai_engine: Optional[AICoordinationEngine] = None):
        """
        初始化优化器
        
        Args:
            nodes: 节点列表
            vehicles: 车辆列表
            ai_engine: AI协同引擎
        """
        self.nodes = nodes
        self.vehicles = vehicles
        self.ai_engine = ai_engine or AICoordinationEngine()
        self.distance_matrix = self._calculate_distance_matrix()
        self.time_matrix = self._calculate_time_matrix()
        
    def _calculate_distance_matrix(self) -> np.ndarray:
        """计算节点间距离矩阵"""
        n = len(self.nodes)
        distances = np.zeros((n, n))
        
        for i in range(n):
            for j in range(n):
                if i != j:
                    loc_i = self.nodes[i].location
                    loc_j = self.nodes[j].location
                    # 使用欧氏距离近似 (实际应使用Haversine公式)
                    distances[i][j] = np.sqrt(
                        (loc_i[0] - loc_j[0])**2 + (loc_i[1] - loc_j[1])**2
                    ) * 111  # 转换为公里
        
        return distances
    
    def _calculate_time_matrix(self) -> np.ndarray:
        """计算节点间时间矩阵 (分钟)"""
        avg_speed = np.mean([v.speed for v in self.vehicles])
        return (self.distance_matrix / avg_speed) * 60  # 转换为分钟
    
    def calculate_route_cost(self, route: Route, vehicle: Vehicle) -> float:
        """
        计算路线成本
        
        Args:
            route: 路线
            vehicle: 车辆
            
        Returns:
            总成本
        """
        distance_cost = route.total_distance * vehicle.cost_per_km
        time_cost = (route.total_time / 60) * vehicle.cost_per_hour
        waiting_cost = sum([
            max(0, self.nodes[node_id].time_window[0] - arrival_time) * 0.5
            for node_id, arrival_time in zip(route.nodes, route.arrival_times)
        ])
        
        return distance_cost + time_cost + waiting_cost
    
    def calculate_passenger_satisfaction(self, route: Route) -> float:
        """
        计算乘客满意度
        
        Args:
            route: 路线
            
        Returns:
            满意度 [0, 1]
        """
        satisfaction_scores = []
        
        for i, node_id in enumerate(route.nodes):
            node = self.nodes[node_id]
            if node.demand_passenger > 0:
                # 时间窗满足度
                arrival_time = route.arrival_times[i]
                time_window_satisfaction = 1.0 if (
                    node.time_window[0] <= arrival_time <= node.time_window[1]
                ) else 0.5
                
                # 拥挤度
                vehicle = self.vehicles[route.vehicle_id]
                crowding = route.passenger_load[i] / vehicle.capacity_passenger
                crowding_satisfaction = max(0, 1.0 - crowding * 0.8)
                
                # 综合满意度
                satisfaction = 0.6 * time_window_satisfaction + 0.4 * crowding_satisfaction
                satisfaction_scores.append(satisfaction)
        
        return np.mean(satisfaction_scores) if satisfaction_scores else 1.0
    
    def calculate_cargo_satisfaction(self, route: Route) -> float:
        """
        计算货物配送满意度
        
        Args:
            route: 路线
            
        Returns:
            满意度 [0, 1]
        """
        satisfaction_scores = []
        
        for i, node_id in enumerate(route.nodes):
            node = self.nodes[node_id]
            if node.demand_cargo > 0:
                # 时间窗满足度
                arrival_time = route.arrival_times[i]
                time_window_satisfaction = 1.0 if (
                    node.time_window[0] <= arrival_time <= node.time_window[1]
                ) else 0.3
                
                # 货物完整性 (装载率不应过高)
                vehicle = self.vehicles[route.vehicle_id]
                cargo_ratio = route.cargo_load[i] / vehicle.capacity_cargo
                integrity_satisfaction = 1.0 if cargo_ratio < 0.8 else 0.7
                
                satisfaction = 0.7 * time_window_satisfaction + 0.3 * integrity_satisfaction
                satisfaction_scores.append(satisfaction)
        
        return np.mean(satisfaction_scores) if satisfaction_scores else 1.0
    
    def construct_initial_solution(self) -> List[Route]:
        """
        构造初始解 (最近邻算法)
        
        Returns:
            初始路线方案
        """
        routes = []
        unvisited = set(range(1, len(self.nodes)))  # 排除depot
        
        for vehicle in self.vehicles:
            route = Route(vehicle_id=vehicle.id)
            current_node = 0  # 从depot开始
            current_time = 0.0
            passenger_load = 0
            cargo_load = 0.0
            total_distance = 0.0
            
            while unvisited:
                # 找最近的可行节点
                best_node = None
                best_distance = float('inf')
                
                for node_id in unvisited:
                    node = self.nodes[node_id]
                    distance = self.distance_matrix[current_node][node_id]
                    travel_time = self.time_matrix[current_node][node_id]
                    arrival_time = current_time + travel_time
                    
                    # 检查容量和时间窗约束
                    new_passenger_load = passenger_load + node.demand_passenger
                    new_cargo_load = cargo_load + node.demand_cargo
                    
                    if (new_passenger_load <= vehicle.capacity_passenger and
                        new_cargo_load <= vehicle.capacity_cargo and
                        arrival_time <= node.time_window[1] and
                        distance < best_distance):
                        best_node = node_id
                        best_distance = distance
                
                if best_node is None:
                    break  # 无可行节点，结束此车辆路线
                
                # 更新路线
                node = self.nodes[best_node]
                travel_time = self.time_matrix[current_node][best_node]
                arrival_time = max(current_time + travel_time, node.time_window[0])
                
                passenger_load += node.demand_passenger
                cargo_load += node.demand_cargo
                total_distance += self.distance_matrix[current_node][best_node]
                
                route.nodes.append(best_node)
                route.arrival_times.append(arrival_time)
                route.passenger_load.append(passenger_load)
                route.cargo_load.append(cargo_load)
                
                current_node = best_node
                current_time = arrival_time + node.service_time
                unvisited.remove(best_node)
            
            # 返回depot
            if route.nodes:
                total_distance += self.distance_matrix[current_node][0]
                route.total_distance = total_distance
                route.total_time = current_time
                route.total_cost = self.calculate_route_cost(route, vehicle)
                routes.append(route)
        
        return routes
    
    def optimize_with_ai_coordination(self, 
                                     max_iterations: int = 100,
                                     temperature: float = 1000.0,
                                     cooling_rate: float = 0.95) -> List[Route]:
        """
        使用AI协同的模拟退火算法优化
        
        Args:
            max_iterations: 最大迭代次数
            temperature: 初始温度
            cooling_rate: 冷却率
            
        Returns:
            优化后的路线方案
        """
        # 构造初始解
        current_solution = self.construct_initial_solution()
        best_solution = current_solution
        current_cost = sum(route.total_cost for route in current_solution)
        best_cost = current_cost
        
        print(f"初始解成本: {current_cost:.2f}")
        
        for iteration in range(max_iterations):
            # AI协同决策
            avg_passenger_wait = self._calculate_avg_wait_time(current_solution, NodeType.PASSENGER)
            avg_cargo_urgency = self._calculate_avg_urgency(current_solution, NodeType.CARGO)
            
            ai_decision = self.ai_engine.suggest_priority_adjustment(
                avg_passenger_wait, avg_cargo_urgency
            )
            
            # 生成邻域解
            new_solution = self._generate_neighbor(current_solution)
            new_cost = self._calculate_weighted_cost(new_solution, ai_decision)
            
            # 接受准则
            delta = new_cost - current_cost
            if delta < 0 or random.random() < np.exp(-delta / temperature):
                current_solution = new_solution
                current_cost = new_cost
                
                if current_cost < best_cost:
                    best_solution = new_solution
                    best_cost = current_cost
                    print(f"迭代 {iteration}: 找到更优解，成本 = {best_cost:.2f}, {ai_decision['reasoning']}")
            
            temperature *= cooling_rate
        
        print(f"\n最优解成本: {best_cost:.2f}")
        return best_solution
    
    def _calculate_avg_wait_time(self, routes: List[Route], node_type: NodeType) -> float:
        """计算平均等待时间"""
        wait_times = []
        for route in routes:
            for i, node_id in enumerate(route.nodes):
                node = self.nodes[node_id]
                if node.node_type == node_type or node.node_type == NodeType.MIXED:
                    arrival = route.arrival_times[i]
                    earliest = node.time_window[0]
                    wait_times.append(max(0, arrival - earliest))
        return np.mean(wait_times) if wait_times else 0.0
    
    def _calculate_avg_urgency(self, routes: List[Route], node_type: NodeType) -> float:
        """计算平均紧急度"""
        urgencies = []
        for route in routes:
            for i, node_id in enumerate(route.nodes):
                node = self.nodes[node_id]
                if node.node_type == node_type or node.node_type == NodeType.MIXED:
                    urgencies.append(node.priority)
        return np.mean(urgencies) if urgencies else 0.5
    
    def _calculate_weighted_cost(self, routes: List[Route], ai_decision: Dict) -> float:
        """计算加权成本"""
        total_cost = 0.0
        alpha = ai_decision['alpha']
        beta = ai_decision['beta']
        
        for route in routes:
            vehicle = self.vehicles[route.vehicle_id]
            base_cost = self.calculate_route_cost(route, vehicle)
            passenger_penalty = (1.0 - self.calculate_passenger_satisfaction(route)) * 1000
            cargo_penalty = (1.0 - self.calculate_cargo_satisfaction(route)) * 800
            
            weighted_cost = base_cost + alpha * passenger_penalty + beta * cargo_penalty
            total_cost += weighted_cost
        
        return total_cost
    
    def _generate_neighbor(self, routes: List[Route]) -> List[Route]:
        """生成邻域解"""
        new_routes = [self._copy_route(route) for route in routes]
        
        if not new_routes or not any(route.nodes for route in new_routes):
            return new_routes
        
        # 随机选择操作
        operation = random.choice(['swap', 'insert', 'reverse'])
        
        # 选择一条有节点的路线
        valid_routes = [r for r in new_routes if len(r.nodes) > 1]
        if not valid_routes:
            return new_routes
        
        route_idx = random.randint(0, len(valid_routes) - 1)
        route = valid_routes[route_idx]
        
        if operation == 'swap' and len(route.nodes) >= 2:
            i, j = random.sample(range(len(route.nodes)), 2)
            route.nodes[i], route.nodes[j] = route.nodes[j], route.nodes[i]
        elif operation == 'insert' and len(route.nodes) >= 2:
            i = random.randint(0, len(route.nodes) - 1)
            j = random.randint(0, len(route.nodes) - 1)
            node = route.nodes.pop(i)
            route.nodes.insert(j, node)
        elif operation == 'reverse' and len(route.nodes) >= 2:
            i = random.randint(0, len(route.nodes) - 2)
            j = random.randint(i + 1, len(route.nodes))
            route.nodes[i:j] = reversed(route.nodes[i:j])
        
        # 重新计算路线信息
        self._recalculate_route(route)
        
        return new_routes
    
    def _copy_route(self, route: Route) -> Route:
        """复制路线"""
        return Route(
            vehicle_id=route.vehicle_id,
            nodes=route.nodes.copy(),
            arrival_times=route.arrival_times.copy(),
            passenger_load=route.passenger_load.copy(),
            cargo_load=route.cargo_load.copy(),
            total_distance=route.total_distance,
            total_time=route.total_time,
            total_cost=route.total_cost
        )
    
    def _recalculate_route(self, route: Route):
        """重新计算路线信息"""
        if not route.nodes:
            return
        
        vehicle = self.vehicles[route.vehicle_id]
        current_node = 0
        current_time = 0.0
        passenger_load = 0
        cargo_load = 0.0
        total_distance = 0.0
        
        route.arrival_times = []
        route.passenger_load = []
        route.cargo_load = []
        
        for node_id in route.nodes:
            node = self.nodes[node_id]
            travel_time = self.time_matrix[current_node][node_id]
            arrival_time = max(current_time + travel_time, node.time_window[0])
            
            passenger_load += node.demand_passenger
            cargo_load += node.demand_cargo
            total_distance += self.distance_matrix[current_node][node_id]
            
            route.arrival_times.append(arrival_time)
            route.passenger_load.append(passenger_load)
            route.cargo_load.append(cargo_load)
            
            current_node = node_id
            current_time = arrival_time + node.service_time
        
        total_distance += self.distance_matrix[current_node][0]
        route.total_distance = total_distance
        route.total_time = current_time
        route.total_cost = self.calculate_route_cost(route, vehicle)


class Visualizer:
    """可视化工具"""
    
    @staticmethod
    def plot_routes(nodes: List[Node], routes: List[Route], 
                    filename: str = 'routes_visualization.png'):
        """
        绘制路线图
        
        Args:
            nodes: 节点列表
            routes: 路线列表
            filename: 输出文件名
        """
        plt.figure(figsize=(12, 8))
        
        # 绘制节点
        for node in nodes:
            if node.node_type == NodeType.DEPOT:
                plt.scatter(node.location[0], node.location[1], 
                           c='red', s=200, marker='s', label='车站' if node.id == 0 else '')
            elif node.node_type == NodeType.PASSENGER:
                plt.scatter(node.location[0], node.location[1], 
                           c='blue', s=100, marker='o', alpha=0.6)
            elif node.node_type == NodeType.CARGO:
                plt.scatter(node.location[0], node.location[1], 
                           c='green', s=100, marker='^', alpha=0.6)
            else:  # MIXED
                plt.scatter(node.location[0], node.location[1], 
                           c='purple', s=100, marker='D', alpha=0.6)
            
            plt.text(node.location[0], node.location[1], f'  {node.id}', 
                    fontsize=8)
        
        # 绘制路线
        colors = plt.cm.rainbow(np.linspace(0, 1, len(routes)))
        for route, color in zip(routes, colors):
            if not route.nodes:
                continue
            
            # 从depot开始
            prev_loc = nodes[0].location
            for node_id in route.nodes:
                node_loc = nodes[node_id].location
                plt.plot([prev_loc[0], node_loc[0]], 
                        [prev_loc[1], node_loc[1]], 
                        c=color, alpha=0.5, linewidth=2)
                plt.arrow(prev_loc[0], prev_loc[1],
                         node_loc[0] - prev_loc[0], 
                         node_loc[1] - prev_loc[1],
                         head_width=0.3, head_length=0.2, 
                         fc=color, ec=color, alpha=0.3)
                prev_loc = node_loc
            
            # 返回depot
            depot_loc = nodes[0].location
            plt.plot([prev_loc[0], depot_loc[0]], 
                    [prev_loc[1], depot_loc[1]], 
                    c=color, alpha=0.5, linewidth=2, 
                    label=f'车辆{route.vehicle_id}')
        
        plt.xlabel('经度')
        plt.ylabel('纬度')
        plt.title('客货一体化农村公交路线优化结果')
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"路线图已保存至: {filename}")
    
    @staticmethod
    def plot_performance_metrics(routes: List[Route], optimizer: PassengerCargoOptimizer,
                                 filename: str = 'performance_metrics.png'):
        """
        绘制性能指标
        
        Args:
            routes: 路线列表
            optimizer: 优化器
            filename: 输出文件名
        """
        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        
        # 成本分布
        costs = [route.total_cost for route in routes]
        axes[0, 0].bar(range(len(costs)), costs, color='steelblue')
        axes[0, 0].set_xlabel('车辆ID')
        axes[0, 0].set_ylabel('总成本')
        axes[0, 0].set_title('各车辆路线成本')
        axes[0, 0].grid(True, alpha=0.3)
        
        # 满意度对比
        passenger_sat = [optimizer.calculate_passenger_satisfaction(route) for route in routes]
        cargo_sat = [optimizer.calculate_cargo_satisfaction(route) for route in routes]
        x = np.arange(len(routes))
        width = 0.35
        axes[0, 1].bar(x - width/2, passenger_sat, width, label='乘客满意度', color='blue', alpha=0.7)
        axes[0, 1].bar(x + width/2, cargo_sat, width, label='货物满意度', color='green', alpha=0.7)
        axes[0, 1].set_xlabel('车辆ID')
        axes[0, 1].set_ylabel('满意度')
        axes[0, 1].set_title('乘客与货物满意度对比')
        axes[0, 1].legend()
        axes[0, 1].grid(True, alpha=0.3)
        
        # 载客量变化
        for route in routes:
            if route.passenger_load:
                axes[1, 0].plot(route.passenger_load, marker='o', 
                               label=f'车辆{route.vehicle_id}')
        axes[1, 0].set_xlabel('节点序号')
        axes[1, 0].set_ylabel('载客量')
        axes[1, 0].set_title('各车辆载客量变化')
        axes[1, 0].legend()
        axes[1, 0].grid(True, alpha=0.3)
        
        # 载货量变化
        for route in routes:
            if route.cargo_load:
                axes[1, 1].plot(route.cargo_load, marker='s', 
                               label=f'车辆{route.vehicle_id}')
        axes[1, 1].set_xlabel('节点序号')
        axes[1, 1].set_ylabel('载货量 (kg)')
        axes[1, 1].set_title('各车辆载货量变化')
        axes[1, 1].legend()
        axes[1, 1].grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"性能指标图已保存至: {filename}")


def generate_sample_data(num_nodes: int = 20, num_vehicles: int = 3) -> Tuple[List[Node], List[Vehicle]]:
    """
    生成示例数据
    
    Args:
        num_nodes: 节点数量
        num_vehicles: 车辆数量
        
    Returns:
        节点列表和车辆列表
    """
    random.seed(42)
    np.random.seed(42)
    
    nodes = []
    
    # Depot
    nodes.append(Node(
        id=0,
        name="中心站",
        node_type=NodeType.DEPOT,
        location=(0.0, 0.0)
    ))
    
    # 生成其他节点
    for i in range(1, num_nodes + 1):
        node_types = [NodeType.PASSENGER, NodeType.CARGO, NodeType.MIXED]
        node_type = random.choice(node_types)
        
        demand_passenger = random.randint(1, 5) if node_type in [NodeType.PASSENGER, NodeType.MIXED] else 0
        demand_cargo = random.uniform(10, 50) if node_type in [NodeType.CARGO, NodeType.MIXED] else 0.0
        
        # 时间窗
        earliest = random.randint(0, 600)  # 0-10小时
        latest = earliest + random.randint(120, 360)  # +2-6小时
        
        nodes.append(Node(
            id=i,
            name=f"节点{i}",
            node_type=node_type,
            location=(random.uniform(-10, 10), random.uniform(-10, 10)),
            demand_passenger=demand_passenger,
            demand_cargo=demand_cargo,
            time_window=(earliest, min(latest, 1440)),
            service_time=random.randint(5, 15),
            priority=random.uniform(0.5, 1.0)
        ))
    
    # 生成车辆
    vehicles = []
    for i in range(num_vehicles):
        vehicles.append(Vehicle(
            id=i,
            name=f"车辆{i+1}",
            capacity_passenger=random.randint(15, 30),
            capacity_cargo=random.uniform(200, 400),
            speed=random.uniform(40, 60),
            cost_per_km=random.uniform(1.5, 2.5),
            cost_per_hour=random.uniform(40, 60)
        ))
    
    return nodes, vehicles


def main():
    """主函数 - 示例使用"""
    print("=" * 80)
    print("客货一体化农村公交协同优化系统")
    print("Integrated Passenger-Cargo Rural Transportation Optimization System")
    print("基于大语言模型AI协同的乘客-配送客户协同优化")
    print("=" * 80)
    print()
    
    # 生成示例数据
    print("1. 生成示例数据...")
    nodes, vehicles = generate_sample_data(num_nodes=20, num_vehicles=3)
    
    print(f"   - 节点数量: {len(nodes)} (包括1个depot)")
    print(f"   - 车辆数量: {len(vehicles)}")
    print(f"   - 乘客节点: {sum(1 for n in nodes if n.node_type == NodeType.PASSENGER)}")
    print(f"   - 货物节点: {sum(1 for n in nodes if n.node_type == NodeType.CARGO)}")
    print(f"   - 混合节点: {sum(1 for n in nodes if n.node_type == NodeType.MIXED)}")
    print()
    
    # 初始化AI协同引擎
    print("2. 初始化AI协同引擎...")
    ai_engine = AICoordinationEngine(alpha=0.6, beta=0.4)
    print("   - 乘客优先权重 (α): 0.6")
    print("   - 货物优先权重 (β): 0.4")
    print()
    
    # 创建优化器
    print("3. 创建优化器并构建模型...")
    optimizer = PassengerCargoOptimizer(nodes, vehicles, ai_engine)
    print("   - 距离矩阵已计算")
    print("   - 时间矩阵已计算")
    print()
    
    # 执行优化
    print("4. 执行AI协同优化...")
    print("-" * 80)
    optimized_routes = optimizer.optimize_with_ai_coordination(
        max_iterations=100,
        temperature=1000.0,
        cooling_rate=0.95
    )
    print("-" * 80)
    print()
    
    # 输出结果
    print("5. 优化结果:")
    print()
    for route in optimized_routes:
        if route.nodes:
            vehicle = vehicles[route.vehicle_id]
            print(f"车辆 {route.vehicle_id} ({vehicle.name}):")
            print(f"  路线: depot -> {' -> '.join(map(str, route.nodes))} -> depot")
            print(f"  总距离: {route.total_distance:.2f} km")
            print(f"  总时间: {route.total_time:.2f} 分钟")
            print(f"  总成本: {route.total_cost:.2f} 元")
            print(f"  乘客满意度: {optimizer.calculate_passenger_satisfaction(route):.2%}")
            print(f"  货物满意度: {optimizer.calculate_cargo_satisfaction(route):.2%}")
            print()
    
    # 总体统计
    total_cost = sum(route.total_cost for route in optimized_routes)
    total_distance = sum(route.total_distance for route in optimized_routes)
    avg_passenger_sat = np.mean([optimizer.calculate_passenger_satisfaction(r) for r in optimized_routes])
    avg_cargo_sat = np.mean([optimizer.calculate_cargo_satisfaction(r) for r in optimized_routes])
    
    print("=" * 80)
    print("总体统计:")
    print(f"  总成本: {total_cost:.2f} 元")
    print(f"  总距离: {total_distance:.2f} km")
    print(f"  平均乘客满意度: {avg_passenger_sat:.2%}")
    print(f"  平均货物满意度: {avg_cargo_sat:.2%}")
    print(f"  综合协调得分: {ai_engine.evaluate_coordination_score(avg_passenger_sat, avg_cargo_sat, 0.8):.2f}")
    print("=" * 80)
    print()
    
    # 可视化
    print("6. 生成可视化图表...")
    try:
        Visualizer.plot_routes(nodes, optimized_routes)
        Visualizer.plot_performance_metrics(optimized_routes, optimizer)
        print("   可视化完成！")
    except Exception as e:
        print(f"   可视化失败: {e}")
    print()
    
    # AI决策历史
    print("7. AI协同决策历史:")
    for i, decision in enumerate(ai_engine.decision_history[:5]):  # 显示前5条
        print(f"   决策 {i+1}: α={decision['alpha']:.2f}, β={decision['beta']:.2f}")
        print(f"          推理: {decision['reasoning']}")
    if len(ai_engine.decision_history) > 5:
        print(f"   ... (共 {len(ai_engine.decision_history)} 条决策)")
    print()
    
    print("=" * 80)
    print("优化完成！")
    print("=" * 80)


if __name__ == "__main__":
    main()
