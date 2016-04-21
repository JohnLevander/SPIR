##
## General Plots
##
## Author......: Luis Gustavo Nardin
## Last Change.: 04/20/2016
##
library(data.table)
library(ggplot2)
library(doParallel)
registerDoParallel(cores=2)

setwd("/data/workspace/cmci/SPIR/scripts/")

baseDir <- "/data/projects/current/cmci/project-3/sub-projects/spir/"
inputEbolaDir <- paste0(baseDir, "ebola/")
outputDir <- paste0(baseDir, "figures/")

###############
## FUNCTIONS
###############
source("calcExpectedTime.R")


##############
## Fear Onion Graph
##############
inormal <- seq(0, 1, 0.0001)
ks <- c(0.3, 0.7, 1.0, 1.5, 2.0, 4.0)
ichange <- matrix(0, nrow=length(ks), ncol=length(inormal))
x <- 1
for (k in ks) {
  y <- 1
  for (i in inormal){
    ichange[x,y] <- inormal[y]^(1 / k)
    y <- y + 1
  }
  x <- x + 1
}

df <- NULL
for (i in 1:length(ks)){
  df <- rbind(df, cbind(inormal, rep(ks[i], length(inormal)), ichange[i,]))
}
df <- data.table(df)
names(df) <- c("inormal", "fear", "value")

pl <- ggplot(df, aes(x=inormal*100, y=value*100, group=fear)) +
  xlab(expression(paste("% Infected (i)"))) +
  ylab(expression(paste("Distortion % Infected ("*i^{1 / kappa}*")"))) +
  geom_line(size=1) +
  geom_text(data=df[which(inormal == 0.30)], aes(label=paste0("k = ", fear)),
            size=6, fontface='bold',vjust=-0.5, hjust=0, angle=40) +
  scale_x_continuous(breaks=c(0, 25, 50, 75, 100),
                     labels=c("0%", "25%", "50%", "75%", "100%"),
                     limits=c(0, 100)) +
  scale_y_continuous(breaks=c(0, 25, 50, 75, 100),
                     labels=c("0%", "25%", "50%", "75%", "100%"),
                     limits=c(0, 100)) +
  theme(axis.title.x = element_text(colour='black', size=24, face='bold',
                                    margin=margin(t=0.5, unit = "cm")),
        axis.title.y = element_text(colour='black', size=24, face='bold',
                                    margin=margin(r=0.2, unit = "cm")),
        axis.text.x = element_text(colour='black', size=18, face='bold'),
        axis.text.y = element_text(colour='black', size=18, face='bold'),
        axis.line = element_line(colour='black', size=1.5, linetype='solid'),
        panel.background = element_rect(fill = "transparent",colour = NA),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(),
        legend.title = element_text(colour="black", size=14, face="bold"),
        legend.text = element_text(colour="black", size=12, face="bold"))

ggsave(paste0(outputDir, "fear.pdf"), plot=pl,
       width=7.5, height=7, units="in")


##
## Calculating the Expected Times
##
###############
## EBOLA INPUT PARAMETERS
###############
# Disease duration
duration <- 65

# R0
R0 <- 2

# gamma
gamma <- 1 / duration

# beta
betaS <- R0 / duration

# Infection probability (Susceptible)
bs <- 1 - exp(-betaS)

# Prophylactic protection
rho <- 0.50

# Recover probability
g <- 1 - exp(-gamma)

# Discount factor (0 = No discount)
lambda <- 0

# Fear factor (1 = No fear)
kappa <- 1

# Payoffs (S, P, I, R)
payoffs <- c(1, 0.95, 0.10, 0.95)

# Disease's prevalence
i <- 0.1

# Planning Horizon
H <- seq(1, 365)

eTime <- foreach(h=H, .combine=rbind) %dopar%
  calc_expectedTime(h, i, bs, rho, g, lambda, kappa, payoffs)

total <- eTime[,6] + eTime[,7] + eTime[,8]
dataS <- cbind(eTime[,1], eTime[,2], eTime[,3], eTime[,4], eTime[,5], "S", eTime[,6] / total)
dataS <- rbind(dataS, cbind(eTime[,1], eTime[,2], eTime[,3], eTime[,4], eTime[,5], "I", eTime[,7] / total))
dataS <- rbind(dataS, cbind(eTime[,1], eTime[,2], eTime[,3], eTime[,4], eTime[,5], "R", eTime[,8] / total))
dataS <- rbind(dataS, cbind(eTime[,1], eTime[,2], eTime[,3], eTime[,4], eTime[,5], "U", eTime[,9]))

