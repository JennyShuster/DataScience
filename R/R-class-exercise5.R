library(dplyr)

library(ggplot2)

mtcars2 <- as_data_frame(mtcars)

ggplot(data=mtcars2) +
  geom_point(mapping = aes(x = mpg, y = wt)) +
  facet_wrap(~ Species, nrow = 1) + 
  coord_flip()