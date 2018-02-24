__precompile__()
# integer permutation genetic algorithm
using Base.Iterators.take
Dtype = Float64
Gene  = Vector{Int}
Popu  = Vector{Gene}

function defaultDisturb(gene :: Gene, actualScore :: Dtype)
    return actualScore * (1 + (rand() - 0.5)/100)
end

function newGene(size)
    randperm(size)
end

function mutate!(gene :: Gene, size :: Int)
    loc1, loc2 = rand(1:size), rand(1:size)
    if (loc1 != loc2)
        gene[loc1], gene[loc2] = gene[loc2], gene[loc1]
    end
end

function mutate(gene :: Gene, size :: Int)
    loc1, loc2 = rand(1:size), rand(1:size)
    new_gene = gene[1:end]
    if (loc1 != loc2)
        new_gene[loc1], new_gene[loc2] = new_gene[loc2], new_gene[loc1]
    end
    new_gene
end

function innerCrossOver!(gene :: Gene, size :: Int)
    loc = rand(1:size)
    left = size - loc
    arrBuff = gene[1:loc]
    gene[1:left] = gene[loc+1:end]
    gene[left+1:end] = arrBuff
end

function innerCrossOver(gene :: Gene, size :: Int)
    loc = rand(1:size)
    new_gene = gene[loc+1:end]
    append!(new_gene, gene[1:loc])
    new_gene
end


function ga(gene_length :: Int, fitness :: Function,
            iter = 500, popu_size = 500,
            p_c = 0.02, p_m = 0.05,
            use_disturb :: Any = false)

    popu :: Popu = map(1:popu_size) do _
        newGene(gene_length)
    end

    if use_disturb == false
        fitnessWrap = fitness
    else
        fitnessWrap = x -> disturb(x, fitness(x))
    end

    for iter_num = 1:iter

        sort!(popu, by=fitnessWrap)
        remain_num = trunc(Int, clamp.(rand(), 0.2, 0.5) * popu_size)
        popu = collect(take(popu, remain_num))

        p_m_rand = rand(remain_num-1)
        p_c_rand = rand(remain_num-1)

        half = div(remain_num, 2)

        for i = 1:half - 1
            gene = popu[half + i + 1]
            # mutate vary
            will_m = p_m_rand[i] > p_m
            will_c = p_c_rand[i] > p_c
            if will_m
                mutate!(gene, gene_length)
            end
            # (inner) cross over vary
            if will_c
                innerCrossOver!(gene, gene_length)
            end

            # ntr
            if !will_c && !will_m
                master = popu[i+1]
                if rand() > 0.5
                    popu[half + i + 1] = mutate(master, gene_length)
                else
                    popu[half + i + 1] = innerCrossOver(master, gene_length)
                end
            end
        end

        # generate new genes to fill population
        new_borned = map(1:popu_size - remain_num) do _
            newGene(gene_length)
        end |> it -> append!(popu, it)

    end
    println(popu[end], fitness(popu[end]))
    (popu[1], fitness(popu[1]))

end


X = [34, 56, 27, 44, 4, 10, 55, 14, 28, 12, 16, 68, 24, 29,49, 51, 45, 78, 82, 32, 95, 53,
     7, 64, 88, 23, 87, 34, 71, 98]
Y = [57, 64, 82, 94, 18, 64, 69, 30, 54, 70, 40, 46, 82, 38, 15, 26, 31, 56,
          33, 11, 8,  46, 94, 62, 52, 61, 76, 58, 41, 69]

Map = collect(zip(X, Y))
# Map = [
#     (100, 200),
#     (50, 70),
#     (40, 20),
#     (9, 200),
#     (170, 33),
#     (110, 120),
#     (300, 120),
#     (200, 70),
#     (180, 50)
# ]

indexOfMap = x -> getindex(Map, x)
function TSP(pathIndex)
    roadLen = 0
    path = map(indexOfMap, pathIndex)
    start = path[1]
    for next in path[2:end]
        x1, y1 = start
        x2, y2 = next
        roadLen += hypot(x2-x1, y2-y1)
        start = next
    end
    roadLen
end

route, score = ga(size(Map)[1], TSP, 700, 1000, 0.15, 0.25)

X! = X[route]
Y! = Y[route]
using Gadfly
points = plot(x=X!, y=Y!,  Geom.point, Geom.line)
Gadfly.add_plot_element!(points, Guide.title("the length of route: $score"))
draw(SVG("genetic.svg", 5inch, 3inch), points)
