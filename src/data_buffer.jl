# This file is a part of TemporaryArrays.jl, licensed under the MIT License (MIT).


const BufferArray = Vector{UInt8}
# Alternative: Use ResizeableUnsafeArray with size hinting, growable
# via page faults, manual alloc/free. Would mean slower allocation
# for small arrays, but fast resize. Allow optional hand-off of finished
# array to Julia (via unsafe_wrap with offset manipulation) instead of
# standard re-use?


# Minimum allocation size (typical cache line size):
const min_alloc_size = 64

# Time for buffer size to linearly decay to zero:
const buffer_decay_time_ns = 2 * Int64(10)^9


function _allocsize(nbytes::Integer)
    nbytes2 = nextpow2(nbytes)
    T = typeof(min_alloc_size)
    max(T(nbytes2), min_alloc_size)
end


mutable struct DataBuffer
    data::BufferArray
    currused::Int
    maxused::Int
    lastchange::UInt64
end


DataBuffer(nbytes::Integer = 0) = DataBuffer(
    BufferArray(_allocsize(nbytes)),
    0, 0, time_ns()
)


Base.length(buf::DataBuffer) = length(linearindices(buf.data))


function _alloc!(buf::DataBuffer, nbytes::Integer)
    _isfree(buf) || error("Can't allocate on buffer in use")

    nbytes_alloc = _allocsize(nbytes)
    data = buf.data
    datalen = length(data)
    t = time_ns()

    if datalen < n
        resize!(data, nbytes_alloc)
    end

    buf.currused = n

    _update_maxused!(buf)
    if _isoversized(buf)
        buf.data = BufferArray(_allocsize(buf.maxused))
    end

    @assert length(buf.data) >= n
    pointer(buf.data)
end


function _free!(buf::DataBuffer)
    _update_maxused!(buf)
    if _isoversized(buf)
        buf.data = BufferArray(_allocsize(buf.maxused))
    end

    buf.currused = 0
    nothing
end



_isfree(buf::DataBuffer) = !(buf.currused > 0)

_isoversized(buf::DataBuffer) = length(buf.data) > 2 * _allocsize(buf.maxused)

# _isobsolete(buf::DataBuffer) = _isfree(buf) && (time_ns() - buf.lastchange > buffer_decay_time_ns)

function _update_maxused!(buf::DataBuffer)
    maxused = buf.maxused
    currused = buf.currused
    t = time_ns()
    delta_t = t - buf.lastchange

    # Linear decay of max-used level:
    if delta_t > buffer_decay_time_ns
        buf.maxused = currused
    else
        T = typeof(maxused)
        buf.maxused = max(T(maxused * (delta_t / buffer_decay_time_ns)), T(currused))
    end

    buf.lastchange = t

    @assert buf.maxused >= buf.currused
    buf
end



mutable struct BufferStack
    buffers::Vector(DataBuffer)
    pos::Int
end


function _alloc!(bufstack::BufferStack, nbytes::Integer)
    pos = bufstack.pos
    buffers = bufstack.buffers
    ptr = alloc!(buffers[pos], nbytes)
    newpos = pos + 1
    if newpos > length(buffers)
        resize!(buffers, newpos)
    end
    @assert checkindex(Bool, linearindices(buffers), newpos)
    bufstack.pos = newpos
    ptr
end


function _free!(bufstack::BufferStack)
    pos = bufstack.pos
    buffers = bufstack.buffers

    free!(buffers[pos])

    #!!! TODO: buffer stack GC

    newpos = pos - 1
    @assert checkindex(Bool, linearindices(buffers), newpos)
    bufstack.pos = newpos
    nothing
end
