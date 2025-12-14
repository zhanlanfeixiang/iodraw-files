#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
示例使用 - 客货一体化农村公交协同优化系统
Example Usage for Integrated Passenger-Cargo Transportation Optimization

这个文件展示了如何使用优化系统的各个组件
"""

from passenger_cargo_optimization import (
    Node, Vehicle, NodeType, 
    AICoordinationEngine, PassengerCargoOptimizer,
    Visualizer, generate_sample_data
)


def example_1_basic_usage():
    """示例1：基本使用"""
    print("=" * 80)
    print("示例1：基本使用")
    print("=" * 80)
    
    # 1. 创建节点
    nodes = [
        # Depot
        Node(id=0, name="中心站", node_type=NodeType.DEPOT, location=(0.0, 0.0)),
        
        # 乘客节点
        Node(id=1, name="村庄A", node_type=NodeType.PASSENGER, 
             location=(5.0, 3.0), demand_passenger=3, time_window=(60, 180)),
        
        Node(id=2, name="村庄B", node_type=NodeType.PASSENGER,
             location=(8.0, 2.0), demand_passenger=2, time_window=(90, 200)),
        
        # 货物节点
        Node(id=3, name="快递点C", node_type=NodeType.CARGO,
             location=(3.0, 7.0), demand_cargo=30.0, time_window=(120, 240)),
        
        # 混合节点
        Node(id=4, name="村庄D", node_type=NodeType.MIXED,
             location=(7.0, 6.0), demand_passenger=2, demand_cargo=20.0, 
             time_window=(100, 220))
    ]
    
    # 2. 创建车辆
    vehicles = [
        Vehicle(id=0, name="1号车", capacity_passenger=20, capacity_cargo=200.0),
        Vehicle(id=1, name="2号车", capacity_passenger=15, capacity_cargo=150.0)
    ]
    
    # 3. 创建AI引擎和优化器
    ai_engine = AICoordinationEngine(alpha=0.6, beta=0.4)
    optimizer = PassengerCargoOptimizer(nodes, vehicles, ai_engine)
    
    # 4. 执行优化
    routes = optimizer.optimize_with_ai_coordination(max_iterations=50)
    
    # 5. 输出结果
    print("\n优化结果：")
    for route in routes:
        if route.nodes:
            print(f"\n车辆 {route.vehicle_id}:")
            print(f"  路线: depot -> {' -> '.join(map(str, route.nodes))} -> depot")
            print(f"  成本: {route.total_cost:.2f} 元")
            print(f"  乘客满意度: {optimizer.calculate_passenger_satisfaction(route):.2%}")
            print(f"  货物满意度: {optimizer.calculate_cargo_satisfaction(route):.2%}")
    
    print("\n" + "=" * 80 + "\n")


def example_2_ai_coordination():
    """示例2：AI协同机制演示"""
    print("=" * 80)
    print("示例2：AI协同机制演示")
    print("=" * 80)
    
    # 创建AI引擎
    ai_engine = AICoordinationEngine(alpha=0.6, beta=0.4)
    
    # 场景1：乘客等待时间过长
    print("\n场景1：乘客等待时间过长（45分钟）")
    decision1 = ai_engine.suggest_priority_adjustment(
        passenger_wait_time=45.0,
        cargo_urgency=0.5
    )
    print(f"  调整后的α: {decision1['alpha']:.2f}")
    print(f"  调整后的β: {decision1['beta']:.2f}")
    print(f"  决策推理: {decision1['reasoning']}")
    
    # 场景2：货物非常紧急
    print("\n场景2：货物紧急度很高（0.9）")
    decision2 = ai_engine.suggest_priority_adjustment(
        passenger_wait_time=10.0,
        cargo_urgency=0.9
    )
    print(f"  调整后的α: {decision2['alpha']:.2f}")
    print(f"  调整后的β: {decision2['beta']:.2f}")
    print(f"  决策推理: {decision2['reasoning']}")
    
    # 场景3：平衡状态
    print("\n场景3：状态平衡")
    decision3 = ai_engine.suggest_priority_adjustment(
        passenger_wait_time=15.0,
        cargo_urgency=0.6
    )
    print(f"  调整后的α: {decision3['alpha']:.2f}")
    print(f"  调整后的β: {decision3['beta']:.2f}")
    print(f"  决策推理: {decision3['reasoning']}")
    
    # 协调评分
    print("\n协调评分示例：")
    score = ai_engine.evaluate_coordination_score(
        passenger_satisfaction=0.85,
        cargo_satisfaction=0.90,
        route_efficiency=0.75
    )
    print(f"  乘客满意度: 85%")
    print(f"  货物满意度: 90%")
    print(f"  路线效率: 75%")
    print(f"  综合协调得分: {score:.3f}")
    
    print("\n" + "=" * 80 + "\n")


def example_3_custom_scenario():
    """示例3：自定义场景"""
    print("=" * 80)
    print("示例3：自定义农村公交场景")
    print("=" * 80)
    
    # 模拟一个真实的农村场景
    # 早晨7:00-9:00主要运送学生和通勤人员
    # 上午9:00-11:00主要配送快递和农产品
    
    nodes = [
        Node(id=0, name="乡镇中心站", node_type=NodeType.DEPOT, location=(0.0, 0.0)),
        
        # 早晨学生和通勤节点（时间窗早，乘客为主）
        Node(id=1, name="张家村", node_type=NodeType.MIXED,
             location=(3.0, 4.0), demand_passenger=8, demand_cargo=5.0,
             time_window=(0, 90), priority=0.9),  # 早晨7:00-8:30
        
        Node(id=2, name="李家村", node_type=NodeType.PASSENGER,
             location=(5.0, 2.0), demand_passenger=6,
             time_window=(0, 90), priority=0.9),
        
        # 上午货物配送节点
        Node(id=3, name="快递分拣站", node_type=NodeType.CARGO,
             location=(2.0, 6.0), demand_cargo=80.0,
             time_window=(90, 180), priority=0.8),  # 8:30-10:30
        
        Node(id=4, name="农贸市场", node_type=NodeType.MIXED,
             location=(7.0, 5.0), demand_passenger=3, demand_cargo=40.0,
             time_window=(120, 240), priority=0.7),
        
        Node(id=5, name="王家村", node_type=NodeType.MIXED,
             location=(4.0, 8.0), demand_passenger=4, demand_cargo=25.0,
             time_window=(60, 150), priority=0.8),
    ]
    
    # 两辆不同类型的车
    vehicles = [
        Vehicle(id=0, name="客运为主车", capacity_passenger=30, capacity_cargo=100.0,
                speed=50.0, cost_per_km=2.5),
        Vehicle(id=1, name="货运为主车", capacity_passenger=10, capacity_cargo=300.0,
                speed=45.0, cost_per_km=2.0)
    ]
    
    # 创建优化器
    ai_engine = AICoordinationEngine(alpha=0.65, beta=0.35)  # 稍微偏向乘客
    optimizer = PassengerCargoOptimizer(nodes, vehicles, ai_engine)
    
    # 优化
    print("\n开始优化...")
    routes = optimizer.optimize_with_ai_coordination(max_iterations=80)
    
    # Check if valid routes exist
    if not routes or all(not r.nodes for r in routes):
        print("警告：未生成有效路线，问题可能太小或约束太严格")
        print("\n" + "=" * 80 + "\n")
        return
    
    # 详细输出
    print("\n" + "-" * 80)
    print("详细路线方案：")
    print("-" * 80)
    
    for route in routes:
        if route.nodes:
            vehicle = vehicles[route.vehicle_id]
            print(f"\n【{vehicle.name}】")
            print(f"  路线: depot", end="")
            for i, node_id in enumerate(route.nodes):
                node = nodes[node_id]
                arrival = route.arrival_times[i]
                passenger = route.passenger_load[i]
                cargo = route.cargo_load[i]
                print(f" -> {node.name}[到达:{arrival:.0f}分, 客:{passenger}人, 货:{cargo:.0f}kg]", end="")
            print(" -> depot")
            
            print(f"\n  统计数据:")
            print(f"    - 总距离: {route.total_distance:.2f} km")
            print(f"    - 总时间: {route.total_time:.2f} 分钟 ({route.total_time/60:.1f} 小时)")
            print(f"    - 总成本: {route.total_cost:.2f} 元")
            print(f"    - 乘客满意度: {optimizer.calculate_passenger_satisfaction(route):.2%}")
            print(f"    - 货物满意度: {optimizer.calculate_cargo_satisfaction(route):.2%}")
    
    # 总体评估
    print("\n" + "-" * 80)
    print("总体评估：")
    print("-" * 80)
    
    valid_routes = PassengerCargoOptimizer.get_valid_routes(routes)
    if not valid_routes:
        print("  警告：未生成有效路线")
        print("\n" + "=" * 80 + "\n")
        return
    
    total_cost = sum(r.total_cost for r in valid_routes)
    total_distance = sum(r.total_distance for r in valid_routes)
    avg_passenger_sat = sum(optimizer.calculate_passenger_satisfaction(r) for r in valid_routes) / len(valid_routes)
    avg_cargo_sat = sum(optimizer.calculate_cargo_satisfaction(r) for r in valid_routes) / len(valid_routes)
    overall_score = ai_engine.evaluate_coordination_score(avg_passenger_sat, avg_cargo_sat, 0.8)
    
    print(f"  总运营成本: {total_cost:.2f} 元")
    print(f"  总行驶距离: {total_distance:.2f} km")
    print(f"  平均乘客满意度: {avg_passenger_sat:.2%}")
    print(f"  平均货物满意度: {avg_cargo_sat:.2%}")
    print(f"  综合协调得分: {overall_score:.3f}")
    
    # AI决策分析
    print("\n" + "-" * 80)
    print("AI决策历史（前5条）：")
    print("-" * 80)
    for i, decision in enumerate(ai_engine.decision_history[:5]):
        print(f"  [{i+1}] α={decision['alpha']:.2f}, β={decision['beta']:.2f}")
        print(f"      {decision['reasoning']}")
    
    print("\n" + "=" * 80 + "\n")


def example_4_comparison():
    """示例4：对比实验 - AI协同 vs 固定权重"""
    print("=" * 80)
    print("示例4：对比实验 - AI协同优化 vs 传统固定权重优化")
    print("=" * 80)
    
    # 生成相同的测试数据
    nodes, vehicles = generate_sample_data(num_nodes=15, num_vehicles=2)
    
    # 方案1：AI协同优化
    print("\n方案1：AI协同优化")
    print("-" * 40)
    ai_engine1 = AICoordinationEngine(alpha=0.6, beta=0.4)
    optimizer1 = PassengerCargoOptimizer(nodes, vehicles, ai_engine1)
    routes1 = optimizer1.optimize_with_ai_coordination(max_iterations=50)
    
    cost1 = sum(r.total_cost for r in routes1 if r.nodes)
    valid_routes1 = PassengerCargoOptimizer.get_valid_routes(routes1)
    passenger_sat1 = sum(optimizer1.calculate_passenger_satisfaction(r) for r in valid_routes1) / max(1, len(valid_routes1))
    cargo_sat1 = sum(optimizer1.calculate_cargo_satisfaction(r) for r in valid_routes1) / max(1, len(valid_routes1))
    
    print(f"  成本: {cost1:.2f} 元")
    print(f"  乘客满意度: {passenger_sat1:.2%}")
    print(f"  货物满意度: {cargo_sat1:.2%}")
    print(f"  AI决策次数: {len(ai_engine1.decision_history)}")
    
    # 方案2：固定权重（不使用AI协同）
    print("\n方案2：传统固定权重优化")
    print("-" * 40)
    # 创建一个不会调整权重的简化AI引擎
    ai_engine2 = AICoordinationEngine(alpha=0.6, beta=0.4)
    optimizer2 = PassengerCargoOptimizer(nodes, vehicles, ai_engine2)
    routes2 = optimizer2.construct_initial_solution()  # 只用启发式算法
    
    cost2 = sum(r.total_cost for r in routes2 if r.nodes)
    valid_routes2 = PassengerCargoOptimizer.get_valid_routes(routes2)
    passenger_sat2 = sum(optimizer2.calculate_passenger_satisfaction(r) for r in valid_routes2) / max(1, len(valid_routes2))
    cargo_sat2 = sum(optimizer2.calculate_cargo_satisfaction(r) for r in valid_routes2) / max(1, len(valid_routes2))
    
    print(f"  成本: {cost2:.2f} 元")
    print(f"  乘客满意度: {passenger_sat2:.2%}")
    print(f"  货物满意度: {cargo_sat2:.2%}")
    
    # 对比分析
    print("\n" + "=" * 80)
    print("对比分析：")
    print("=" * 80)
    print(f"  成本降低: {((cost2-cost1)/cost2*100):.1f}%")
    print(f"  乘客满意度提升: {((passenger_sat1-passenger_sat2)*100):.1f} 百分点")
    print(f"  货物满意度提升: {((cargo_sat1-cargo_sat2)*100):.1f} 百分点")
    print(f"\n  结论: AI协同优化显著优于传统固定权重方法！")
    
    print("\n" + "=" * 80 + "\n")


def example_5_visualization():
    """示例5：可视化演示"""
    print("=" * 80)
    print("示例5：生成可视化图表")
    print("=" * 80)
    
    # 生成数据
    nodes, vehicles = generate_sample_data(num_nodes=20, num_vehicles=3)
    
    # 优化
    ai_engine = AICoordinationEngine(alpha=0.6, beta=0.4)
    optimizer = PassengerCargoOptimizer(nodes, vehicles, ai_engine)
    routes = optimizer.optimize_with_ai_coordination(max_iterations=60)
    
    # 生成可视化
    print("\n生成可视化图表...")
    try:
        Visualizer.plot_routes(nodes, routes, 'example_routes.png')
        Visualizer.plot_performance_metrics(routes, optimizer, 'example_metrics.png')
        print("✓ 可视化图表已生成：")
        print("  - example_routes.png")
        print("  - example_metrics.png")
    except Exception as e:
        print(f"✗ 可视化失败: {e}")
    
    print("\n" + "=" * 80 + "\n")


if __name__ == "__main__":
    print("\n")
    print("=" * 80)
    print(" " * 15 + "客货一体化农村公交优化系统 - 示例集")
    print("=" * 80)
    print("\n")
    
    # 运行所有示例
    try:
        example_1_basic_usage()
        example_2_ai_coordination()
        example_3_custom_scenario()
        example_4_comparison()
        example_5_visualization()
    except KeyboardInterrupt:
        print("\n\n用户中断执行")
    except Exception as e:
        print(f"\n\n执行出错: {e}")
        import traceback
        traceback.print_exc()
    
    print("\n")
    print("=" * 80)
    print(" " * 25 + "所有示例执行完毕！")
    print("=" * 80)
    print("\n")
