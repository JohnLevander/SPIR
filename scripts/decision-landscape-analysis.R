##
## Calculates and plot the planning horizon,
## frequency of infected, and utilities
##
## Author......: Luis Gustavo Nardin
## Last Change.: 03/25/2016
##
library(data.table)
library(lattice)
library(rgl)

##
## Input parameters
##
# Payoffs (S, P, I, R)
payoffs <- c(1, 0.99, 0, 1)

# Infection probability (Susceptible)
bs <- 0.15

# Prophylactic protection
rho <- 0.16

# Infection probability (Prophylactic)
bp <- rho * bs

# Recover probability
g <- 0.05

# Range of Time Horizon to evaluate
H <- seq(1,368)

# Range of Proportion of infected to evaluate
I <- seq(0.01,1.00,0.01)

rws <- length(H) * length(I)
data <- matrix(data=0, nrow=rws, ncol=4)
rw <- 1
for(h in H){
  for(i in I){
    p <- i * bs
    Tss <- (1 - ((1 - p)^h)) / p
    if (p != g){
      Tis <- (1 / g) - (((p * ((1 - g)^h)) / (g * (p - g))) * (1 - (((1 - p) / (1 - g))^h))) - (((1 - p)^h) / g)
    } else {
      Tis <- (1 / g) - ((p * h * ((1 - g)^(h-1))) / g) - (((1 - p)^h) / g)
    }
    Trs <- h - Tss -Tis
    Us <- (payoffs[1] * Tss) + (payoffs[3] * Tis) + (payoffs[4] * Trs)
    
    p <- i * bp
    Tpp <- (1 - ((1 - p)^h)) / p
    if (p != g){
      Tip <- (1 / g) - (((p * ((1 - g)^h)) / (g * (p - g))) * (1 - (((1 - p) / (1 - g))^h))) - (((1 - p)^h) / g)
    } else {
      Tip <- (1 / g) - ((p * h * ((1 - g)^(h-1))) / g) - (((1 - p)^h) / g)
    }
    Trp <- h - Tpp - Tip
    Up <- (payoffs[2] * Tpp) + (payoffs[3] * Tip) + (payoffs[4] * Trp)
    
    data[rw,] <- c(h, i, Us, Up)
    rw <- rw + 1
  }
}

data <- data.table(data)
colnames(data) <- c("h","i","US","UP")

##
## Wireframe 3D plot
##
wireframe(US + UP ~ h * i, data,
          xlab="Planning Horizon \n (H)",
          ylab="Frequency of Infected \n (i)",
          zlab="E(U)\n[S=Black]\n[P=Blue]",
          arrows=FALSE, scales=list(arrows=FALSE), aspect=c(1, 1),
          col=c("black","blue"))

##
## Interactive 3D plot
##
plot3d(data$h, data$i, data$US, col="black")
plot3d(data$h, data$i, data$UP, col="blue", add = TRUE)
