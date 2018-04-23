# This file is a part of TemporaryArrays.jl, licensed under the MIT License (MIT).


# _non_neg(x::T) where T<:Real = x >= 0 ? x : zero(T)


@inline _tuple_cumsum(xs::Tuple) = _tuple_cumsum_impl(xs...)

@inline _tuple_cumsum_impl() = ()

@inline _tuple_cumsum_impl(x, xs...) = (x, _tuple_cumsum_impl2(x, xs...)...)

@inline _tuple_cumsum_impl2(s) = ()

@inline function _tuple_cumsum_impl2(s, x, xs...)
    y = s + x
    (y, _tuple_cumsum_impl2(y, xs...)...)
end


@inline function _align_alloc_size(s::Integer)
    const log2_cacheline_size = 6
    const cacheline_size = 1 << log2_cacheline_size

    ((s + cacheline_size - 1) >> log2_cacheline_size) << log2_cacheline_size
end
