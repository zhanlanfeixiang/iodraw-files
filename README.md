# 两阶段随机优化 MATLAB 实现

本项目实现了一个完整的两阶段随机优化框架，用于解决仓库选址与车辆路径优化问题。

## 🎯 项目概述

该项目解决的是一个典型的供应链优化问题：
- **第一阶段**：在不确定需求下选择仓库位置（选址决策）
- **第二阶段**：基于已选仓库和实际需求场景进行路径优化（配送决策）

## 📁 文件结构

```
├── two_stage_optimization.m           # 🚀 主优化函数（基础版本）
├── advanced_optimization.m            # 🔬 高级优化函数（多算法支持）
├── example_usage.m                    # 📖 使用示例和参数分析
├── test_functionality.m              # 🧪 功能测试脚本
├── 两阶段随机优化说明文档.md           # 📚 详细技术文档
└── README.md                          # 📋 本文件
```

## 🚀 快速开始

### 基础使用
```matlab
% 使用默认参数运行
[selected_warehouses, total_cost, routes] = two_stage_optimization();

% 查看结果
fprintf('选择的仓库: %s\n', num2str(selected_warehouses'));
fprintf('总成本: %.2f\n', total_cost);
```

### 自定义参数
```matlab
[warehouses, cost, routes] = two_stage_optimization(...
    'num_customers', 25, ...           % 客户数量
    'num_potential_warehouses', 6, ... % 潜在仓库数量
    'num_scenarios', 15, ...           % 随机场景数量
    'warehouse_capacity', 1200, ...    % 仓库容量
    'vehicle_capacity', 120, ...       % 车辆容量
    'plot_results', true);             % 显示结果图
```

### 高级算法使用
```matlab
% 使用遗传算法
[best_solution, all_solutions] = advanced_two_stage_optimization(...
    'algorithm', 'genetic', ...
    'num_runs', 10, ...
    'max_iterations', 200);

% 使用模拟退火算法
[best_solution, all_solutions] = advanced_two_stage_optimization(...
    'algorithm', 'simulated_annealing', ...
    'save_results', true);
```

## 🔧 功能特性

### 🎲 算法支持
- **贪心算法**：快速求解，适合小规模问题
- **遗传算法**：全局搜索，适合复杂问题
- **模拟退火**：跳出局部最优，平衡探索与开发

### 📊 可视化功能
- 仓库和客户位置分布图
- 配送路径可视化
- 需求分布统计图
- 成本分析图表
- 算法性能比较图

### 🎛️ 参数配置
| 参数名称 | 默认值 | 说明 |
|---------|--------|------|
| `num_customers` | 20 | 客户数量 |
| `num_potential_warehouses` | 5 | 潜在仓库数量 |
| `num_scenarios` | 10 | 随机场景数量 |
| `warehouse_capacity` | 1000 | 仓库容量 |
| `fixed_cost_warehouse` | 5000 | 仓库固定成本 |
| `vehicle_capacity` | 100 | 车辆容量 |
| `plot_results` | true | 是否显示结果图 |

## 📖 使用示例

### 运行示例集合
```matlab
% 运行所有预设示例
run('example_usage.m');
```

### 参数敏感性分析
```matlab
% 分析仓库成本对总成本的影响
warehouse_costs = [3000, 4000, 5000, 6000, 7000];
total_costs = zeros(size(warehouse_costs));

for i = 1:length(warehouse_costs)
    [~, total_costs(i), ~] = two_stage_optimization(...
        'fixed_cost_warehouse', warehouse_costs(i), ...
        'plot_results', false);
end

% 绘制敏感性分析结果
plot(warehouse_costs, total_costs, 'o-');
xlabel('仓库固定成本');
ylabel('总期望成本');
title('成本敏感性分析');
```

## 🧪 测试验证

运行测试脚本验证功能：
```matlab
run('test_functionality.m');
```

