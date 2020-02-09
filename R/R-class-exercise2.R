##1
iris
min(iris$Sepal.Length)
max(iris$Sepal.Length)
mean(iris$Sepal.Length)

min(iris$Sepal.Width)
max(iris$Sepal.Width)
mean(iris$Sepal.Width)

min(iris$Petal.Length)
max(iris$Petal.Length)
mean(iris$Petal.Length)

min(iris$Petal.Width)
max(iris$Petal.Width)
mean(iris$Petal.Width)

##2
mtcars
#a
sqrt(mtcars$mpg)
#b
log(mtcars$disp)
#c
(mtcars$wt)^3
##3
s1 <- paste("age", "gender", "height", "weight", sep="+")
s1
##4
m1 <- matrix(c(4,7,-8,3,0,-2,1,-5,12,-3,6,9), ncol=4)
m1
mean(m1)
colMeans(m1)
rowMeans(m1)
