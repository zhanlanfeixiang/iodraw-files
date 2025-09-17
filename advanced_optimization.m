%% 高级两阶段随机优化工具函数
% Advanced utility functions for two-stage stochastic optimization

function [best_solution, all_solutions] = advanced_two_stage_optimization(varargin)
    %% 高级两阶段优化，支持多种算法和参数调优
    
    p = inputParser;
    addParameter(p, 'num_customers', 20, @isnumeric);
    addParameter(p, 'num_potential_warehouses', 5, @isnumeric);
    addParameter(p, 'num_scenarios', 10, @isnumeric);
    addParameter(p, 'warehouse_capacity', 1000, @isnumeric);
    addParameter(p, 'fixed_cost_warehouse', 5000, @isnumeric);
    addParameter(p, 'vehicle_capacity', 100, @isnumeric);
    addParameter(p, 'algorithm', 'greedy', @ischar); % 'greedy', 'genetic', 'simulated_annealing'
    addParameter(p, 'max_iterations', 100, @isnumeric);
    addParameter(p, 'num_runs', 5, @isnumeric); % 多次运行取最优
    addParameter(p, 'plot_results', true, @islogical);
    addParameter(p, 'save_results', false, @islogical);
    
    parse(p, varargin{:});
    params = p.Results;
    
    fprintf('开始高级两阶段随机优化...\n');
    fprintf('算法: %s\n', params.algorithm);
    fprintf('运行次数: %d\n', params.num_runs);
    
    %% 生成问题数据
    [customers, warehouses, scenarios] = generate_problem_data_advanced(params);
    
    %% 多次运行优化
    all_solutions = cell(params.num_runs, 1);
    all_costs = zeros(params.num_runs, 1);
    
    for run = 1:params.num_runs
        fprintf('\n运行 %d/%d...\n', run, params.num_runs);
        
        switch lower(params.algorithm)
            case 'greedy'
                solution = greedy_optimization(customers, warehouses, scenarios, params);
            case 'genetic'
                solution = genetic_algorithm_optimization(customers, warehouses, scenarios, params);
            case 'simulated_annealing'
                solution = simulated_annealing_optimization(customers, warehouses, scenarios, params);
            otherwise
                error('未知算法: %s', params.algorithm);
        end
        
        all_solutions{run} = solution;
        all_costs(run) = solution.total_cost;
    end
    
    %% 选择最优解
    [~, best_idx] = min(all_costs);
    best_solution = all_solutions{best_idx};
    
    fprintf('\n最优解总成本: %.2f\n', best_solution.total_cost);
    fprintf('平均成本: %.2f (标准差: %.2f)\n', mean(all_costs), std(all_costs));
    
    %% 结果可视化和保存
    if params.plot_results
        visualize_advanced_results(customers, warehouses, best_solution, all_solutions, params);
    end
    
    if params.save_results
        save_optimization_results(best_solution, all_solutions, params);
    end
end

