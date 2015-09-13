facts("Element testing") do

context("spring") do
    @fact spring1e(3.0) --> [3.0 -3.0; -3.0 3.0]
    @fact spring1s(3.0, [3.0, 1.0]) --> 3.0 * (1.0 - 3.0)
end

context("plani4e") do
    K, f = plani4e([0, 1, 1.5, 0.5], [0.0, 0.2, 0.8, 0.6], [2, 2, 2], hooke(2, 210e9, 0.3), [1.0, 2.5])

    K_calfem =
  1e11*[1.367692307692308   0.067307692307692  -1.012307692307693   0.740384615384616   0.059230769230770  -0.740384615384616  -0.414615384615385  -0.067307692307692;
   0.067307692307692   2.121538461538462   0.336538461538462   0.576153846153845  -0.740384615384616   0.449615384615385   0.336538461538462  -3.147307692307693;
  -1.012307692307693   0.336538461538462   4.340000000000000  -2.759615384615385  -0.414615384615385   0.336538461538462  -2.913076923076923   2.086538461538462;
   0.740384615384616   0.576153846153845  -2.759615384615385   8.163076923076922  -0.067307692307692  -3.147307692307692   2.086538461538461  -5.591923076923075;
   0.059230769230770  -0.740384615384616  -0.414615384615385  -0.067307692307692   1.367692307692308   0.067307692307692  -1.012307692307693   0.740384615384616;
  -0.740384615384616   0.449615384615385   0.336538461538462  -3.147307692307692   0.067307692307692   2.121538461538462   0.336538461538462   0.576153846153845;
  -0.414615384615385   0.336538461538462  -2.913076923076923   2.086538461538461  -1.012307692307693   0.336538461538462   4.340000000000000  -2.759615384615385;
  -0.067307692307692  -3.147307692307693   2.086538461538462  -5.591923076923075   0.740384615384616   0.576153846153845  -2.759615384615385   8.163076923076924]

   f_calfem =
  [0.250;
   0.625;
   0.250;
   0.625;
   0.250;
   0.625;
   0.250;
   0.625]

    @fact norm(K - K_calfem) / norm(K) --> roughly(0.0, atol=1e-15)
    @fact norm(f - f_calfem) / norm(f) --> roughly(0.0, atol=1e-15)


    # Patch test the element:
    # Set up a 4 element patch:
    # 17,18---15,16----13,14
    #   |       |        |
    #  7,8-----5,6-----11,12
    #   |       |        |
    #  1,2-----3,4------9,10
    # Set dirichlet boundary conditions such that u_x = u_y = 0.1x + 0.05y
    # Solve and see that middle node is at correct position
    function patch_test()
        Coord = [0 0
                 1 0
                 1 1
                 0 1
                 2 0
                 2 1
                 2 2
                 1 2
                 0 2]

        Dof = [1 2
               3 4
               5 6
               7 8
               9 10
               11 12
               13 14
               15 16
               17 18]

        Edof = [1 1 2 3 4 5 6 7 8;
                2 3 4 9 10 11 12 5 6;
                3 5 6 11 12 13 14 15 16;
                4 7 8 5 6 15 16 17 18]

        function get_coord(dof)
          node = div(dof+1, 2)
          if dof % 2 == 0
              return Coord[node, 2]
          else
              return Coord[node, 1]
          end
        end

        ux = 0.1
        uy = 0.05
        bc_dofs = [1, 2, 3, 4, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 7, 8]
        bc = zeros(length(bc_dofs), 2)
        for i in 1:size(bc, 1)
          dof = bc_dofs[i]
          node = div(dof+1, 2)
          coord = Coord[node, :]
          bc[i, 1] = dof
          bc[i, 2] = ux * coord[1] + uy * coord[2]
        end

          a = start_assemble()
          D = hooke(2, 250e9, 0.3)
          for e in 1:size(Edof, 1)
            ex = [get_coord(i) for i in Edof[e, 2:2:end]]
            ey = [get_coord(i) for i in Edof[e, 3:2:end]]
            Ke, _ = plani4e(ex, ey, [2, 1, 2], D)
            assemble(Edof[e, :], a, Ke)
          end
          K = end_assemble(a)
          a, _ = solve_eq_sys(K, zeros(18), bc)
          d_free = setdiff(collect(1:18), convert(Vector{Int}, bc[:,1]))
          @fact a[d_free] --> roughly([ux + uy, ux + uy])
      end
      patch_test()

end

context("plante") do
    K, f = plante([0, 1, 1.5], [0.0, 0.2, 0.8], [2, 2, 1], hooke(2, 210e9, 0.3), [1.0, 2.5])

    K_calfem = 1e12 * [
    0.243923076923077  -0.121153846153846  -0.392538461538462   0.282692307692308   0.148615384615385  -0.161538461538462
    -0.121153846153846   0.199500000000000   0.242307692307692  -0.501576923076923  -0.121153846153846   0.302076923076923
    -0.392538461538462   0.242307692307692   0.725307692307692  -0.484615384615385  -0.332769230769231   0.242307692307692
    0.282692307692308  -0.501576923076923  -0.484615384615385   1.375499999999999   0.201923076923077  -0.873923076923076
    0.148615384615385  -0.121153846153846  -0.332769230769231   0.201923076923077   0.184153846153846  -0.080769230769231
    -0.161538461538462   0.302076923076923   0.242307692307692  -0.873923076923076  -0.080769230769231   0.5718461538461549
    ]

    f_calfem = [1/6, 5/12, 1/6, 5/12, 1/6, 5/12]

    @fact norm(K - K_calfem) / norm(K) --> roughly(0.0, atol=1e-13)
    @fact norm(f - f_calfem) / norm(f) --> roughly(0.0, atol=1e-13)

