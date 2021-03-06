## arithmetic.jl operators for NamedArray

## (c) 2013--2014 David A. van Leeuwen

## This code is licensed under the MIT License
## See the file LICENSE.md in this distribution

import Base: +, -, *, /, \
if VERSION < v"0.6.0-dev.1632"
    import Base: .+, .-, .*, ./, \
end

-(n::NamedArray) = NamedArray(-n.array, n.dicts, n.dimnames)

## disambiguation magic
if VERSION < v"0.6.0-dev.1632"
    @eval begin
        .*(n::NamedArray{Bool}, b::BitArray) = NamedArray(n.array .* b, n.dicts, n.dimnames)
        .*{N}(n::NamedArray{Bool,N}, b::BitArray{N}) = NamedArray(n.array .* b, n.dicts, n.dimnames)
        .*{N}(b::BitArray{N}, n::NamedArray{Bool,N}) = n .* b
    end
end

# disambiguation (Argh...)
for op in (:+, :-)
    @eval ($op){T1<:Number,T2<:Number}(x::Range{T1}, y::NamedVector{T2}) = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    @eval ($op){T1<:Number,T2<:Number}(x::NamedVector{T1}, y::Range{T2}) = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
end

if VERSION < v"0.6.0-dev.1632"
    for op in (:.+, :.-, :.*, :./)
        @eval begin
            function ($op){T1<:Number, T2<:Number}(x::NamedArray{T1}, y::NamedArray{T2})
                if names(x) == names(y) && x.dimnames == y.dimnames
                    NamedArray(($op)(x.array, y.array), x.dicts, x.dimnames)
                else
                    warn("Dropping mismatching names")
                    ($op)(x.array, y.array)
                end
            end
            ($op){T1<:Number,T2<:Number,N}(x::NamedArray{T1,N}, y::AbstractArray{T2,N}) = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
            ($op){T1<:Number,T2<:Number,N}(x::AbstractArray{T1,N}, y::NamedArray{T2,N}) = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
        end
    end
end

for op in (:+, :-)
    ## named %op% named
    @eval begin
        function ($op){T1<:Number, T2<:Number}(x::NamedArray{T1}, y::NamedArray{T2})
            if names(x) == names(y) && x.dimnames == y.dimnames
                NamedArray(($op)(x.array, y.array), x.dicts, x.dimnames)
            else
                warn("Dropping mismatching names")
                ($op)(x.array, y.array)
            end
        end
        ($op){T1<:Number,T2<:Number,N}(x::NamedArray{T1,N}, y::AbstractArray{T2,N}) = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
        ($op){T1<:Number,T2<:Number,N}(x::AbstractArray{T1,N}, y::NamedArray{T2,N}) = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    end
end

## scalar arithmetic
## disambiguate
for op in (:+, :-)
    @eval begin
        ($op)(x::NamedArray{Bool}, y::Bool) = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
        ($op)(x::Bool, y::NamedArray{Bool}) = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    end
end

## NamedArray, Number
if VERSION < v"0.6.0-dev.1632"
    for op in (:.+, :.-, :.*, :./)
        @eval begin
            ($op){T1<:Number,T2<:Number}(x::NamedArray{T1}, y::T2) = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
            ($op){T1<:Number,T2<:Number}(x::T1, y::NamedArray{T2}) = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
        end
    end
end

for op in (:+, :-, :*)
    @eval begin
        ($op){T1<:Number,T2<:Number}(x::NamedArray{T1}, y::T2) = NamedArray(($op)(x.array, y), x.dicts, x.dimnames)
        ($op){T1<:Number,T2<:Number}(x::T1, y::NamedArray{T2}) = NamedArray(($op)(x, y.array), y.dicts, y.dimnames)
    end
end
/{T1<:Number,T2<:Number}(x::NamedArray{T1}, y::T2) = NamedArray(x.array / y, x.dicts, x.dimnames)
\{T1<:Number,T2<:Number}(x::T1, y::NamedArray{T2}) = NamedArray(x \ y.array, y.dicts, y.dimnames)

import Base: A_mul_B!, A_mul_Bc!, A_mul_Bc, A_mul_Bt!, A_mul_Bt, Ac_mul_B, Ac_mul_B!, Ac_mul_Bc, Ac_mul_Bc!, At_mul_B, At_mul_B!, At_mul_Bt, At_mul_Bt!

