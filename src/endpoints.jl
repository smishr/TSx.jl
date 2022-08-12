"""
# Computing end points
```julia
endpoints(ts::TS, on::T, k::Int=1) where {T<:Union{Symbol, String}}
endpoints(ts::TS, on::Function, k::Int=1)
```

Return index values for last observation in `ts` for the period given
by `on` every `k` instance. Can be used to subset a `TS` object
directly using it's return value.

Valid values for `on` are: `:years`, `:quarters`, `:months`, `:weeks`,
and `:days`. `on` can also take a `Function` which should return a
tuple to be used as a grouping key. The last observation of each
unique group is returned. See the weekly example below to see how the
function works in real world.

`ts` is first converted into the groups provided by `on` then the
last observation is picked up every `k^th` instance. For example,
`k=2` picks every alternate group out of the ones created by `on`.

The method returns `Vector{Int}` corresponding to the matched values
in `Index`.

# Examples
```jldoctest; setup = :(using TSx, DataFrames, Dates, Random, Statistics)
julia> using Random
julia> random(x) = rand(MersenneTwister(123), x);
julia> dates = Date(2017):Day(1):Date(2019);
julia> ts = TS(random(length(dates)), dates)
(731 x 1) TS with Date Index

 Index       x1
 Date        Float64
───────────────────────
 2017-01-01  0.768448
 2017-01-02  0.940515
 2017-01-03  0.673959
 2017-01-04  0.395453
 2017-01-05  0.313244
 2017-01-06  0.662555
 2017-01-07  0.586022
 2017-01-08  0.0521332
 2017-01-09  0.26864
 2017-01-10  0.108871
     ⋮           ⋮
 2018-12-24  0.812797
 2018-12-25  0.158056
 2018-12-26  0.269285
 2018-12-27  0.15065
 2018-12-28  0.916177
 2018-12-29  0.278016
 2018-12-30  0.617211
 2018-12-31  0.67549
 2019-01-01  0.910285
       712 rows omitted

julia> ep = endpoints(ts, :months, 1)
25-element Vector{Int64}:
  31
  59
  90
 120
 151
 181
 212
 243
 273
 304
 334
 365
 396
 424
 455
 485
 516
 546
 577
 608
 638
 669
 699
 730
 731

julia> ts[ep]
(25 x 1) TS with Date Index

 Index       x1
 Date        Float64
───────────────────────
 2017-01-31  0.48
 2017-02-28  0.458476
 2017-03-31  0.274441
 2017-04-30  0.413966
 2017-05-31  0.734931
 2017-06-30  0.257159
 2017-07-31  0.415851
 2017-08-31  0.0377973
 2017-09-30  0.934059
 2017-10-31  0.413175
 2017-11-30  0.557009
 2017-12-31  0.346659
 2018-01-31  0.174777
 2018-02-28  0.432223
 2018-03-31  0.835142
 2018-04-30  0.945539
 2018-05-31  0.0635483
 2018-06-30  0.589922
 2018-07-31  0.285088
 2018-08-31  0.912558
 2018-09-30  0.238931
 2018-10-31  0.49775
 2018-11-30  0.830232
 2018-12-31  0.67549
 2019-01-01  0.910285

julia> diff(index(ts[ep]))
24-element Vector{Day}:
 28 days
 31 days
 30 days
 31 days
 30 days
 31 days
 31 days
 30 days
 31 days
 30 days
 31 days
 31 days
 28 days
 31 days
 30 days
 31 days
 30 days
 31 days
 31 days
 30 days
 31 days
 30 days
 31 days
 1 day

# with k=2
julia> ep = endpoints(ts, :months, 2)
12-element Vector{Int64}:
  59
 120
 181
 243
 304
 365
 424
 485
 546
 608
 669
 730

julia> ts[ep]
(12 x 1) TS with Date Index

 Index       x1
 Date        Float64
───────────────────────
 2017-02-28  0.458476
 2017-04-30  0.413966
 2017-06-30  0.257159
 2017-08-31  0.0377973
 2017-10-31  0.413175
 2017-12-31  0.346659
 2018-02-28  0.432223
 2018-04-30  0.945539
 2018-06-30  0.589922
 2018-08-31  0.912558
 2018-10-31  0.49775
 2018-12-31  0.67549

julia> diff(index(ts[ep]))
11-element Vector{Day}:
 61 days
 61 days
 62 days
 61 days
 61 days
 59 days
 61 days
 61 days
 62 days
 61 days
 61 days

# Weekly points are implemented internally like this
julia> endpoints(ts, i -> [(year(x), Dates.week(x)) for x in i], 1)
105-element Vector{Int64}:
 365
   8
  15
  22
  29
  36
  43
  50
  57
  64
  71
   ⋮
 666
 673
 680
 687
 694
 701
 708
 715
 722
 729
 731
```
"""
function endpoints(ts::TS, on::T, k::Int=1) where {T<:Union{Symbol, String}}
    if (on == :days || on == "days")
        endpoints(ts, i -> Dates.yearmonthday.(i), k)
    elseif (on == :weeks || on == "weeks")
        endpoints(ts, i -> [(year(x), Dates.week(x)) for x in i], k)
    elseif (on == :months || on == "months")
        endpoints(ts, i -> Dates.yearmonth.(i), k)
    elseif (on == :quarters || on == "quarters")
        endpoints(ts, i -> [(year(x), Dates.quarterofyear(x)) for x in i], k)
    elseif (on == :years || on == "years")
        endpoints(ts, i -> Dates.year.(i), k)
    else
        error("unsupported value supplied to `on`")
    end
end

function endpoints(ts::TS, on::Function, k::Int=1)
    ii = index(ts)
    ex = Expr(:call, on, ii)
    new_index = eval(ex)
    new_index_unique = unique(new_index)
    points = new_index_unique[k:k:length(new_index_unique)]
    [findlast([p] .== new_index) for p in points]
end