测试包括：
- ✅ 基本功能测试
- ✅ 参数验证测试  
- ✅ 数据一致性测试
- ✅ 边界条件测试
- ✅ 绘图功能测试
- ✅ 性能基准测试

## 📈 性能指南

### 问题规模建议
| 规模 | 客户数 | 仓库数 | 场景数 | 推荐算法 |
|------|--------|--------|--------|----------|
| 小规模 | ≤20 | ≤5 | ≤10 | 贪心算法 |
| 中规模 | 20-50 | 5-10 | 10-20 | 遗传算法 |
| 大规模 | >50 | >10 | >20 | 模拟退火 |

### 性能优化建议
1. **快速测试**：设置 `plot_results = false`
2. **大规模问题**：减少场景数量，使用高级算法
3. **精确求解**：增加运行次数 (`num_runs`)
4. **内存优化**：分批处理大规模数据

## 🔍 算法原理

### 第一阶段：仓库选址
1. 计算期望需求
2. 评估仓库-客户距离矩阵
3. 基于成本最小化选择仓库位置

### 第二阶段：路径优化
1. 为每个随机场景求解VRP
2. 使用最近邻启发式算法
3. 考虑车辆容量约束

### 随机性建模
- 多场景方法建模需求不确定性
- 等概率场景假设
- 期望值优化准则

## 📊 输出结果

### 基础版本
```matlab
selected_warehouses  % 选择的仓库编号向量
total_cost          % 总期望成本（标量）
routes              % 每个场景的路径信息（cell数组）
```

### 高级版本
```matlab
best_solution       % 最优解结构体
  .selected_warehouses  % 选择的仓库
  .routes              % 路径信息
  .total_cost          % 总成本
  .algorithm           % 使用的算法

all_solutions       % 所有运行的解（cell数组）
```

## 🛠️ 技术要求

- **MATLAB版本**：R2016b 或更高
- **推荐工具箱**：Statistics and Machine Learning Toolbox
- **内存要求**：建议 4GB+ RAM（大规模问题）
- **处理器**：支持并行计算的多核处理器（可选）

## 🔄 扩展方向

### 可能的改进
1. **多目标优化**：成本、时间、环境影响
2. **动态场景**：时变需求、实时优化
3. **鲁棒优化**：最坏情况保证
4. **机器学习**：需求预测、智能调参

### 自定义修改
1. **距离函数**：支持实际道路距离
2. **约束条件**：时间窗、服务时间限制
3. **成本结构**：非线性成本、折扣策略

## 🐛 常见问题

### Q: 程序运行时间过长怎么办？
A: 
- 减少场景数量或客户数量
- 使用贪心算法
- 关闭绘图功能

### Q: 某些客户未被服务怎么办？
A:
- 增加车辆容量
- 增加仓库数量  
- 检查需求设置

### Q: 结果不稳定怎么办？
A:
- 增加运行次数
- 使用固定随机种子
- 调整算法参数

## 📜 许可证

本项目采用 MIT 许可证。详见 LICENSE 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进项目！

## 📚 参考文献

1. Birge, J. R., & Louveaux, F. (2011). *Introduction to stochastic programming*
2. Laporte, G. (2009). *Fifty years of vehicle routing*. Transportation Science
3. Melo, M. T., et al. (2009). *Facility location and supply chain management*

---

**原始文件格式支持**：
* [流程图](https://www.iodraw.com/diagram) (*.iodraw)
* [思维导图](https://www.iodraw.com/mind) (*.mind)
* [甘特图](https://www.iodraw.com/gantt) (*.gantt)
* [在线白板](https://www.iodraw.com/whiteboard) (*.wb)
* [代码绘图](https://www.iodraw.com/codechart) (*.md)
* [在线图表](https://www.iodraw.com/chart) (*.chart)

**新增**：
* MATLAB 两阶段随机优化代码 (*.m)

---

**作者**: 自动生成  
**版本**: 1.0  
**更新日期**: 2024

🚀 **开始您的两阶段优化之旅！**
