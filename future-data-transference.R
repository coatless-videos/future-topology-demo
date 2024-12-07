## Load required packages
library(future)
library(future.batchtools)
library(listenv)

## Set up access to remote login node (must have Rscript)
login <- tweak(cluster, workers = "balamuta@login.farmshare.stanford.edu",
               persistent = TRUE)
plan(login)

## Define a data frame locally. This will be saved on the remote node as a CSV file.
## This shows how to use the future to pass data to the remote node.
## (It's better practice to use `scp`, `rsync`, or `sftp` to transfer data.)
set.seed(290)
local_data <- data.frame(x = 1:10, y = rnorm(10))

## Define a future topology to save the data on the remote node
x %<-% {
  
  write.csv(local_data, "data-on-cluster.csv", row.names = FALSE)
  
}

# Check that the file was saved on the remote node
y %<-% {
  
  list.files()
  
}

# Show the file on the remote node
z %<-% {
  
  my_data <- read.csv("data-on-cluster.csv")
  print(my_data)
}

z
