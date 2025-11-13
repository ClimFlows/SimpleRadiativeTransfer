#==============================================================================#
# Definition of longwave band                                                  #
#------------------------------------------------------------------------------#
# Band Types

struct LW{F<:AbstractFloat} <: Band
    c_opacity::F
    α::F
end

LW(c_opacity::F) where F = LW(c_opacity, F(1//2))

#------------------------------------------------------------------------------#
# Transmission function

# More generic function in main, see wich one is easier
# function τ(band::LW, p_1, p_2)
#     (; α, c_opacity) = band
#     return @. exp( - c_opacity * sqrt( (abs(p_1^2 - p_2^2)) ))
# end# function τ


#==============================================================================#
# Fluxes functions

function down_rad!(
    flux,
    band::LW,
    p_int,
    temp_col,
    params
    )

    n_layers  = length(temp_col)

    for i in 1:n_layers
        for j in i:n_layers
            flux[i] -= stefan_bolt(temp_col[j], params) *
                ( τ(band, p_int[i], p_int[j]) -
                τ(band, p_int[i], p_int[j+1]) )
        end# for
    end# for

end# function down_rad



function up_rad!(
    flux,
    band::LW,
    p_int,
    temp_col,
    temp_surf,
    up_flux_surf,
    params
    )

    n_layers = length(temp_col)

    flux    .+= τ(band, p_int[1], p_int) * up_flux_surf

    for i in 2:n_layers+1
        for j in 1:i-1
            flux[i] += stefan_bolt(temp_col[j], params) *
                ( τ(band, p_int[i], p_int[j+1]) -
                τ(band, p_int[i], p_int[j]) )
        end# for
    end# for

end# function up_rad


function net_rad(
    band::LW  ,
    p_int     ,
    temp_col  ,
    surf_flux ,
    params
    )

    (; emissiv) = params

    flux = zeros(length(p_int))

    down_rad!(flux, band, p_int, temp_col, params)

    temp_surf = surface_temperature(
        - surf_flux - flux[1],
        params
    )

    up_flux_surf = emissiv * stefan_bolt(temp_surf, params) -
        (1 - emissiv) * flux[1]


    up_rad!(flux, band, p_int, temp_col, temp_surf, up_flux_surf, params)

    return flux, temp_surf

end# function net_rad

