library(tidyverse)
library(broom)
theme_set(theme_light())

hardness <-
    read_csv("hardness.csv") %>% filter(temper < 1000)

hardnessmodel <-
    lm(hardness ~ aust + I(aust^2) + temper + I(temper^2) + quench + quench:aust, # nolint
        data = hardness
    )

hardnessmodel %>%
    augment(interval = "confidence") %>%
    ggplot() +
    aes(hardness, .fitted) +
    geom_point() +
    geom_abline() +
    geom_abline(slope = 1, intercept = .5, lty = 3) +
    geom_abline(slope = 1, intercept = -.5, lty = 3) +
    scale_x_continuous(breaks = seq(56, 66, 2), limits = c(56, NA)) +
    scale_y_continuous(breaks = seq(56, 66, 2), limits = c(56, NA)) +
    labs(
        x = "Actual",
        y = "Model fitted value",
        title = "Second-order linear model for the hardness of CPM-Magnacut under different prep conditions", # nolint
        subtitles = "with variations in austinizing temperature, temper temperature and quench rate", # nolint
        caption = "Dotted lines indicate 0.5 HRC deviation from model"
    )

ggsave("hardness-prediction.png", width = 10, height = 8)

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

hardnessmodel %>%
    broom::augment(newdata = crossing(
        aust = seq(1900, 2200, 10),
        temper = seq(300, 500, 10),
        quench = c("RT", "LN2", "Freezer")
    )) %>%
    mutate(quench = factor(quench,
        levels = c("RT", "Freezer", "LN2")
    )) %>%
    ggplot() +
    aes(x = aust, y = temper, z = .fitted, color = .fitted) +
    geom_contour_filled(breaks = seq(56, 66, 1)) +
    facet_wrap(~quench, ncol = 1) +
    labs(
        x = "Austinizing temperature (in degF)",
        y = "Temper temperature (in degC)",
        z = "Hardness range"
    ) +
    scale_x_continuous(sec.axis = sec_axis(~ 5 / 9 * (. - 32),
        name = "Austinizing temperature (in degC)"
    )) +
    scale_y_continuous(sec.axis = sec_axis(~ 5 / 9 * (. - 32),
        name = "Temper temperature (in degC)"
    ))

ggsave("hardness-contour.png", width = 18, height = 6)