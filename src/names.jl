## names.jl retrieve and set dimension names
## (c) 2013 David A. van Leeuwen

## This code is licensed under the GNU General Public License, version 2
## See the file LICENSE in this distribution## access to the names of the dimensions

import Base.names

sortnames(dict::Dict) = String[string(k) for k in keys(dict)][sortperm(collect(values(dict)))] 
allnames(a::NamedArray) = [sortnames(dict) for dict in a.dicts]
names(a::NamedArray, d::Int) = sortnames(a.dicts[d])
dimnames(a::NamedArray) = String[string(dn) for dn in a.dimnames]
dimnames(a::NamedArray, d::Int) = string(a.dimnames[d])

## seting names, dimnames
function setnames!(a::NamedArray, v::Vector, d::Int)
    @assert size(a.array,d) == length(v)
    ## a.dicts is a tuple, so we need to replace it as a whole...
    vdicts = Dict[]
    for i = 1:length(a.dicts)
        if i==d
            push!(vdicts, Dict(zip(v, 1:length(v))))
        else
            push!(vdicts, a.dicts[i])
        end
    end
    a.dicts = tuple(vdicts...)
end

function setnames!(a::NamedArray, v, d::Int, i::Int)
    @assert 1 <= d <= ndims(a)
    @assert 1 <= i <= size(a, d)
    filter!((k,v) -> v!=i, a.dicts[d]) # remove old name
    a.dicts[d][v] = i
end

function setdimnames!{T,N}(a::NamedArray{T,N}, dn::NTuple{N})
    a.dimnames = dn
end
    
function setdimnames!{T,N}(a::NamedArray{T,N}, v, d::Int)
    @assert 1 <= d <= N
    vdimnames = Array(Any, N)
    for i=1:N
        if i==d
            vdimnames[i] = v
        else
            vdimnames[i] = a.dimnames[i]
        end
    end
    a.dimnames = tuple(vdimnames...)
end
