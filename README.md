NamedArrays
===========

Julia type that implements a drop-in replacement of Array with named dimensions.

[![Build Status](https://travis-ci.org/davidavdav/NamedArrays.jl.svg)](https://travis-ci.org/davidavdav/NamedArrays.jl)
[![NamedArrays](http://pkg.julialang.org/badges/NamedArrays_0.5.svg)](http://pkg.julialang.org/?pkg=NamedArrays)
[![NamedArrays](http://pkg.julialang.org/badges/NamedArrays_0.6.svg)](http://pkg.julialang.org/?pkg=NamedArrays)
[![Coverage Status](https://coveralls.io/repos/github/davidavdav/NamedArrays.jl/badge.svg?branch=master)](https://coveralls.io/github/davidavdav/NamedArrays.jl?branch=master)

Idea
----

We would want to have the possibility to give each row/column/... in
an Array names, as well as the array dimensions themselves.  This
could be used for pretty-printing, indexing, and perhaps even some
sort of dimension-checking in certain matrix computations.

In all other respects, a NamedArray should be the same as an Array.

Synopsis
--------

```julia
using NamedArrays
n = NamedArray(rand(2,4))
setnames!(n, ["one", "two"], 1)         # give the names "one" and "two" to the rows (dimension 1)
n["one", 2:3]
n["two", :] = 11:14
n[Not("two"), :] = 4:7                      # all rows but the one called "two"
n
sum(n,1)
```

Construction
-------

```julia
# NamedArray(a::Array)
x = NamedArray([1 2; 3 4])
# NamedArray{T}(dims...)
x = NamedArray{Int}(2, 2)
```

these constructors add default names to the array of type String, "1",
"2", ... for each dimension, and names the dimensions `:A`, `:B`,
... (which will be all right for 26 dimensions to start with; 26
dimensions should be enough for anyone:-).  The former initializes
the NamedArray with the Array `a`, the latter makes an uninitialized
NamedArray of element type `T` with the specified dimensions `dims...`.

```julia
# NamedArray{T,N}(a::Array{T,N}, names::NTuple{N,Dict}, dimnames::NTuple{N})
x = NamedArray([1 3; 2 4], ( ["A"=>1,"B"=>2], ["C"=>1,"D"=>2] ), ("ROWS","COLS"))
```
This is the basic constructor for a namedarray.  `names` must be a tuple of `Dict`s whose range (the values) are exacly covering the range `1:size(a,dim)` for each dimension `dim`.   The keys in the various dictionaries may be of mixed types, but after initialization, the type of the names cannot be altered.  `dimnames` specify the names of the dimensions themselves, and may be of any type.

```julia
# NamedArray{T,N}(a::Array{T,N}, names::NTuple{N,Vector}, dimnames::NTuple{N})
x = NamedArray([1 3; 2 4], ( ["A","B"], ["C","D"] ), ("ROWS","COLS"))
# NamedArray{T,N}(a::Array{T,N}, names::NTuple{N,Vector})
x = NamedArray([1 3; 2 4], ( ["A","B"], ["C","D"] ))
```
This is a more friendly version of the basic constructor, where the range of the dictionaries is automatically assigned the values `1:size(a,dim)` for the `names` in order. If `dimnames` is not specified, the default values will be used (`:A`, `:B`, etc.).

In principle, there is no limit imposed to the type of the `names` used, but we discourage the use of `Real`, `AbstractArray` and `Range`, because they have a special interpretation in `getindex()` and `setindex`.

Indexing
------
```julia
n[1,1]
n[1,:]
n["label",2]
n[1:10, Not("label")]
n[[2,4,6], ["a", "b", "d"]
```

This is the main use of `NamedArrays`.  As an index, not only integers, arrays of integer and ranges can be given, but also names (keys), arrays of keys and negations of any of any of these can be specified.

 When a single element is selected by an index expression, a scalar value is returned.  When an array slice is selected, an attempt is made to return a NamedArray with the correct names for the dimensions.

### Negation / complement

```julia
n[Not(1),:]]
```

There is a special type constructor `Not()`, whose function is to specify which elements to exclude from the array.  This is similar to negative indices in the language R.  The elements in `Not(elements...)` select all but the indicated elements from the array.

Both integers and names can be negated.

```julia
n[Not("one"), :]
```

### Dictionary-style indexing

You can also use a dictionary-style indexing, if you don't want to bother about the order of the dimensions:
```julia
n[:B=>"b", :A=>"one"]
```
This style cannot be mixed with other indexing styles, yet.

### Assignment

Most index types can be used for assignment as LHS
```julia
n[1,1] = 0
n["one", "b"] = 1
n[:,"c"] = 1:4
n[:B=>"c", :A=>"two"] = 5
```

General functions
--

 * Names, dimnames

```julia
allnames(a::NamedArray)
names(a::NamedArray, dim)
dimnames(a::NamedArray)
```

 return the names of the indices along dimension `dim` and the names of the dimensions themselves.

 ```julia
 setnames!(a::NamedArray, names::Vector, dim::Int)
 setnames!(a::NamedArray, name, dim::Int, index:Int)
 setdimnames!(a::NamedArray, name, dim:Int)
 ```

sets all the names of dimension `dim`, or only the name at index `index`, or the name of the dimension `dim`.

 * Copy

```julia
copy(a::NamedArray)
```

returns a copy of all the elements in a, and returns a NamedArray

 * Convert

```julia
convert(::Type{Array}, a::NamedArray)
```

 converts a NamedArray to an Array by dropping all name information

```julia
convert{T}(::Type{NamedArray{T}}, a::NamedArray)
float32(a)
float64(a)
```
 converts the element type of a NamedArray

 * Arithmetic:
  - between NamedArray and NamedArray
  - between NamedArray and Array
  - between NamedArray and Number
    - `+`, `-`, `.+`, `.-`, `.*`, `./`
  - between NamedArray and Number
    - `*`, `/`, `\`
  - Matrix Multiplication `*` between NamedArray and NamedArray

 * `print`, `show`:
  - basic printing, limited support for pretty-printing.

 * `size`, `ndims`, `eltype`

 * Similar

```julia
similar(a::NamedArray, t::DataType, dims::NTuple)
```

Methods with special treatment of names / dimnames
--------------------------------------------------

 * Concatenation

```julia
hcat(V::NamedVector...)
```

 concatenates (column) vectors to an array.  If the names are identical
for all vectors, these are retained in the results.  Otherwise
the names are reinitialized to the default "1", "2", ...

 * Transposition

```julia
' ## transpose post-fix operator '
ctranspose
transpose
permutedims
circshift
```

 operate on the dimnames as well

 * Reordering of dimensions in NamedVectors

```julia
nthperm
nthperm!
permute!
shuffle
shuffle!
reverse
reverse!
```

 operate on the names of the rows as well


 * Broadcasts

```julia
broadcast
broadcast!
```

 these functions check consistency of the names of dimensions `d` with `length(d)>1`, and performs the normal `broadcast`

 * Aggregates

```julia
sum
prod
maximum
minimum
mean
std
```

 These functions, when operating along one dimension, keep the names in the orther dimensions, and name the left over singleton dimension as `$function($dimname)`.

Methods that AbstractArray covers
---------------------------

Some methods work automatically with NamedArrays courtesy of the super
type AbstractArray.  However, they may not treat the names attributes
correctly

```julia
a::NamedArray
b::NamedArray
d::Int
function f
sum(a)
prod(a)
isequal(a,b)
==(a, b)
cumsum(a)
cumsum(a, d)
cumprod(a)
cumprod(a, d)
maximum(a)
eltype(a)
cummin(a)
cummin(a, d)
cummax(a)
cummanx(a, d)
repmat(a, d1, d2)
nnz(a)
minimum(a)
mapslices(f, a, d)
map(f, a)
```

Implementation
------------

Currently, the type is defined as

```julia
type NamedArray{T,N,AT,DT} <: AbstractArray{T,N}
    array::AT
    dicts::DT
    dimnames::NTuple{N, Any}
end
```

but the inner constructor actually expects `NTuple`s for `dicts` and `dimnames`, which more easily allows somewhat stricter typechecking.   This is sometimes a bit annoying, if you want to initialize a new NamedArray from known `dicts` and `dimnames`.  You can use the expression `tuple(Vector...)` for that.
