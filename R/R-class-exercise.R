a <- 10:20
a
b <- letters[4:13]
b
f <- c(1,1,1,0,0,0,0,0)
f
f <- factor(f, levels=c(0,1), labels=c("Yes", "No"))
f
.Ob <- 1
ls(pattern = "O")
ls(pattern= "O", all.names = TRUE)    # also shows ".[foo]"
