library(tidyverse)
library(broom)
theme_set(theme_light())

hardness <-
    read_csv("hardness.csv") %>% filter(temper < 1000)

hardnessmodel <-
    lm(hardness ~ aust + I(aust^2) +temper + I(temper^2) + quench + quench:aust,
    data = hardness)

hardnessmodel %>%
    augment(interval = "confidence") %>%
    ggplot() +
    aes(hardness, .fitted) +
    geom_point() +
    geom_abline() + 
    geom_abline(slope = 1, intercept = .5, lty = 3) +
    geom_abline(slope = 1, intercept = -.5, lty = 3) +
    scale_x_continuous(breaks = seq(56, 66, 2), limits = c(56, NA)) +
    scale_y_continuous(breaks = seq(56, 66, 2), limits = c(56, NA))

hardnessmodel %>%
    tidy() %>%
    select(-statistic) %>%
    mutate(across(estimate:std.error, ~ scales::number(.x, accuracy = .01)),
        p.value = scales::pvalue(p.value)
    ) %>%
    knitr::kable()

hardnessmodel %>%
    broom::glance() %>%
    select(ends_with("r.squared"), p.value) %>%
    mutate(across(!p.value, ~ scales::number(.x, accuracy = .0001)),
        p.value = scales::pvalue(p.value)
    ) %>%
    knitr::kable()