## Assume dimensions/names are correct
for op in (:A_mul_B!, :A_mul_Bc!, :A_mul_Bt!, :Ac_mul_B!, :Ac_mul_Bc!, :At_mul_B!, :At_mul_Bt!)
    @eval ($op)(C::NamedMatrix, A::AbstractMatrix, B::AbstractMatrix) = ($op)(C.array, A, B)
end

for op in (:A_mul_Bc, :A_mul_Bt)
    @eval ($op)(A::NamedMatrix, B::NamedMatrix) = NamedArray(($op)(A.array, B.array), (A.dicts[1], B.dicts[1]), (A.dimnames[1], B.dimnames[1]))
    for T in [Union{Base.LinAlg.QRCompactWYQ, Base.LinAlg.QRPackedQ}, StridedMatrix, AbstractMatrix] ## v0.4 ambiguity-hell
        @eval ($op)(A::NamedMatrix, B::$T) = NamedArray(($op)(A.array, B), (A.dicts[1], defaultnamesdict(size(B,1))), (A.dimnames[1], :B))
        @eval ($op)(A::$T, B::NamedMatrix) = NamedArray(($op)(A, B.array), (defaultnamesdict(size(A,1)), B.dicts[1]), (:A, B.dimnames[1]))
    end
end
for op in (:Ac_mul_B, :At_mul_B)
    @eval ($op)(A::NamedMatrix, B::NamedMatrix) = NamedArray(($op)(A.array, B.array), (A.dicts[2], B.dicts[2]), (A.dimnames[2], B.dimnames[2]))
    for T in [StridedMatrix, AbstractMatrix] ## v0.4 ambiguity-hell
        @eval ($op)(A::NamedMatrix, B::$T) = NamedArray(($op)(A.array, B), (A.dicts[2], defaultnamesdict(size(B,2))), (A.dimnames[2], :B))
        @eval ($op)(A::$T, B::NamedMatrix) = NamedArray(($op)(A, B.array), (defaultnamesdict(size(A,2)), B.dicts[2]), (:A, B.dimnames[2]))
    end
end
for op in (:Ac_mul_Bc, :At_mul_Bt)
    @eval ($op)(A::NamedMatrix, B::NamedMatrix) = NamedArray(($op)(A.array, B.array), (A.dicts[2], B.dicts[1]), (A.dimnames[2], B.dimnames[1]))
    for T in [StridedMatrix, AbstractMatrix] ## v0.4 ambiguity-hell
        @eval ($op)(A::NamedMatrix, B::$T) = NamedArray(($op)(A.array, B), (A.dicts[2], defaultnamesdict(size(B,1))), (A.dimnames[2], :B))
        @eval ($op)(A::$T, B::NamedMatrix) = NamedArray(($op)(A, B.array), (defaultnamesdict(size(A,2)), B.dicts[1]), (:A, B.dimnames[1]))
    end
end

import Base.LinAlg: Givens, BlasFloat, lufact!, LU, ipiv2perm, cholfact!, cholfact, qrfact!, qrfact, eigfact!, eigfact, eigvals!,
    eigvals, hessfact, hessfact!, schurfact!, schurfact, svdfact!, svdfact, svdvals!, svdvals, svd, diag, diagm, scale!,
    cond, kron, linreg, lyap, sylvester, isposdef

## matmul
## ambiguity, this can somtimes be a pain to resolve...
*{Tx,TiA,Ty}(x::SparseMatrixCSC{Tx,TiA},y::NamedMatrix{Ty}) = x*y.array
*{Tx,S,Ty}(x::SparseMatrixCSC{Tx,S},y::NamedVector{Ty}) = x*y.array
for t in (:Tridiagonal, :(LinAlg.AbstractTriangular), :Givens, :Bidiagonal)
    @eval *(x::$t, y::NamedMatrix) = NamedArray(x*y.array, ([string(i) for i in 1:size(x,1)],names(y,2)), y.dimnames)
    @eval *(x::$t, y::NamedVector) = x*y.array
end

## There is no such thing as a A_mul_B
## Named * Named
*(A::NamedMatrix, B::NamedMatrix) = NamedArray(A.array * B.array, (A.dicts[1], B.dicts[2]), (A.dimnames[1], B.dimnames[2]))
*(A::NamedMatrix, B::NamedVector) = NamedArray(A.array * B.array, (A.dicts[1],), (B.dimnames[1],))
if isdefined(Base, :RowVector)
    *(A::NamedRowVector, B::NamedVector) = A.array * B.array