total <- eTime[,10] + eTime[,11] + eTime[,12]
dataP <- cbind(eTime[,1], eTime[,2], eTime[,3], eTime[,4], eTime[,5], "P", eTime[,10] / total)
dataP <- rbind(dataP, cbind(eTime[,1], eTime[,2], eTime[,3], eTime[,4], eTime[,5], "I", eTime[,11] / total))
dataP <- rbind(dataP, cbind(eTime[,1], eTime[,2], eTime[,3], eTime[,4], eTime[,5], "R", eTime[,12] / total))
dataP <- rbind(dataP, cbind(eTime[,1], eTime[,2], eTime[,3], eTime[,4], eTime[,5], "U", eTime[,13]))

dataS <- data.table(dataS)
colnames(dataS) <- c("h", "i", "rho", "lambda", "kappa", "type", "value")
dataS[which(value < 0)] <- 0

dataP <- data.table(dataP)
colnames(dataP) <- c("h", "i", "rho", "lambda", "kappa", "type", "value")
dataP[which(value < 0)] <- 0

plS <- ggplot(dataS[which(type != "U")], aes(x=as.numeric(as.character(h)),
                                             y=as.numeric(as.character(value)),
                                             fill=as.factor(type),
                                             color=as.factor(type),
                                             group=as.factor(type))) +
  geom_area(position="stack") +
  xlab(expression(paste("Planning Horizon (H)"))) +
  ylab(expression(paste("Expected Time Contributions"))) +
  scale_y_continuous(breaks=c(0, 0.25, 0.5, 0.75, 1),
                     labels=c("0%", "25%", "50%", "75%", "100%"),
                     limits=c(-0.001, 1.001)) +
  scale_color_manual(name="",
                     values=c("S" = "black", "I" = "red2", "R" = "gold1")) +
  scale_fill_manual(name="",
                    values=c("S" = "black", "I" = "red2", "R" = "gold1")) +
  theme(axis.title.x = element_text(colour = 'black', size = 24, face = 'bold',
                                    margin=margin(t=0.2, unit = "cm")),
        axis.title.y = element_text(colour = 'black', size = 24, face = 'bold',
                                    margin=margin(r=0.4, unit = "cm")),
        axis.text.x = element_text(colour = 'black', size = 12, face = 'bold'),
        axis.text.y = element_text(colour = 'black', size = 12, face = 'bold'),
        axis.line = element_line(colour = 'black', size = 1.5, linetype = 'solid'),
        panel.background = element_rect(fill = "transparent", colour = NA),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(),
        plot.margin = unit(c(0.5, 0, 0.5, 0), "cm"),
        #legend.position = "none",
        legend.title = element_text(colour="black", size=14, face="bold"),
        legend.text = element_text(colour="black", size=12, face="bold"),
        legend.background = element_rect(fill="white"),
        legend.key = element_rect(fill = "white"))


plP <- ggplot(dataP[which(type != "U")], aes(x=as.numeric(as.character(h)),
                                             y=as.numeric(as.character(value)),
                                             fill=as.factor(type),
                                             color=as.factor(type),
                                             group=as.factor(type))) +
  geom_area(position="stack") +
  xlab(expression(paste("Planning Horizon (H)"))) +
  ylab(expression(paste("Expected Time Contributions"))) +
  scale_y_continuous(breaks=c(0, 0.25, 0.5, 0.75, 1),
                     labels=c("0%", "25%", "50%", "75%", "100%"),
                     limits=c(-0.001, 1.001)) +
  scale_color_manual(name="",
                     values=c("P" = "blue3", "I" = "red2", "R" = "gold1")) +
  scale_fill_manual(name="",
                    values=c("P" = "blue3", "I" = "red2", "R" = "gold1")) +
  theme(axis.title.x = element_text(colour = 'black', size = 24, face = 'bold',
                                    margin=margin(t=0.2, unit = "cm")),
        axis.title.y = element_text(colour = 'black', size = 24, face = 'bold',
                                    margin=margin(r=0.4, unit = "cm")),
        axis.text.x = element_text(colour = 'black', size = 12, face = 'bold'),
        axis.text.y = element_text(colour = 'black', size = 12, face = 'bold'),
        axis.line = element_line(colour = 'black', size = 1.5, linetype = 'solid'),
        panel.background = element_rect(fill = "transparent", colour = NA),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(),
        plot.margin = unit(c(0.5, 0, 0.5, 0), "cm"),
        #legend.position = "none",
        legend.title = element_text(colour="black", size=14, face="bold"),
        legend.text = element_text(colour="black", size=12, face="bold"),
        legend.background = element_rect(fill="white"),
        legend.key = element_rect(fill = "white"))