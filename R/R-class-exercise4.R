nasa1 <- as_data_frame(nasa)

library(dplyr)

nasa2 <- nasa1 %>% 
  filter((lat>=29.56 & lat<=33.09) & (long>= -110.93 & long<= -90.55)) %>%
  mutate(t_s = temperature / surftemp)%>%
  group_by(year)%>%
  summarise(pressure_mean = mean(pressure,na.rm=TRUE),
            pressure_std = sd(pressure,na.rm=TRUE),
            ozone_mean = mean(ozone,na.rm=TRUE),
            ozone_std = sd(ozone,na.rm=TRUE),
            t_s_mean = mean(t_s,na.rm=TRUE),
            t_s_std = sd(t_s,na.rm=TRUE))%>%
  arrange(desc(ozone_mean))
