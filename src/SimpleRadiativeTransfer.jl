module SimpleRadiativeTransfer

export Band, SW, LW, UV
export sw_create, lw_create, uv_create

export surface_temperature, stefan_bolt
export total_rad
export params_create


#==============================================================================#
# Band Types

abstract type Band end




#==============================================================================#
# Temperatures

surface_temperature(net_flux, (; stefan, emissiv)) =
    ( (net_flux/emissiv) / stefan )^(1//4)


stefan_bolt(temp, (; stefan)) = stefan * temp^4

#------------------------------------------------------------------------------#
# Transmission function
## with pressure values

function τ end

function τ(band::Band, p_1, p_2, μ)
    (; α, c_opacity) = band
    return @. exp( - c_opacity/μ * abs( p_1^(1//α) - p_2^(1//α) )^α  )
end



# When τ is called without μ parameter
τ(band::Band, p_1, p_2) = τ(band, p_1, p_2, 1)


#==============================================================================#
# Fluxes functions

function down_rad end
function up_rad end

function down_rad!(flux, band::Band, p_int, source, μ)
    flux .-= τ(band, p_int, 0, μ) * μ * source
end

function up_rad!(flux, band::Band, p_int, source, μ)
    flux .+= τ(band, p_int[1], p_int, μ) * source
end

function down_rad(band::Band, p_int, source, μ)
    return τ(band, p_int, 0, μ) * μ * source
end

function up_rad(band::Band, p_int, source, μ)
    return τ(band, p_int[1], p_int, μ) * source
end


#==============================================================================#
# Import

include("julia/longwave_band.jl")
include("julia/shortwave_band.jl")
include("julia/uv_band.jl")


#==============================================================================#
### Total flux


function total_rad(params, band_sw::SW, band_lw::LW, p_int, temp_col)

    flux = net_rad(band_sw, p_int, params)

    flux_lw, temp_surf = net_rad(band_lw, p_int, temp_col, flux[1], params)
    flux .+= flux_lw

    return flux, temp_surf
end

function total_rad(params, band_sw::SW, band_lw::LW, band_uv::UV, p_int, temp_col)

    flux   = net_rad(band_sw, p_int, params)
    flux .+= net_rad(band_uv, p_int)

    flux_lw, temp_surf = net_rad(band_lw, p_int, temp_col, flux[1], params)
    flux .+= flux_lw

    return flux, temp_surf
end

#==============================================================================#



function params_create(
    n_layers = 100      ,
    p_surf   = 101325.0 ,
    stefan   = 5.67e-8  ,
    albedo   = 0.32     ,
    emissiv  = 0.9      ,
    c_p      = 1005     ,
    g        = 9.81
    )
    """Create parameter set with default values"""

    return (
        n_layers = n_layers ,
        p_surf   = p_surf   ,
        albedo   = albedo   ,
        stefan   = stefan   ,
        emissiv  = emissiv  ,
        c_p      = c_p      ,
        g        = g
    )

end



end # module

