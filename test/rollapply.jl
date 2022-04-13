DATA_SIZE = 360
index_timetype = Date(2000, 1,1) + Day.(0:(DATA_SIZE - 1))
vec1 = randn(DATA_SIZE)
vec2 = randn(DATA_SIZE)
vec3 = randn(DATA_SIZE)
df = DataFrame(Index = index_timetype, vec1 = vec1,vec2 = vec2, vec3 = vec3)
ts = TS(df, 1)

functions = [mean, median, sum, minimum, maximum, std]
cols = [2, 3, :vec1, :vec3]          # col 1 is index
windowsize = [1, 5, 100, DATASIZE]

@test typeof(TSx.rollapply(mean, ts, 2, 5)) == TSx.TS

for fun in functions
    res = @test TSx.rollapply(fun, ts, 2, 5).coredata[!, 2] == RollingFunctions.rolling(fun, df[!, 2], 5)
    print(res)
end

for fun in functions
    res = @test TSx.rollapply(fun, ts, :vec1, 5).coredata[!, :vec1] == RollingFunctions.rolling(fun, df[!, :vec1], 5)
    print(res)
end

for fun in functions
    res = @test TSx.rollapply(fun, ts, :vec3, 100).coredata[!, :vec3] == RollingFunctions.rolling(fun, df[!, :vec3], 100)
    print(res)
end

for fun in functions
    res = @test TSx.rollapply(fun, ts, :vec3, DATA_SIZE).coredata[!, :vec3] == RollingFunctions.rolling(fun, df[!, :vec3], DATA_SIZE)
    print(res)
end




















for fun in functions
    @ts_test(fun, 1, 1).coredata[!, 2] == RollingFunctions.rolling(fun, df[!, 1], 1)
end


for fun in functions
    @ts_test(fun, 3, 100).coredata[!,2] == RollingFunctions.rolling(fun, df[!, 3], 100)
end

for fun in functions
    @ts_test(fun, :vec1, 100).coredata[!,2] == RollingFunctions.rolling(fun, df[!, :vec1], 100)
end

for fun in functions
    @ts_test(fun, :vec3, DATA_SIZE).coredata[!,2] == RollingFunctions.rolling(fun, df[!, :vec3], DATA_SIZE)
end



