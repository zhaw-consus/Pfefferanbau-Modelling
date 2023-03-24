ou <- data_10min_nested |>
    filter(SSP == SSP_sel, period == period_sel)|>
    pull(characteristic_df) |>
    map(\(x) suitability(x,"min. monthly precipitation"), .progress = TRUE) |>
    rast()


ou_modal <- ou |>
    modal()

acc <- sum(ou_modal == ou)/nlyr(ou)


plot(acc)

ou_modal



