module SimpleRadiativeTransfer

export Band, SW, LW
export sw_create, lw_create

export surface_temperature, stefan_bolt
export τ, down_rad, up_rad, total_rad
export params_create


#==============================================================================#
# Band Types

abstract type Band end

## Short waves
struct SW <: Band
    α
    c_opacity
end

function sw_create(α = 1, c_opacity = 0.9)
    return SW(α, c_opacity)
end

## Long waves
struct LW <: Band
    α
    c_opacity
end

function lw_create(α = 1//2, c_opacity = 0.08)
    return LW(α, c_opacity)
end


#==============================================================================#
# Temperatures

surface_temperature(params, net_flux) =
    ( (net_flux/params.emissiv) / params.stefan )^(1//4)


stefan_bolt(params, temp) = params.stefan * temp^4

#------------------------------------------------------------------------------#
# Transmission function
## with pressure values

function τ(params, band::Band, p_1, p_2, mu)
    (; g, p_surf)    = params
    (; α, c_opacity) = band
    return @. exp( - c_opacity/mu * abs( p_1^(1//α) - p_2^(1//α) )^α  )
end

function τ(params, band::SW, p_1, p_2, mu)
    (; g, p_surf) = params
    (; c_opacity) = band
    return @. exp( -  c_opacity * (abs(p_1 - p_2))/mu )
end

function τ(params, band::LW, p_1, p_2, mu)
    (; g, p_surf)    = params
    (; α, c_opacity) = band
    return @. exp( - c_opacity * sqrt( (abs(p_1^2 - p_2^2)) ))
end


τ(params, band::Band, p_1, p_2) = τ(params, band, p_1, p_2, 1)


#==============================================================================#
# Fluxes functions

function down_rad(params, band::Band, p_int)
    (; mu, solarc) = params
    return τ(params, band, p_int, 0, mu) * mu * solarc
end

function up_rad(params, band::Band, p_int, up_flux_surf)
    (; p_surf) = params
    return τ(params, band, p_surf, p_int) * up_flux_surf
end

function up_rad(params, band::SW, p_int, down_flux_surf)
    (; p_surf, albedo) = params
    up_flux_surf = down_flux_surf * albedo
    return τ(params, band, p_surf, p_int, 3//5) * up_flux_surf
end




## Long wave

function down_rad(params, band::LW, p_int, temp_col)
    (; n_layers) = params
    down_flux    = zeros(n_layers+1)

    for i in 1:n_layers
        for j in i:n_layers
            down_flux[i] += stefan_bolt(params, temp_col[j]) *
                ( τ(params, band, p_int[i], p_int[j]) -
                 τ(params, band, p_int[i], p_int[j+1]) )
        end
    end

    return down_flux
end


function up_rad(params, band::LW, p_int, temp_col, temp_surf, down_flux_surf)
    (; p_surf, n_layers, emissiv) = params

    up_flux_surf = emissiv * stefan_bolt(params, temp_surf) +
        (1 - emissiv) * down_flux_surf

    up_flux = τ(params, band, p_surf, p_int) * up_flux_surf

    for i in 2:n_layers+1
        for j in 1:i-1
            up_flux[i] += stefan_bolt(params, temp_col[j]) *
                ( τ(params, band, p_int[i], p_int[j+1]) -
                τ(params, band, p_int[i], p_int[j]) )
        end
    end

    return up_flux

end

#------------------------------------------------------------------------------#
### Total flux

function total_rad(params, band_sw::SW, band_lw::LW, p_int, temp_col)
    down_rad_sw = down_rad(params, band_sw, p_int)
    up_rad_sw   = up_rad(params, band_sw, p_int, down_rad_sw[1])

    down_rad_lw = down_rad(params, band_lw, p_int, temp_col)

    temp_surf   = surface_temperature(
        params,
        down_rad_lw[1] + down_rad_sw[1] - up_rad_sw[1]
    )

    up_rad_lw   = up_rad(
        params, band_lw, p_int, temp_col, temp_surf, down_rad_lw[1]
    )

    return up_rad_lw + up_rad_sw - down_rad_lw - down_rad_sw, temp_surf
end

#==============================================================================#



function params_create(
    n_layers = 30       ,
    p_surf   = 101325.0 ,
    mu       = 0.7      ,
    solarc   = 1340/4   ,
    stefan   = 5.67e-8  ,
    g        = 9.81     ,
    albedo   = 0.32     ,
    emissiv  = 0.9      ,
    c_p      = 1005
    )
    """Create parameter set with default values"""

    return (
        n_layers = n_layers ,
        p_surf   = p_surf   ,
        albedo   = albedo   ,
        mu       = mu       ,
        solarc   = solarc   ,
        stefan   = stefan   ,
        g        = g        ,
        emissiv  = emissiv  ,
        c_p      = c_p
    )

end



end # module