end

context("soli8e") do
    K, f = soli8e([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8], [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
                  [0.1, 0.2, 1.3, 1.4, 0.5, 0.6, 1.7, 1.8], [2], hooke(4, 210e9, 0.3), [1.0, 2.5, 3.5])

    K_calfem_trace =  -1.469957313088530e+12

    f_calfem =    [-0.111944444444444,
                  -0.279861111111111,
                  -0.391805555555555,
                  -0.103472222222222,
                  -0.258680555555556,
                  -0.362152777777778,
                  -0.094583333333333,
                  -0.236458333333333,
                  -0.331041666666667,
                  -0.103333333333333,
                  -0.258333333333333,
                  -0.361666666666667,
                  -0.115416666666667,
                  -0.288541666666667,
                  -0.403958333333333,
                  -0.106666666666667,
                  -0.266666666666667,
                  -0.373333333333333,
                  -0.097777777777778,
                  -0.244444444444444,
                  -0.342222222222222,
                  -0.106805555555556,
                  -0.267013888888889,
                  -0.373819444444444]

    @fact trace(K) --> roughly(K_calfem_trace)
    @fact norm(f- f_calfem) / norm(f_calfem) --> roughly(0.0, atol =1e-13)
end

context("plani8e") do
    K, f = plani8e([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
                   [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0], [2,2,2], hooke(2, 210e9, 0.3), [1.0, 2.5])

    K_calfem_trace =  -2.642786509138767e+11

    f_calfem =    [-0.218148148148149,
                   -0.545370370370372,
                    0.461111111111112,
                    1.152777777777779,
                    0.107037037037037,
                    0.267592592592593,
                   -0.207777777777778,
                   -0.519444444444446,
                    0.201481481481482,
                    0.503703703703705,
                    0.851851851851853,
                    2.129629629629632,
                   -0.485925925925926,
                   -1.214814814814815,
                   -1.136296296296297,
                   -2.840740740740743]

    @fact trace(K) --> roughly(K_calfem_trace)
    @fact norm(f- f_calfem) / norm(f_calfem) --> roughly(0.0, atol =1e-13)
end

context("flw2i4e") do
    K, f = flw2i4e([0, 1, 1.5, 0.5], [0.0, 0.2, 0.8, 0.6], [2, 2, 2], [1 2; 3 4], [2.0])

    K_calfem = [3.126666666666666   1.713333333333333  -1.193333333333333  -3.646666666666667;
                2.713333333333332   4.606666666666666  -4.646666666666666  -2.673333333333332;
               -1.193333333333333  -3.646666666666666   3.126666666666667   1.713333333333332;
               -4.646666666666667  -2.673333333333332   2.713333333333331   4.606666666666667]

    f_calfem = 0.5 * ones(4)

    @fact norm(K - K_calfem) / norm(K) --> roughly(0.0, atol=1e-13)
    @fact norm(f - f_calfem) / norm(f) --> roughly(0.0, atol=1e-13)
end

context("flw2i8e") do
    K, f = flw2i8e([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
                   [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0], [2,2], [1 2; 3 4], [3.0])

    K_calfem_trace = -7.239044777988562

    f_calfem =    [ -0.654444444444446;
                     1.383333333333335;
                     0.321111111111111;
                    -0.623333333333334;
                     0.604444444444445;
                     2.555555555555558;
                    -1.457777777777777;
                    -3.408888888888892]

    @fact trace(K) --> roughly(K_calfem_trace)
    @fact norm(f- f_calfem) / norm(f_calfem) --> roughly(0.0, atol =1e-13)
end

context("flw2te") do
    K, f = flw2te([0, 1, 1.5], [0.0, 0.2, 0.8], [2, 1], [1 2; 3 4], [2.0])

    K_calfem =
    [-0.28  -0.96   1.24;
      0.04   7.28  -7.32;
      0.24  -6.32   6.08]

    f_calfem = [0.333333333333333;
                0.333333333333333;
                0.333333333333333]

    @fact norm(K - K_calfem) / norm(K) --> roughly(0.0, atol=1e-13)
    @fact norm(f - f_calfem) / norm(f) --> roughly(0.0, atol=1e-13)
end

context("flw3i8e") do
    K, f = flw3i8e([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8], [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
                   [0.1, 0.2, 1.3, 1.4, 0.5, 0.6, 1.7, 1.8], [2], [1 2 3; 4 5 6; 7 8 9], [2.0])

    K_calfem_trace = -13.061465948339601

    f_calfem =    [ -0.223888888888889;
                    -0.206944444444444;
                    -0.189166666666667;
                    -0.206666666666667;
                    -0.230833333333333;
                    -0.213333333333333;
                    -0.195555555555556;
                    -0.213611111111111;]

    @fact trace(K) --> roughly(K_calfem_trace)
    @fact norm(f- f_calfem) / norm(f_calfem) --> roughly(0.0, atol =1e-13)
end



context("bar") do
    # From example 3.2 in the book Strukturmekanik
    ex = [0.  1.6]; ey = [0. -1.2]
    elem_prop = [200.e9 1.0e-3]
    Ke = bar2e(ex, ey, elem_prop)
    ed = [0. 0. -0.3979 -1.1523]*1e-3
    N = bar2s(ex, ey, elem_prop, ed)
    Ke_ref = [ 64  -48. -64  48
              -48   36   48 -36
              -64   48   64 -48
               48  -36  -48  36]*1e6
    N_ref = 37.306e3
    @fact norm(Ke - Ke_ref) / norm(Ke_ref) --> roughly(0.0, atol=1e-15)
    @fact abs(N - N_ref) / N_ref --> roughly(0.0, atol=1e-15)
end

end