end
## Named * Abstract
*(A::NamedMatrix, B::AbstractMatrix) = NamedArray(A.array * B, (A.dicts[1], defaultnamesdict(size(B,2))), A.dimnames)
*(A::AbstractMatrix, B::NamedMatrix) = NamedArray(A * B.array, (defaultnamesdict(size(A,1)), B.dicts[2]), B.dimnames)
*(A::NamedMatrix, B::AbstractVector) = NamedArray(A.array * B, (A.dicts[1],), (A.dimnames[1],))
*(A::AbstractMatrix, B::NamedVector) = A * B.array
if isdefined(Base, :RowVector)
    *(A::NamedRowVector, B::AbstractVector) = A.array * B
end
## \ --- or should we overload A_div_B?
## Named \ Named
\(x::NamedVector, y::NamedVector) = x.array \ y.array
\(x::NamedMatrix, y::NamedVector) = NamedArray(x.array\y.array, (names(x,2),), (x.dimnames[2],))
\(x::NamedVector, y::NamedMatrix) = NamedArray(x.array\y.array, (["1"],names(y,2)), (:A, y.dimnames[2]))
\(x::NamedMatrix, y::NamedMatrix) = NamedArray(x.array\y.array, (names(x,2),names(y,2)), (x.dimnames[2], y.dimnames[2]))

## Named \ Abstract
\(x::NamedVector, y::AbstractVecOrMat) = x.array \ y
\(x::NamedMatrix, y::AbstractVector) = NamedArray(x.array \ y, (x.dicts[2],), (x.dimnames[2],))
\(x::NamedMatrix, y::AbstractMatrix) = NamedArray(x.array \ y, (names(x,2),[string(i) for i in 1:size(y,2)]), (x.dimnames[2],:B))
## Abstract \ Named
## ambiguity
\{Tx<:Number,Ty<:Number}(x::Diagonal{Tx}, y::NamedVector{Ty}) = x \ y.array
\{Tx<:Number,Ty<:Number}(x::Union{Bidiagonal{Tx},LinAlg.AbstractTriangular{Tx}}, y::NamedVector{Ty}) = x \ y.array
\{Tx<:Number,Ty<:Number}(x::Union{Bidiagonal{Tx},LinAlg.AbstractTriangular{Tx}}, y::NamedMatrix{Ty}) = NamedArray(x \ y.array, (defaultnamesdict(size(x,1)), y.dicts[2]), (:A, y.dimnames[2]))

\(x::Bidiagonal,y::NamedVector) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y,2)), (:A, y.dimnames[2]))
\(x::Bidiagonal,y::NamedMatrix) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y,2)), (:A, y.dimnames[2]))

## AbstractVectorOrMat gives us more ambiguities than separate entries...
\(x::AbstractVector, y::NamedVector) = x \ y.array
\(x::AbstractMatrix, y::NamedVector) = x \ y.array
\(x::AbstractVector, y::NamedMatrix) = NamedArray(x \ y.array, (["1"],names(y,2)), (:A, y.dimnames[2]))
\(x::AbstractMatrix, y::NamedMatrix) = NamedArray(x \ y.array, ([string(i) for i in 1:size(x,2)], names(y,2)), (:A, y.dimnames[2]))

## keeping names for some matrix routines
for f in (:inv, :chol, :sqrtm, :pinv, :expm)
    eval(Expr(:import, :Base, f))
    @eval ($f)(n::NamedArray) = NamedArray(($f)(n.array), n.dicts, n.dimnames)
end

## tril, triu
Base.tril!(n::NamedMatrix, k::Integer) = (tril!(n.array, k); n)
Base.triu!(n::NamedMatrix, k::Integer) = (triu!(n.array, k); n)

## LU factorization
function lufact!{T}(n::NamedArray{T}, pivot::Union{Type{Val{false}}, Type{Val{true}}} = Val{true})
    luf = lufact!(n.array, pivot)
    LU{T,typeof(n),}(n, luf.ipiv, luf.info)
end

