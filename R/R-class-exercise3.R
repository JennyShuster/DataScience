#1
az <- LETTERS
za <- order(az, decreasing = TRUE)
az[za]
#or
za <- sort (az, decreasing = TRUE)
za

#2
#for

for (i in 1:10) {

  print(x)
  if (x == 8){
    break
  }
  
}

#while
x <- 0
while (x != 8) {
  x <- sample(x=1:10,size=1)
  print(x)

}

#3
a <- c("well", "you", "merged", "vectors", "one") 
b <- c("done", "have", "two", "into", "phrase")
i <- 1
while (i <= length(a)) {
  print(paste(a[[i]], b[[i]]))
  i <- i + 1
}
