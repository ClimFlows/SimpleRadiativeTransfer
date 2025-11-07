#==============================================================================#
# Definition of shortwave band                                                 #
#------------------------------------------------------------------------------#
# Band Types

struct UV{F<:AbstractFloat} <: Band
    c_opacity::F
    α::F
    μ::F
    source::F
end

function UV(c_opacity::F ;
                   α      = 1//2,
                   μ      = 0.7,
                   source = 1340/4
                   ) where F

    return UV(c_opacity, F(α), F(μ), F(source))
end


#------------------------------------------------------------------------------#
# Transmission function

# function τ(band::SW, p_1, p_2, mu)
#     (; g, p_surf) = params
#     (; c_opacity) = band
#     return @. exp( -  c_opacity * (abs(p_1 - p_2))/mu )
# end


#==============================================================================#
# Fluxes functions

net_rad(band::UV, p_int, params) = net_rad(band, p_int)

function net_rad(
    band::UV ,
    p_int    ,
    )
    (; source, μ) = band

    flux = -down_rad(band, p_int, source, μ)

    # up_flux_surf = -flux[1] * albedo

    # up_rad!(flux, band, p_int, up_flux_surf, 3//5)

    return flux
end# function net_rad
