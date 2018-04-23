# This file is a part of TemporaryArrays.jl, licensed under the MIT License (MIT).


struct TempArraySpec{T,N}
    size::NTuple{N,Int}

    @inline TempArraySpec{T}(I::Integer...) where {T} =
        new{T,length(I)}(map(Int, I))
end


# struct TempArraySpec{T,N}
#     size::NTuple{N,Int}
# 
#     @inline TempArraySpec{T,N}(isbits_T::Val{true}, size::NTuple{N,Int}) where {T,N} =
#         new{T,N}(size)
# end
# 
# @inline TempArraySpec{T}(I::Integer...) where {T} =
#     TempArraySpec{T,length(I)}(Val{isbits(T)}(), map(Int, I))


# struct TempArraySpecs{N,S<:NTuple{N,TempArraySpec}}
#     specs::S
# 
#     @inline TempArraySpecs(specs::TempArraySpec...) =
#         new{length(specs),typeof(specs)}(specs)
# end


@inline _tmp_allocsize(as::TempArraySpec{T,N}) where {T,N} = _tmp_allocsize_impl(Val{isbits(T)}(), as)

@inline _tmp_allocsize_impl(isbits_T::Val{true}, as::TempArraySpec{T,N}) where {T,N} =
    _align_alloc_size(Int(sizeof(T) * prod(as.size)))

@inline _tmp_allocsize_impl(isbits_T::Val{false}, as::TempArraySpec{T,N}) where {T,N} = 0