## after lu.jl, this could be merged at Base.
function Base.getindex{T,DT,AT}(A::LU{T,NamedArray{T,2,AT,DT}}, d::Symbol)
    m, n = size(A)
    if d == :L
        L = tril!(A.factors[1:m, 1:min(m,n)])
        for i = 1:min(m,n); L[i,i] = one(T); end
        setnames!(L, defaultnames(L,2), 2)
        setdimnames!(L, :LU, 2)
        return L
    end
    if d == :U
        U = triu!(A.factors[1:min(m,n), 1:n])
        setnames!(U, defaultnames(U,1), 1)
        setdimnames!(U, :LU, 1)
        return U
    end
    d == :p && return ipiv2perm(A.ipiv, m)
    if d == :P
        p = A[:p]
        P = zeros(T, m, m)
        for i in 1:m
            P[i,p[i]] = one(T)
        end
        return P
    end
    throw(KeyError(d))
end


function cholfact!{T<:BlasFloat}(n::NamedArray{T}, uplo::Symbol=:U)
    ishermitian(n) || LinAlg.non_hermitian_error("cholfact!")
    return cholfact!(Hermitian(n, uplo))
end

cholfact{T<:BlasFloat}(n::NamedArray{T}, uplo::Symbol=:U) = cholfact!(copy(n), uplo)

## ldlt skipped

## from factorization
function qrfact!{T<:BlasFloat}(n::NamedMatrix{T}, pivot::Union{Type{Val{false}}, Type{Val{true}}} = Val{false})
    qr = qrfact!(n.array, pivot)
    LinAlg.QRCompactWY(NamedArray(qr.factors, n.dicts, n.dimnames), qr.T)
end
LAPACK.gemqrt!{BF<:BlasFloat}(side::Char, trans::Char, V::NamedArray{BF}, T::StridedMatrix{BF}, C::StridedVecOrMat{BF}) = LAPACK.gemqrt!(side, trans, V.array, T, C)

qrfact{T<:BlasFloat}(n::NamedMatrix{T}, pivot::Union{Type{Val{false}}, Type{Val{true}}} = Val{false}) = qrfact!(copy(n), pivot)

eigfact!(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigfact!(n.array, permute=permute, scale=scale)
eigfact(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigfact!(copy(n.array), permute=permute, scale=scale)

eigvals!(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigvals!(n.array, permute=permute, scale=scale)
eigvals(n::NamedMatrix; permute::Bool=true, scale::Bool=true) = eigvals!(copy(n.array), permute=permute, scale=scale)

hessfact!(n::NamedMatrix) = hessfact!(n.array)
hessfact(n::NamedMatrix) = hessfact(copy(n.array))

schurfact!(n::NamedMatrix) = schurfact!(n.array)
schurfact(n::NamedMatrix) = schurfact!(copy(n.array))
schurfact(A::NamedMatrix, B::AbstractMatrix) = schurfact(A.array, B)
schurfact!(A::NamedMatrix, B::AbstractMatrix) = schurfact!(A.array, B)

svdfact!(n::NamedMatrix; thin::Bool=true) = svdfact!(n.array; thin=thin)
svdfact{T<:BlasFloat}(A::NamedMatrix{T}; thin=true) = svdfact!(copy(A), thin=thin)

svdvals!(n::NamedArray) = svdvals!(n.array)
svdvals(n::NamedArray) = svdvals(copy(n.array))

diag(n::NamedMatrix) = NamedArray(diag(n.array), n.dicts[1:1], n.dimnames[1:1])

diagm(n::NamedVector) = NamedArray(diagm(n.array), n.dicts[[1,1]], n.dimnames[[1,1]])

# rank, vecnorm, norm, condskeel, trace, det, logdet OK
cond(n::NamedArray) = cond(n.array)

# null(n::NamedArray) = null(n.array)

function kron(a::NamedArray, b::NamedArray)
    n = Array{typeof(AbstractString[])}(2)
    dn = AbstractString[]
    for dim in 1:2
        n[dim] = AbstractString[]
        for i in names(a, dim)
            for j in names(b, dim)
                push!(n[dim], string(i, "×", j))
            end
        end
        push!(dn, string(dimnames(a,dim), "×", dimnames(b,dim)))
    end
    NamedArray(kron(a.array, b.array), tuple(n...), tuple(dn...))
end

# linreg(x::NamedVector, y::AbstractVector) = linreg(x.array, y)

lyap(A::NamedMatrix, C::AbstractMatrix) = NamedArray(lyap(A.array,C), A.dicts, A.dimnames)

sylvester(A::NamedMatrix, B::AbstractMatrix, C::AbstractMatrix) = NamedArray(sylvester(A.array, B, C), A.dicts, A.dimnames)

## issym, istriu, istril OK
isposdef(n::NamedArray) = isposdef(n.array)

## eigs OK
