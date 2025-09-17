%% 两阶段随机优化：仓库选址与路径优化
% Two-Stage Stochastic Optimization: Warehouse Location and Route Optimization
% 作者: 自动生成代码
% 日期: 2024

function [selected_warehouses, total_cost, routes] = two_stage_optimization(varargin)
    %% 参数解析
    p = inputParser;
    addParameter(p, 'num_customers', 20, @isnumeric);
    addParameter(p, 'num_potential_warehouses', 5, @isnumeric);
    addParameter(p, 'num_scenarios', 10, @isnumeric);
    addParameter(p, 'warehouse_capacity', 1000, @isnumeric);
    addParameter(p, 'fixed_cost_warehouse', 5000, @isnumeric);
    addParameter(p, 'vehicle_capacity', 100, @isnumeric);
    addParameter(p, 'plot_results', true, @islogical);
    
    parse(p, varargin{:});
    params = p.Results;
    
    fprintf('开始两阶段随机优化...\n');
    fprintf('客户数量: %d\n', params.num_customers);
    fprintf('潜在仓库数量: %d\n', params.num_potential_warehouses);
    fprintf('场景数量: %d\n', params.num_scenarios);
    
    %% 生成问题数据
    [customers, warehouses, scenarios] = generate_problem_data(params);
    
    %% 第一阶段：仓库选址优化
    fprintf('\n第一阶段：仓库选址优化...\n');
    selected_warehouses = stage1_warehouse_selection(customers, warehouses, scenarios, params);
    
    %% 第二阶段：路径优化
    fprintf('\n第二阶段：路径优化...\n');
    [routes, route_costs] = stage2_route_optimization(customers, warehouses, selected_warehouses, scenarios, params);
    
    %% 计算总成本
    total_cost = calculate_total_cost(selected_warehouses, route_costs, params);
    
    %% 结果可视化
    if params.plot_results
        visualize_results(customers, warehouses, selected_warehouses, routes, scenarios);
    end
    
    %% 输出结果摘要
    print_solution_summary(selected_warehouses, total_cost, routes, params);
end

