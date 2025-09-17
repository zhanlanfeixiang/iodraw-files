%% 测试脚本：验证两阶段随机优化功能
% Test script for two-stage stochastic optimization

clear; clc; close all;

fprintf('开始测试两阶段随机优化功能...\n\n');

%% 测试1：基本功能测试
fprintf('测试1：基本功能测试\n');
fprintf('==================\n');

try
    % 使用较小的参数进行快速测试
    [selected_warehouses, total_cost, routes] = two_stage_optimization(...
        'num_customers', 8, ...
        'num_potential_warehouses', 3, ...
        'num_scenarios', 5, ...
        'warehouse_capacity', 500, ...
        'vehicle_capacity', 60, ...
        'plot_results', false); % 关闭绘图以加快测试
    
    fprintf('✓ 基本功能测试通过\n');
    fprintf('  选择的仓库: %s\n', num2str(selected_warehouses'));
    fprintf('  总成本: %.2f\n', total_cost);
    fprintf('  场景数: %d\n', length(routes));
    
    % 验证输出格式
    assert(isnumeric(selected_warehouses), '选择的仓库应为数值');
    assert(isnumeric(total_cost), '总成本应为数值');
    assert(iscell(routes), '路径应为cell数组');
    
    fprintf('✓ 输出格式验证通过\n\n');
    
catch ME
    fprintf('✗ 基本功能测试失败: %s\n\n', ME.message);
end

%% 测试2：参数验证测试
fprintf('测试2：参数验证测试\n');
fprintf('==================\n');

try
    % 测试不同参数组合
    param_sets = {
        struct('num_customers', 5, 'num_potential_warehouses', 2, 'num_scenarios', 3), ...
        struct('num_customers', 12, 'num_potential_warehouses', 4, 'num_scenarios', 6), ...
        struct('num_customers', 15, 'num_potential_warehouses', 5, 'num_scenarios', 8)
    };
    
    for i = 1:length(param_sets)
        params = param_sets{i};
        [~, cost, ~] = two_stage_optimization(...
            'num_customers', params.num_customers, ...
            'num_potential_warehouses', params.num_potential_warehouses, ...
            'num_scenarios', params.num_scenarios, ...
            'plot_results', false);
        
        fprintf('  参数组合 %d: 成本 %.2f\n', i, cost);
    end
    
    fprintf('✓ 参数验证测试通过\n\n');
    
catch ME
    fprintf('✗ 参数验证测试失败: %s\n\n', ME.message);
end

%% 测试3：数据一致性测试
fprintf('测试3：数据一致性测试\n');
fprintf('==================\n');

try
    % 使用固定随机种子，测试结果的一致性
    rng(42);
    [warehouses1, cost1, routes1] = two_stage_optimization(...
        'num_customers', 10, 'num_potential_warehouses', 3, 'num_scenarios', 5, ...
        'plot_results', false);
    
    rng(42);
    [warehouses2, cost2, routes2] = two_stage_optimization(...
        'num_customers', 10, 'num_potential_warehouses', 3, 'num_scenarios', 5, ...
        'plot_results', false);
    
    % 验证结果一致性
    if isequal(warehouses1, warehouses2) && abs(cost1 - cost2) < 1e-6
        fprintf('✓ 数据一致性测试通过\n');
        fprintf('  两次运行结果完全一致\n\n');
    else
        fprintf('✗ 数据一致性测试失败\n');
        fprintf('  第一次: 仓库 %s, 成本 %.6f\n', num2str(warehouses1'), cost1);
        fprintf('  第二次: 仓库 %s, 成本 %.6f\n', num2str(warehouses2'), cost2);
    end
    
catch ME
    fprintf('✗ 数据一致性测试失败: %s\n\n', ME.message);
end

%% 测试4：边界条件测试
fprintf('测试4：边界条件测试\n');
fprintf('==================\n');

try
    % 测试最小规模问题
    [warehouses_min, cost_min, routes_min] = two_stage_optimization(...
        'num_customers', 3, 'num_potential_warehouses', 2, 'num_scenarios', 2, ...
        'plot_results', false);
    
    fprintf('✓ 最小规模测试通过 (3客户, 2仓库, 2场景)\n');
    fprintf('  成本: %.2f\n', cost_min);
    
    % 测试单仓库情况
    [warehouses_single, cost_single, routes_single] = two_stage_optimization(...
        'num_customers', 8, 'num_potential_warehouses', 1, 'num_scenarios', 3, ...
        'plot_results', false);
    
    fprintf('✓ 单仓库测试通过\n');
    fprintf('  选择的仓库: %d, 成本: %.2f\n', warehouses_single, cost_single);
    
    fprintf('✓ 边界条件测试通过\n\n');
    
catch ME
    fprintf('✗ 边界条件测试失败: %s\n\n', ME.message);
end

%% 测试5：绘图功能测试
fprintf('测试5：绘图功能测试\n');
fprintf('==================\n');

try
    % 测试绘图功能（生成但不显示）
    [~, ~, ~] = two_stage_optimization(...
        'num_customers', 6, 'num_potential_warehouses', 3, 'num_scenarios', 3, ...
        'plot_results', true);
    
    % 检查是否生成了图形
    if ~isempty(findall(0, 'type', 'figure'))
        fprintf('✓ 绘图功能测试通过\n');
        fprintf('  成功生成可视化图形\n');
        close all; % 关闭所有图形
    else
        fprintf('✗ 绘图功能测试失败 - 未生成图形\n');
    end
    
catch ME
    fprintf('✗ 绘图功能测试失败: %s\n', ME.message);
end

%% 测试总结
fprintf('\n=== 测试总结 ===\n');
fprintf('所有基本功能测试完成。\n');
fprintf('如果所有测试都显示"通过"，则说明代码工作正常。\n');
fprintf('如果有测试失败，请检查相应的错误信息。\n\n');

%% 性能基准测试
fprintf('性能基准测试：\n');
fprintf('=============\n');

try
    % 测试中等规模问题的性能
    tic;
    [~, benchmark_cost, ~] = two_stage_optimization(...
        'num_customers', 20, 'num_potential_warehouses', 5, 'num_scenarios', 10, ...
        'plot_results', false);
    benchmark_time = toc;
    
    fprintf('基准问题 (20客户, 5仓库, 10场景):\n');
    fprintf('  执行时间: %.2f 秒\n', benchmark_time);
    fprintf('  总成本: %.2f\n', benchmark_cost);
    
    if benchmark_time < 30
        fprintf('✓ 性能表现良好\n');
    elseif benchmark_time < 60
        fprintf('⚠ 性能可接受\n');
    else
        fprintf('⚠ 性能较慢，建议优化参数\n');
    end
    
catch ME
    fprintf('✗ 性能测试失败: %s\n', ME.message);
end

fprintf('\n测试完成！\n');