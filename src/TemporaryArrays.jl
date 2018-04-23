# This file is a part of TemporaryArrays.jl, licensed under the MIT License (MIT).

__precompile__(true)

module TemporaryArrays

using Compat
using Compat: axes

using UnsafeArrays

include("util.jl")
include("data_buffer.jl")
include("temp_array_spec.jl")

end # module
