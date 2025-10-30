using SimpleRadiativeTransfer
using Test
using DelimitedFiles
using UnicodePlots
using ProgressMeter

#==============================================================================#

function p_col_create(n::Int, p_surf)
    p_all = [ p_surf*( 1 - (i-1)/(2*n) ) for i in 1:(2*n+1) ]
    return [ p_all[i] for i in 1:2:2*n+1 ], [ p_all[i] for i in 2:2:2*n ]
end

function p_col_create(params)
    (; n_layers, p_surf) = params
    return p_col_create(n_layers, p_surf)
end


#==============================================================================#

function var_temp(params, tot_rad, p_int)
    (; n_layers, c_p, g) = params

    var_t = ones(n_layers)

    for i in 1:n_layers
        var_t[i] = g * (tot_rad[i+1]-tot_rad[i]) / ( c_p * (p_int[i+1] - p_int[i]))
    end

    return(var_t)
end





#==============================================================================#
# main


function temp_ev(
    band_lw,
    bands,
    n_time,
    d_time,
    p_int,
    p_layers,
    temp_col,
    params
    )

    @showprogress for k in 1:n_time+1
        tot_rad, temp_surf = total_rad(params, band_lw, bands, p_int, temp_col)
        var_t              = var_temp(params, tot_rad, p_int)
        temp_col += var_t * d_time
    end

    return temp_col
end

#==============================================================================#

function test_3bands(;
                     n_time       = 4000,
                     step_sorties = 500,
                     d_time       = 3600,
                     temp_0       = 290,
                     r_sw         = 0.9,
                     r_lw         = 0.08,
                     r_uv         = 1e-6,
                     solarc = 1340/4
                     )

    params   = params_create()

    band_sw  = sw_create(-log(r_sw)/params.p_surf, source=0.9*solarc)
    band_uv  = uv_create(-log(r_uv)/params.p_surf, source=0.1*solarc)
    band_lw  = lw_create(-log(r_lw)/params.p_surf)

    @info "Testing 3 bands radiative transfer" band_lw, band_sw, band_uv

    p_int, p_layers = p_col_create(params)

    temp_col_0 = temp_0 * ones(params.n_layers)

    @time temp_col = temp_ev(
        band_lw,
        [band_sw, band_uv],
        n_time,
        d_time,
        p_int,
        p_layers,
        temp_col_0,
        params
    )

    return temp_col
end

#==============================================================================#

function test_2bands(;
                     n_time       = 4000,
                     step_sorties = 500,
                     d_time       = 3600,
                     temp_0       = 290,
                     r_sw         = 0.9,
                     r_lw         = 0.08,
                     r_uv         = 1e-6,
                     solarc = 1340/4
                     )

    params   = params_create()

    band_sw  = sw_create(-log(r_sw)/params.p_surf, source=0.9*solarc)
    band_lw  = lw_create(-log(r_lw)/params.p_surf)

    @info "Testing 2 bands radiative transfer" band_lw, band_sw

    p_int, p_layers = p_col_create(params)

    temp_col_0 = temp_0 * ones(params.n_layers)

    @time temp_col = temp_ev(
        band_lw,
        [band_sw],
        n_time,
        d_time,
        p_int,
        p_layers,
        temp_col_0,
        params
    )

    return temp_col

end

#==============================================================================#


@testset "SimpleRadiativeTransfer.jl" begin

    temp_col_2b = test_2bands()
    ref_temp_col_2b = readdlm("temp_col_2bands.csv")
    @test temp_col_2b ≈ ref_temp_col_2b atol = 0.01

    temp_col_3b = test_3bands()
    ref_temp_col_3b = readdlm("temp_col_3bands.csv")
    @test temp_col_3b ≈ ref_temp_col_3b atol = 0.01
    p = Plot(;
             xlim=(150.0, 350.0),
             ylim=(101325, 0),
             yflip=true,
             title="Temperature column at the end of the simulation",
             xlabel="Temperature (K)", ylabel="Pressure Level (Pa)"
             )

    lineplot!(p, temp_col_2b, p_layers; name="2 bands")
    lineplot!(p, temp_col_3b, p_layers; name="3 bands")

    display(p)
end
