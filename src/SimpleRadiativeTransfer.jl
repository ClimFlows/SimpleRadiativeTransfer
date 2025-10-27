module SimpleRadiativeTransfer

function hello()
    @info "SimpleRadiativeTransfer"
end

# Write your package code here.


#==============================================================================#
# Band Types

abstract type Band end

## Short waves
struct SW <: Band
    alpha
    c_opacity
end

function sw_create(alpha = 1, c_opacity = 0.9)
    return SW(alpha, c_opacity)
end

## Long waves
struct LW <: Band
    alpha
    c_opacity
end

function lw_create(alpha = 0.5, c_opacity = 0.08)
    return LW(alpha, c_opacity)
end


#==============================================================================#





end
