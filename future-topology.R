## Modified from: https://cran.r-project.org/web/packages/future/vignettes/future-3-topologies.html

## Load required packages
library(future)
library(future.batchtools)
library(listenv)

## Set up access to remote login node (must have Rscript)
login <- tweak(cluster, workers = "balamuta@login.farmshare.stanford.edu",
               persistent = TRUE)
plan(login)

## Setup the appropriate batchtools script with SLURM configuration
slurm <- tweak(
  batchtools_slurm,
  resources = list(
    n_cpu = 2,
    queue = "normal",
    walltime = "00:01:00",
    mem = "4G"  # or "4000M" for megabytes
  )
)

## Specify future topology
## login node -> { cluster nodes } -> { multiple cores }
plan(list(login, slurm, multisession))

## Create nested futures for distributed computation
## Top level: Execute on login node
x %<-% {
  thost <- Sys.info()[["nodename"]]
  tpid <- Sys.getpid()
  y <- listenv()
  
  ## Middle level: Execute on compute nodes
  for (task in 1:4) {
    y[[task]] %<-% {
      mhost <- Sys.info()[["nodename"]]
      mpid <- Sys.getpid()
      z <- listenv()
      
      ## Bottom level: Execute in parallel on compute node cores
      for (jj in 1:2) {
        z[[jj]] %<-% data.frame(
          task = task,
          top.host = thost,
          top.pid = tpid,
          mid.host = mhost,
          mid.pid = mpid,
          host = Sys.info()[["nodename"]],
          pid = Sys.getpid()
        )
      }
      Reduce(rbind, z)
    }
  }
  Reduce(rbind, y)
} %seed% 290

## Wait for completion
## Check to see if the job is done and display values if so:
while (resolved(futureOf(x)) != TRUE) {
  message("Waiting for completion...")
  Sys.sleep(1)
}

## Display results
print(x)

## Save results
write.csv(x, "cluster_execution_hierarchy.csv", row.names = FALSE)

## Clean up
plan(sequential)

## --- FIN --- ##