function [customers, warehouses, scenarios] = generate_problem_data(params)
    %% 生成客户位置（随机分布）
    rng(42); % 固定随机种子以确保可重复性
    customers.locations = rand(params.num_customers, 2) * 100; % 0-100范围内的坐标
    customers.names = cellstr(num2str((1:params.num_customers)', 'C%d'));
    
    %% 生成潜在仓库位置
    warehouses.locations = rand(params.num_potential_warehouses, 2) * 100;
    warehouses.capacity = ones(params.num_potential_warehouses, 1) * params.warehouse_capacity;
    warehouses.fixed_cost = ones(params.num_potential_warehouses, 1) * params.fixed_cost_warehouse;
    warehouses.names = cellstr(num2str((1:params.num_potential_warehouses)', 'W%d'));
    
    %% 生成随机需求场景
    scenarios = struct();
    for s = 1:params.num_scenarios
        % 每个场景的客户需求（正态分布）
        scenarios(s).demand = max(1, round(normrnd(50, 15, params.num_customers, 1)));
        scenarios(s).probability = 1/params.num_scenarios; % 等概率场景
        scenarios(s).name = sprintf('Scenario_%d', s);
    end
    
    fprintf('数据生成完成。\n');
end

function selected_warehouses = stage1_warehouse_selection(customers, warehouses, scenarios, params)
    %% 第一阶段：使用期望值模型选择仓库位置
    
    num_warehouses = size(warehouses.locations, 1);
    num_customers = size(customers.locations, 1);
    
    % 计算所有仓库到客户的距离矩阵
    dist_matrix = calculate_distance_matrix(warehouses.locations, customers.locations);
    
    % 计算期望需求
    expected_demand = zeros(num_customers, 1);
    for i = 1:num_customers
        for s = 1:length(scenarios)
            expected_demand(i) = expected_demand(i) + scenarios(s).demand(i) * scenarios(s).probability;
        end
    end
    
    % 简化的仓库选址模型：基于成本和覆盖能力
    warehouse_scores = zeros(num_warehouses, 1);
    
    for w = 1:num_warehouses
        % 计算该仓库的服务成本（基于距离和需求）
        service_cost = sum(dist_matrix(w, :)' .* expected_demand);
        % 仓库得分 = 固定成本 + 期望服务成本
        warehouse_scores(w) = warehouses.fixed_cost(w) + service_cost * 0.1; % 0.1是单位运输成本
    end
    
    % 选择成本最低的仓库（简化：选择一个仓库）
    [~, best_warehouse] = min(warehouse_scores);
    selected_warehouses = best_warehouse;
    
    % 如果总需求大，可以选择多个仓库
    total_expected_demand = sum(expected_demand);
    if total_expected_demand > params.warehouse_capacity
        % 选择额外的仓库
        [~, sorted_indices] = sort(warehouse_scores);
        cumulative_capacity = 0;
        selected_warehouses = [];
        for i = 1:num_warehouses
            selected_warehouses = [selected_warehouses; sorted_indices(i)];
            cumulative_capacity = cumulative_capacity + warehouses.capacity(sorted_indices(i));
            if cumulative_capacity >= total_expected_demand
                break;
            end
        end
    end
    
    fprintf('选择的仓库: %s\n', strjoin(warehouses.names(selected_warehouses), ', '));
end

function [routes, route_costs] = stage2_route_optimization(customers, warehouses, selected_warehouses, scenarios, params)
    %% 第二阶段：对每个场景进行路径优化
    
    num_scenarios = length(scenarios);
    routes = cell(num_scenarios, 1);
    route_costs = zeros(num_scenarios, 1);
    
    for s = 1:num_scenarios
        fprintf('  场景 %d/%d 路径优化...\n', s, num_scenarios);
        
        % 获取当前场景的需求
        current_demand = scenarios(s).demand;
        
        % 为当前场景优化路径
        [routes{s}, route_costs(s)] = solve_vrp_for_scenario(customers, warehouses, ...
            selected_warehouses, current_demand, params);
    end
    
    fprintf('所有场景的路径优化完成。\n');
end

function [scenario_routes, scenario_cost] = solve_vrp_for_scenario(customers, warehouses, selected_warehouses, demand, params)
    %% 为特定场景解决车辆路径问题（VRP）
    
    num_customers = length(demand);
    num_selected_warehouses = length(selected_warehouses);
    
    % 使用最近邻启发式算法
    scenario_routes = {};
    scenario_cost = 0;
    unvisited_customers = 1:num_customers;
    
    for w = 1:num_selected_warehouses
        warehouse_idx = selected_warehouses(w);
        warehouse_loc = warehouses.locations(warehouse_idx, :);
        
        while ~isempty(unvisited_customers)
            % 开始新的路径
            current_route = [];
            current_load = 0;
            current_location = warehouse_loc;
            route_distance = 0;
            
            while ~isempty(unvisited_customers) && current_load < params.vehicle_capacity
                % 找到最近的未访问客户
                distances = zeros(length(unvisited_customers), 1);
                for i = 1:length(unvisited_customers)
                    customer_idx = unvisited_customers(i);
                    customer_loc = customers.locations(customer_idx, :);
                    distances(i) = norm(current_location - customer_loc);
                end
                
                [min_dist, min_idx] = min(distances);
                nearest_customer = unvisited_customers(min_idx);
                
                % 检查容量约束
                if current_load + demand(nearest_customer) <= params.vehicle_capacity
                    % 添加客户到路径
                    current_route = [current_route, nearest_customer];
                    current_load = current_load + demand(nearest_customer);
                    current_location = customers.locations(nearest_customer, :);
                    route_distance = route_distance + min_dist;
                    
                    % 从未访问列表中移除
                    unvisited_customers(min_idx) = [];
                else
                    break; % 容量不足，结束当前路径
                end
            end
            
            if ~isempty(current_route)
                % 返回仓库
                return_distance = norm(current_location - warehouse_loc);
                route_distance = route_distance + return_distance;
                
                % 保存路径
                route_info.warehouse = warehouse_idx;
                route_info.customers = current_route;
                route_info.distance = route_distance;
                route_info.load = current_load;
                scenario_routes{end+1} = route_info;
                
                scenario_cost = scenario_cost + route_distance;
            else
                break; % 无法创建更多路径
            end
        end
    end
    
    if ~isempty(unvisited_customers)
        warning('场景中有客户未被服务: %s', num2str(unvisited_customers));
    end
end

function total_cost = calculate_total_cost(selected_warehouses, route_costs, params)
    %% 计算总期望成本
    
    % 固定成本（仓库）
    fixed_cost = length(selected_warehouses) * params.fixed_cost_warehouse;
    
    % 期望运输成本
    expected_transport_cost = mean(route_costs);
    
    total_cost = fixed_cost + expected_transport_cost;
    
    fprintf('\n成本分析:\n');
    fprintf('  仓库固定成本: %.2f\n', fixed_cost);
    fprintf('  期望运输成本: %.2f\n', expected_transport_cost);
    fprintf('  总期望成本: %.2f\n', total_cost);
end

function dist_matrix = calculate_distance_matrix(locations1, locations2)
    %% 计算两组位置之间的欧几里得距离矩阵
    
    n1 = size(locations1, 1);
    n2 = size(locations2, 1);
    dist_matrix = zeros(n1, n2);
    
    for i = 1:n1
        for j = 1:n2
            dist_matrix(i, j) = norm(locations1(i, :) - locations2(j, :));
        end
    end
end

function visualize_results(customers, warehouses, selected_warehouses, routes, scenarios)
    %% 可视化优化结果
    
    figure('Position', [100, 100, 1200, 800]);
    
    % 子图1：仓库和客户位置
    subplot(2, 2, 1);
    hold on;
    
    % 绘制所有潜在仓库
    scatter(warehouses.locations(:, 1), warehouses.locations(:, 2), 150, 'square', ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0.7, 0.7, 0.7], 'LineWidth', 1.5);
    
    % 高亮选中的仓库
    scatter(warehouses.locations(selected_warehouses, 1), warehouses.locations(selected_warehouses, 2), ...
        200, 'square', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'red', 'LineWidth', 2);
    
    % 绘制客户
    scatter(customers.locations(:, 1), customers.locations(:, 2), 80, 'o', ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'blue', 'LineWidth', 1);
    
    % 添加标签
    for i = 1:size(warehouses.locations, 1)
        text(warehouses.locations(i, 1) + 2, warehouses.locations(i, 2) + 2, warehouses.names{i}, ...
            'FontSize', 8, 'FontWeight', 'bold');
    end
    
    title('仓库选址结果');
    xlabel('X坐标');
    ylabel('Y坐标');
    legend({'潜在仓库', '选中仓库', '客户'}, 'Location', 'best');
    grid on;
    
    % 子图2：第一个场景的路径
    subplot(2, 2, 2);
    if ~isempty(routes) && ~isempty(routes{1})
        plot_routes_for_scenario(customers, warehouses, routes{1}, 1);
    end
    
    % 子图3：需求分布
    subplot(2, 2, 3);
    scenario_demands = zeros(length(scenarios), length(customers.locations));
    for s = 1:length(scenarios)
        scenario_demands(s, :) = scenarios(s).demand';
    end
    
    boxplot(scenario_demands');
    title('客户需求分布（所有场景）');
    xlabel('客户编号');
    ylabel('需求量');
    
    % 子图4：成本分析
    subplot(2, 2, 4);
    route_costs = zeros(length(routes), 1);
    for s = 1:length(routes)
        route_costs(s) = sum([routes{s}.distance]);
    end
    
    bar(route_costs);
    title('各场景运输成本');
    xlabel('场景编号');
    ylabel('运输成本');
    
    sgtitle('两阶段随机优化结果', 'FontSize', 14, 'FontWeight', 'bold');
end

function plot_routes_for_scenario(customers, warehouses, scenario_routes, scenario_num)
    %% 绘制特定场景的路径
    
    hold on;
    
    % 绘制仓库和客户
    scatter(warehouses.locations(:, 1), warehouses.locations(:, 2), 150, 'square', ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'red', 'LineWidth', 1.5);
    scatter(customers.locations(:, 1), customers.locations(:, 2), 80, 'o', ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'blue', 'LineWidth', 1);
    
    % 绘制路径
    colors = ['r', 'g', 'b', 'm', 'c', 'y', 'k'];
    for r = 1:length(scenario_routes)
        route = scenario_routes{r};
        warehouse_loc = warehouses.locations(route.warehouse, :);
        color = colors(mod(r-1, length(colors)) + 1);
        
        % 从仓库到第一个客户
        if ~isempty(route.customers)
            first_customer_loc = customers.locations(route.customers(1), :);
            plot([warehouse_loc(1), first_customer_loc(1)], [warehouse_loc(2), first_customer_loc(2)], ...
                color, 'LineWidth', 2);
            
            % 客户之间的路径
            for i = 1:length(route.customers)-1
                current_loc = customers.locations(route.customers(i), :);
                next_loc = customers.locations(route.customers(i+1), :);
                plot([current_loc(1), next_loc(1)], [current_loc(2), next_loc(2)], ...
                    color, 'LineWidth', 2);
            end
            
            % 从最后一个客户回到仓库
            last_customer_loc = customers.locations(route.customers(end), :);
            plot([last_customer_loc(1), warehouse_loc(1)], [last_customer_loc(2), warehouse_loc(2)], ...
                color, 'LineWidth', 2, 'LineStyle', '--');
        end
    end
    
    title(sprintf('场景 %d 的配送路径', scenario_num));
    xlabel('X坐标');
    ylabel('Y坐标');
    legend({'仓库', '客户'}, 'Location', 'best');
    grid on;
end

function print_solution_summary(selected_warehouses, total_cost, routes, params)
    %% 打印解决方案摘要
    
    fprintf('\n' + repmat('=', 1, 50) + '\n');
    fprintf('两阶段随机优化结果摘要\n');
    fprintf(repmat('=', 1, 50) + '\n');
    
    fprintf('选择的仓库数量: %d\n', length(selected_warehouses));
    fprintf('选择的仓库编号: %s\n', num2str(selected_warehouses'));
    fprintf('总期望成本: %.2f\n', total_cost);
    
    fprintf('\n场景分析:\n');
    for s = 1:length(routes)
        if ~isempty(routes{s})
            num_routes = length(routes{s});
            total_distance = sum([routes{s}.distance]);
            fprintf('  场景 %d: %d 条路径, 总距离 %.2f\n', s, num_routes, total_distance);
        end
    end
    
    fprintf('\n参数设置:\n');
    fprintf('  客户数量: %d\n', params.num_customers);
    fprintf('  潜在仓库数量: %d\n', params.num_potential_warehouses);
    fprintf('  场景数量: %d\n', params.num_scenarios);
    fprintf('  车辆容量: %d\n', params.vehicle_capacity);
    fprintf('  仓库固定成本: %d\n', params.fixed_cost_warehouse);
    
    fprintf(repmat('=', 1, 50) + '\n');
end