function [customers, warehouses, scenarios] = generate_problem_data_advanced(params)
    %% 生成更真实的问题数据
    
    rng(42); % 固定随机种子
    
    %% 客户数据（聚类分布模拟真实城市）
    num_clusters = max(2, floor(params.num_customers / 8));
    cluster_centers = rand(num_clusters, 2) * 100;
    customers.locations = [];
    customers.cluster_id = [];
    
    customers_per_cluster = floor(params.num_customers / num_clusters);
    for i = 1:num_clusters
        if i == num_clusters
            % 最后一个聚类包含剩余所有客户
            remaining_customers = params.num_customers - length(customers.locations);
        else
            remaining_customers = customers_per_cluster;
        end
        
        % 在聚类中心周围生成客户
        cluster_customers = cluster_centers(i, :) + randn(remaining_customers, 2) * 8;
        customers.locations = [customers.locations; cluster_customers];
        customers.cluster_id = [customers.cluster_id; ones(remaining_customers, 1) * i];
    end
    
    customers.names = cellstr(num2str((1:params.num_customers)', 'C%d'));
    
    %% 仓库数据（战略位置）
    warehouses.locations = rand(params.num_potential_warehouses, 2) * 100;
    warehouses.capacity = ones(params.num_potential_warehouses, 1) * params.warehouse_capacity;
    
    % 仓库固定成本根据位置变化
    warehouses.fixed_cost = params.fixed_cost_warehouse * (0.8 + 0.4 * rand(params.num_potential_warehouses, 1));
    warehouses.names = cellstr(num2str((1:params.num_potential_warehouses)', 'W%d'));
    
    %% 随机场景（考虑季节性和趋势）
    scenarios = struct();
    base_demand = 30 + 20 * rand(params.num_customers, 1); % 基础需求
    
    for s = 1:params.num_scenarios
        % 场景特定的需求倍数（模拟季节性变化）
        seasonal_factor = 0.7 + 0.6 * rand(); % 0.7 到 1.3
        demand_noise = 1 + 0.3 * randn(params.num_customers, 1); % 随机噪声
        
        scenarios(s).demand = max(1, round(base_demand .* seasonal_factor .* demand_noise));
        scenarios(s).probability = 1/params.num_scenarios;
        scenarios(s).name = sprintf('Scenario_%d', s);
        scenarios(s).seasonal_factor = seasonal_factor;
    end
    
    fprintf('高级数据生成完成。\n');
    fprintf('  客户聚类数: %d\n', num_clusters);
    fprintf('  平均基础需求: %.2f\n', mean(base_demand));
end

function solution = greedy_optimization(customers, warehouses, scenarios, params)
    %% 贪心算法优化
    
    num_warehouses = size(warehouses.locations, 1);
    
    % 计算所有可能的仓库组合的成本
    best_cost = inf;
    best_warehouses = [];
    best_routes = {};
    
    % 尝试不同数量的仓库
    for num_selected = 1:min(3, num_warehouses) % 最多选择3个仓库
        warehouse_combinations = nchoosek(1:num_warehouses, num_selected);
        
        for i = 1:size(warehouse_combinations, 1)
            selected_warehouses = warehouse_combinations(i, :);
            
            % 计算该组合的成本
            [routes, route_costs] = stage2_route_optimization_advanced(...
                customers, warehouses, selected_warehouses, scenarios, params);
            
            total_cost = calculate_total_cost_advanced(selected_warehouses, route_costs, warehouses, params);
            
            if total_cost < best_cost
                best_cost = total_cost;
                best_warehouses = selected_warehouses;
                best_routes = routes;
            end
        end
    end
    
    solution.selected_warehouses = best_warehouses;
    solution.routes = best_routes;
    solution.total_cost = best_cost;
    solution.algorithm = 'greedy';
end

function solution = genetic_algorithm_optimization(customers, warehouses, scenarios, params)
    %% 遗传算法优化
    
    num_warehouses = size(warehouses.locations, 1);
    population_size = min(50, 2^num_warehouses);
    generations = params.max_iterations;
    
    % 初始化种群
    population = zeros(population_size, num_warehouses);
    for i = 1:population_size
        % 随机选择1-3个仓库
        num_selected = randi([1, min(3, num_warehouses)]);
        selected_indices = randperm(num_warehouses, num_selected);
        population(i, selected_indices) = 1;
    end
    
    best_cost = inf;
    best_solution = [];
    
    for gen = 1:generations
        % 评估种群
        fitness = zeros(population_size, 1);
        for i = 1:population_size
            selected_warehouses = find(population(i, :));
            if ~isempty(selected_warehouses)
                [routes, route_costs] = stage2_route_optimization_advanced(...
                    customers, warehouses, selected_warehouses, scenarios, params);
                fitness(i) = calculate_total_cost_advanced(selected_warehouses, route_costs, warehouses, params);
            else
                fitness(i) = inf;
            end
        end
        
        % 更新最优解
        [min_fitness, min_idx] = min(fitness);
        if min_fitness < best_cost
            best_cost = min_fitness;
            best_solution = population(min_idx, :);
        end
        
        % 选择和繁殖
        [~, sorted_indices] = sort(fitness);
        elite_size = floor(population_size * 0.2);
        new_population = population(sorted_indices(1:elite_size), :);
        
        % 生成新个体
        while size(new_population, 1) < population_size
            % 选择父母
            parent1 = population(sorted_indices(randi(elite_size)), :);
            parent2 = population(sorted_indices(randi(elite_size)), :);
            
            % 交叉
            child = crossover_binary(parent1, parent2);
            
            % 变异
            child = mutate_binary(child, 0.1);
            
            new_population = [new_population; child];
        end
        
        population = new_population;
        
        if mod(gen, 20) == 0
            fprintf('  第 %d 代，最优成本: %.2f\n', gen, best_cost);
        end
    end
    
    selected_warehouses = find(best_solution);
    [routes, ~] = stage2_route_optimization_advanced(...
        customers, warehouses, selected_warehouses, scenarios, params);
    
    solution.selected_warehouses = selected_warehouses;
    solution.routes = routes;
    solution.total_cost = best_cost;
    solution.algorithm = 'genetic';
end

function solution = simulated_annealing_optimization(customers, warehouses, scenarios, params)
    %% 模拟退火算法优化
    
    num_warehouses = size(warehouses.locations, 1);
    
    % 初始解：随机选择仓库
    current_solution = zeros(1, num_warehouses);
    num_selected = randi([1, min(3, num_warehouses)]);
    selected_indices = randperm(num_warehouses, num_selected);
    current_solution(selected_indices) = 1;
    
    selected_warehouses = find(current_solution);
    [routes, route_costs] = stage2_route_optimization_advanced(...
        customers, warehouses, selected_warehouses, scenarios, params);
    current_cost = calculate_total_cost_advanced(selected_warehouses, route_costs, warehouses, params);
    
    best_solution = current_solution;
    best_cost = current_cost;
    
    % 退火参数
    initial_temp = 1000;
    final_temp = 1;
    cooling_rate = 0.95;
    temp = initial_temp;
    
    iteration = 0;
    while temp > final_temp && iteration < params.max_iterations
        iteration = iteration + 1;
        
        % 生成邻域解
        neighbor_solution = generate_neighbor(current_solution);
        selected_warehouses = find(neighbor_solution);
        
        if ~isempty(selected_warehouses)
            [routes, route_costs] = stage2_route_optimization_advanced(...
                customers, warehouses, selected_warehouses, scenarios, params);
            neighbor_cost = calculate_total_cost_advanced(selected_warehouses, route_costs, warehouses, params);
            
            % 接受准则
            delta = neighbor_cost - current_cost;
            if delta < 0 || rand() < exp(-delta / temp)
                current_solution = neighbor_solution;
                current_cost = neighbor_cost;
                
                if current_cost < best_cost
                    best_solution = current_solution;
                    best_cost = current_cost;
                end
            end
        end
        
        temp = temp * cooling_rate;
        
        if mod(iteration, 50) == 0
            fprintf('  迭代 %d，温度: %.2f，最优成本: %.2f\n', iteration, temp, best_cost);
        end
    end
    
    selected_warehouses = find(best_solution);
    [routes, ~] = stage2_route_optimization_advanced(...
        customers, warehouses, selected_warehouses, scenarios, params);
    
    solution.selected_warehouses = selected_warehouses;
    solution.routes = routes;
    solution.total_cost = best_cost;
    solution.algorithm = 'simulated_annealing';
end

% 辅助函数
function child = crossover_binary(parent1, parent2)
    %% 二进制交叉
    crossover_point = randi(length(parent1));
    child = [parent1(1:crossover_point), parent2(crossover_point+1:end)];
end

function mutated = mutate_binary(individual, mutation_rate)
    %% 二进制变异
    mutated = individual;
    for i = 1:length(individual)
        if rand() < mutation_rate
            mutated(i) = 1 - mutated(i);
        end
    end
    % 确保至少选择一个仓库
    if sum(mutated) == 0
        mutated(randi(length(mutated))) = 1;
    end
end

function neighbor = generate_neighbor(solution)
    %% 生成邻域解
    neighbor = solution;
    num_warehouses = length(solution);
    
    % 随机选择操作：添加、删除或替换仓库
    operation = randi(3);
    selected_warehouses = find(solution);
    unselected_warehouses = find(~solution);
    
    switch operation
        case 1 % 添加仓库
            if ~isempty(unselected_warehouses) && length(selected_warehouses) < 3
                new_warehouse = unselected_warehouses(randi(length(unselected_warehouses)));
                neighbor(new_warehouse) = 1;
            end
        case 2 % 删除仓库
            if length(selected_warehouses) > 1
                remove_warehouse = selected_warehouses(randi(length(selected_warehouses)));
                neighbor(remove_warehouse) = 0;
            end
        case 3 % 替换仓库
            if ~isempty(unselected_warehouses) && ~isempty(selected_warehouses)
                remove_warehouse = selected_warehouses(randi(length(selected_warehouses)));
                add_warehouse = unselected_warehouses(randi(length(unselected_warehouses)));
                neighbor(remove_warehouse) = 0;
                neighbor(add_warehouse) = 1;
            end
    end
end

function [routes, route_costs] = stage2_route_optimization_advanced(customers, warehouses, selected_warehouses, scenarios, params)
    %% 改进的第二阶段路径优化
    
    num_scenarios = length(scenarios);
    routes = cell(num_scenarios, 1);
    route_costs = zeros(num_scenarios, 1);
    
    for s = 1:num_scenarios
        current_demand = scenarios(s).demand;
        [routes{s}, route_costs(s)] = solve_vrp_improved(customers, warehouses, ...
            selected_warehouses, current_demand, params);
    end
end

function [scenario_routes, scenario_cost] = solve_vrp_improved(customers, warehouses, selected_warehouses, demand, params)
    %% 改进的VRP求解器
    
    num_customers = length(demand);
    scenario_routes = {};
    scenario_cost = 0;
    unvisited_customers = 1:num_customers;
    
    % 为每个仓库分配客户（基于距离）
    warehouse_assignments = assign_customers_to_warehouses(customers, warehouses, selected_warehouses);
    
    for w = 1:length(selected_warehouses)
        warehouse_idx = selected_warehouses(w);
        assigned_customers = warehouse_assignments{w};
        
        % 只处理分配给该仓库的客户
        warehouse_unvisited = intersect(assigned_customers, unvisited_customers);
        
        while ~isempty(warehouse_unvisited)
            [route, route_cost] = create_single_route(customers, warehouses, warehouse_idx, ...
                warehouse_unvisited, demand, params);
            
            if ~isempty(route)
                scenario_routes{end+1} = route;
                scenario_cost = scenario_cost + route_cost;
                warehouse_unvisited = setdiff(warehouse_unvisited, route.customers);
                unvisited_customers = setdiff(unvisited_customers, route.customers);
            else
                break;
            end
        end
    end
end

function warehouse_assignments = assign_customers_to_warehouses(customers, warehouses, selected_warehouses)
    %% 将客户分配给最近的仓库
    
    num_customers = size(customers.locations, 1);
    warehouse_assignments = cell(length(selected_warehouses), 1);
    
    for c = 1:num_customers
        customer_loc = customers.locations(c, :);
        min_dist = inf;
        assigned_warehouse = 1;
        
        for w = 1:length(selected_warehouses)
            warehouse_idx = selected_warehouses(w);
            warehouse_loc = warehouses.locations(warehouse_idx, :);
            dist = norm(customer_loc - warehouse_loc);
            
            if dist < min_dist
                min_dist = dist;
                assigned_warehouse = w;
            end
        end
        
        warehouse_assignments{assigned_warehouse} = [warehouse_assignments{assigned_warehouse}, c];
    end
end

function [route, route_cost] = create_single_route(customers, warehouses, warehouse_idx, available_customers, demand, params)
    %% 创建单条路径
    
    if isempty(available_customers)
        route = [];
        route_cost = 0;
        return;
    end
    
    warehouse_loc = warehouses.locations(warehouse_idx, :);
    current_route = [];
    current_load = 0;
    current_location = warehouse_loc;
    route_distance = 0;
    remaining_customers = available_customers;
    
    while ~isempty(remaining_customers) && current_load < params.vehicle_capacity
        % 使用最近邻策略
        distances = zeros(length(remaining_customers), 1);
        for i = 1:length(remaining_customers)
            customer_idx = remaining_customers(i);
            customer_loc = customers.locations(customer_idx, :);
            distances(i) = norm(current_location - customer_loc);
        end
        
        [min_dist, min_idx] = min(distances);
        nearest_customer = remaining_customers(min_idx);
        
        if current_load + demand(nearest_customer) <= params.vehicle_capacity
            current_route = [current_route, nearest_customer];
            current_load = current_load + demand(nearest_customer);
            current_location = customers.locations(nearest_customer, :);
            route_distance = route_distance + min_dist;
            remaining_customers(min_idx) = [];
        else
            break;
        end
    end
    
    if ~isempty(current_route)
        % 返回仓库
        return_distance = norm(current_location - warehouse_loc);
        route_distance = route_distance + return_distance;
        
        route.warehouse = warehouse_idx;
        route.customers = current_route;
        route.distance = route_distance;
        route.load = current_load;
        route_cost = route_distance;
    else
        route = [];
        route_cost = 0;
    end
end

function total_cost = calculate_total_cost_advanced(selected_warehouses, route_costs, warehouses, params)
    %% 计算高级总成本
    
    % 仓库固定成本
    fixed_cost = sum(warehouses.fixed_cost(selected_warehouses));
    
    % 期望运输成本
    expected_transport_cost = mean(route_costs);
    
    total_cost = fixed_cost + expected_transport_cost;
end

function visualize_advanced_results(customers, warehouses, best_solution, all_solutions, params)
    %% 高级结果可视化
    
    figure('Position', [100, 100, 1400, 1000]);
    
    % 子图1：最优解的仓库和客户
    subplot(2, 3, 1);
    hold on;
    scatter(warehouses.locations(:, 1), warehouses.locations(:, 2), 150, 'square', ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', [0.7, 0.7, 0.7], 'LineWidth', 1.5);
    scatter(warehouses.locations(best_solution.selected_warehouses, 1), ...
        warehouses.locations(best_solution.selected_warehouses, 2), ...
        200, 'square', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'red', 'LineWidth', 2);
    
    % 根据聚类着色客户
    if isfield(customers, 'cluster_id')
        unique_clusters = unique(customers.cluster_id);
        colors = lines(length(unique_clusters));
        for i = 1:length(unique_clusters)
            cluster_customers = customers.cluster_id == unique_clusters(i);
            scatter(customers.locations(cluster_customers, 1), customers.locations(cluster_customers, 2), ...
                80, 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors(i, :), 'LineWidth', 1);
        end
    else
        scatter(customers.locations(:, 1), customers.locations(:, 2), 80, 'o', ...
            'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'blue', 'LineWidth', 1);
    end
    
    title('最优仓库选址');
    xlabel('X坐标');
    ylabel('Y坐标');
    legend({'潜在仓库', '选中仓库', '客户'}, 'Location', 'best');
    grid on;
    
    % 子图2：成本收敛
    subplot(2, 3, 2);
    all_costs = zeros(length(all_solutions), 1);
    for i = 1:length(all_solutions)
        all_costs(i) = all_solutions{i}.total_cost;
    end
    plot(1:length(all_costs), all_costs, 'o-', 'LineWidth', 2);
    title('多次运行成本分布');
    xlabel('运行次数');
    ylabel('总成本');
    grid on;
    
    % 子图3：第一个场景路径
    subplot(2, 3, 3);
    if ~isempty(best_solution.routes) && ~isempty(best_solution.routes{1})
        plot_routes_for_scenario_advanced(customers, warehouses, best_solution.routes{1}, 1);
    end
    
    % 子图4：仓库选择频率
    subplot(2, 3, 4);
    warehouse_selection_freq = zeros(size(warehouses.locations, 1), 1);
    for i = 1:length(all_solutions)
        warehouse_selection_freq(all_solutions{i}.selected_warehouses) = ...
            warehouse_selection_freq(all_solutions{i}.selected_warehouses) + 1;
    end
    bar(warehouse_selection_freq);
    title('仓库选择频率');
    xlabel('仓库编号');
    ylabel('选择次数');
    
    % 子图5：算法性能比较（如果有多种算法）
    subplot(2, 3, 5);
    algorithms = {};
    algorithm_costs = [];
    for i = 1:length(all_solutions)
        if ~ismember(all_solutions{i}.algorithm, algorithms)
            algorithms{end+1} = all_solutions{i}.algorithm;
        end
        algorithm_costs(end+1) = all_solutions{i}.total_cost;
    end
    
    if length(unique(algorithms)) > 1
        boxplot(algorithm_costs, algorithms);
        title('算法性能比较');
        ylabel('总成本');
    else
        bar(algorithm_costs);
        title(sprintf('算法性能 (%s)', algorithms{1}));
        xlabel('运行次数');
        ylabel('总成本');
    end
    
    % 子图6：成本构成
    subplot(2, 3, 6);
    fixed_cost = sum(warehouses.fixed_cost(best_solution.selected_warehouses));
    route_costs = zeros(length(best_solution.routes), 1);
    for s = 1:length(best_solution.routes)
        if ~isempty(best_solution.routes{s})
            route_costs(s) = sum([best_solution.routes{s}.distance]);
        end
    end
    transport_cost = mean(route_costs);
    
    pie([fixed_cost, transport_cost], {'仓库固定成本', '期望运输成本'});
    title('成本构成');
    
    sgtitle(sprintf('高级两阶段优化结果 (算法: %s)', best_solution.algorithm), ...
        'FontSize', 14, 'FontWeight', 'bold');
end

function plot_routes_for_scenario_advanced(customers, warehouses, scenario_routes, scenario_num)
    %% 高级路径绘制
    
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
        
        if ~isempty(route.customers)
            % 从仓库到第一个客户
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
            
            % 返回仓库
            last_customer_loc = customers.locations(route.customers(end), :);
            plot([last_customer_loc(1), warehouse_loc(1)], [last_customer_loc(2), warehouse_loc(2)], ...
                color, 'LineWidth', 2, 'LineStyle', '--');
        end
    end
    
    title(sprintf('场景 %d 配送路径（高级）', scenario_num));
    xlabel('X坐标');
    ylabel('Y坐标');
    grid on;
end

function save_optimization_results(best_solution, all_solutions, params)
    %% 保存优化结果
    
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    filename = sprintf('optimization_results_%s.mat', timestamp);
    
    results.best_solution = best_solution;
    results.all_solutions = all_solutions;
    results.parameters = params;
    results.timestamp = timestamp;
    
    save(filename, 'results');
    fprintf('结果已保存到: %s\n', filename);
end