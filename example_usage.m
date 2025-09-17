%% 两阶段随机优化示例
% Example usage of Two-Stage Stochastic Optimization for Warehouse Location and Route Optimization
% 示例：仓库选址与路径优化

clear; clc; close all;

fprintf('=== 两阶段随机优化：仓库选址与路径优化示例 ===\n\n');

%% 示例1：基本使用
fprintf('示例1：基本参数运行\n');
fprintf('-------------------\n');

try
    [selected_warehouses, total_cost, routes] = two_stage_optimization();
    fprintf('示例1完成，总成本: %.2f\n\n', total_cost);
catch ME
    fprintf('示例1运行出错: %s\n\n', ME.message);
end

%% 示例2：自定义参数
fprintf('示例2：自定义参数\n');
fprintf('-------------------\n');

try
    [selected_warehouses2, total_cost2, routes2] = two_stage_optimization(...
        'num_customers', 15, ...
        'num_potential_warehouses', 4, ...
        'num_scenarios', 8, ...
        'warehouse_capacity', 800, ...
        'fixed_cost_warehouse', 4000, ...
        'vehicle_capacity', 80, ...
        'plot_results', true);
    
    fprintf('示例2完成，总成本: %.2f\n\n', total_cost2);
catch ME
    fprintf('示例2运行出错: %s\n\n', ME.message);
end

%% 示例3：大规模问题
fprintf('示例3：大规模问题\n');
fprintf('-------------------\n');

try
    [selected_warehouses3, total_cost3, routes3] = two_stage_optimization(...
        'num_customers', 30, ...
        'num_potential_warehouses', 8, ...
        'num_scenarios', 15, ...
        'warehouse_capacity', 1200, ...
        'fixed_cost_warehouse', 6000, ...
        'vehicle_capacity', 120, ...
        'plot_results', false); % 关闭绘图以提高速度
    
    fprintf('示例3完成，总成本: %.2f\n\n', total_cost3);
catch ME
    fprintf('示例3运行出错: %s\n\n', ME.message);
end

%% 参数敏感性分析
fprintf('示例4：参数敏感性分析\n');
fprintf('-------------------\n');

warehouse_costs = [3000, 4000, 5000, 6000, 7000];
total_costs = zeros(size(warehouse_costs));

fprintf('分析仓库固定成本对总成本的影响:\n');
for i = 1:length(warehouse_costs)
    try
        [~, total_costs(i), ~] = two_stage_optimization(...
            'num_customers', 20, ...
            'num_potential_warehouses', 5, ...
            'num_scenarios', 10, ...
            'fixed_cost_warehouse', warehouse_costs(i), ...
            'plot_results', false);
        
        fprintf('  仓库成本 %d: 总成本 %.2f\n', warehouse_costs(i), total_costs(i));
    catch ME
        fprintf('  仓库成本 %d: 运行出错 - %s\n', warehouse_costs(i), ME.message);
        total_costs(i) = NaN;
    end
end

% 绘制敏感性分析结果
if any(~isnan(total_costs))
    figure('Position', [100, 100, 800, 600]);
    plot(warehouse_costs, total_costs, 'o-', 'LineWidth', 2, 'MarkerSize', 8);
    xlabel('仓库固定成本');
    ylabel('总期望成本');
    title('仓库固定成本敏感性分析');
    grid on;
    
    % 添加数据标签
    for i = 1:length(warehouse_costs)
        if ~isnan(total_costs(i))
            text(warehouse_costs(i), total_costs(i), sprintf('%.0f', total_costs(i)), ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center');
        end
    end
end

fprintf('\n=== 所有示例完成 ===\n');

%% 结果比较
fprintf('\n结果比较:\n');
fprintf('---------\n');
if exist('total_cost', 'var')
    fprintf('示例1 (基本参数): %.2f\n', total_cost);
end
if exist('total_cost2', 'var')
    fprintf('示例2 (自定义参数): %.2f\n', total_cost2);
end
if exist('total_cost3', 'var')
    fprintf('示例3 (大规模问题): %.2f\n', total_cost3);
end

%% 使用提示
fprintf('\n使用提示:\n');
fprintf('=========\n');
fprintf('1. 函数支持多种参数自定义，使用名称-值对的方式传入参数\n');
fprintf('2. 主要参数包括:\n');
fprintf('   - num_customers: 客户数量\n');
fprintf('   - num_potential_warehouses: 潜在仓库数量\n');
fprintf('   - num_scenarios: 随机场景数量\n');
fprintf('   - warehouse_capacity: 仓库容量\n');
fprintf('   - fixed_cost_warehouse: 仓库固定成本\n');
fprintf('   - vehicle_capacity: 车辆容量\n');
fprintf('   - plot_results: 是否绘制结果图（true/false）\n');
fprintf('3. 函数返回选择的仓库、总成本和所有场景的路径信息\n');
fprintf('4. 算法使用启发式方法，适合中等规模问题\n');
fprintf('5. 对于大规模问题，建议关闭绘图功能以提高计算速度\n');