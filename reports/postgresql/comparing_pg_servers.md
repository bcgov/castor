---
title: "PostgreSQL server comparison via pgbench"
author: "Kyle Lochhead"
date: "April 4th, 2019"
output:
  html_document: 
    keep_md: yes
params:
  host1:
    label: "Host Name 1"
    value: ""
    input: text
  db1:
    label: "Database Name 1"
    value: ""
    input: text
  user1:
    label: "User Name 1"
    value: ""
    input: text
  pwd1:
    label: "Enter the Password for user"
    value: ""
    input: password
  host2:
    label: "Host Name 2"
    value: ""
    input: text
  db2:
    label: "Database Name 2"
    value: ""
    input: text
  user2:
    label: "User Name 2"
    value: ""
    input: text
  pwd2:
    label: "Enter the Password for user"
    value: ""
    input: password
  clients:
    label: "The number of clients to simulate"
    value: 10
    input: slider
    min: 1
    max: 50
    step: 1
  workers:
    label: "The number of workers to simulate"
    value: 2
    input: slider
    min: 1
    max: 8
    step: 1
  transactions:
    label: "The number of transactions to simulate"
    value: 5000
    input: slider
    min: 1
    max: 50000
    step: 1000
---
## Settings


```
## Loading required package: DBI
```



Table: localhost

unit                           setting   short_desc                                                                               
-----------------------------  --------  -----------------------------------------------------------------------------------------
checkpoint_completion_target   0.9       Time spent flushing dirty buffers during checkpoint, as fraction of checkpoint interval. 
default_statistics_target      500       Sets the default statistics target.                                                      
effective_cache_size           6291456   Sets the planner's assumption about the size of the disk cache.                          
effective_io_concurrency       0         Number of simultaneous requests that can be handled efficiently by the disk subsystem.   
maintenance_work_mem           2096128   Sets the maximum memory to be used for maintenance operations.                           
max_connections                100       Sets the maximum number of concurrent connections.                                       
max_wal_size                   512       Sets the WAL size that triggers a checkpoint.                                            
max_worker_processes           8         Maximum number of concurrent worker processes.                                           
min_wal_size                   256       Sets the minimum size to shrink the WAL to.                                              
random_page_cost               1.1       Sets the planner's estimate of the cost of a nonsequentially fetched disk page.          
shared_buffers                 2097152   Sets the number of shared memory buffers used by the server.                             
wal_buffers                    2048      Sets the number of disk-page buffers in shared memory for WAL.                           
work_mem                       131072    Sets the maximum memory to be used for query workspaces.                                 

```
## [1] TRUE
```



Table: concept.bcgov

unit                              setting   short_desc                                                                               
--------------------------------  --------  -----------------------------------------------------------------------------------------
checkpoint_completion_target      0.7       Time spent flushing dirty buffers during checkpoint, as fraction of checkpoint interval. 
default_statistics_target         100       Sets the default statistics target.                                                      
effective_cache_size              1572864   Sets the planner's assumption about the size of the data cache.                          
effective_io_concurrency          200       Number of simultaneous requests that can be handled efficiently by the disk subsystem.   
maintenance_work_mem              1048576   Sets the maximum memory to be used for maintenance operations.                           
max_connections                   100       Sets the maximum number of concurrent connections.                                       
max_parallel_workers              4         Sets the maximum number of parallel workers that can be active at one time.              
max_parallel_workers_per_gather   2         Sets the maximum number of parallel processes per executor node.                         
max_wal_size                      1024      Sets the WAL size that triggers a checkpoint.                                            
max_worker_processes              4         Maximum number of concurrent worker processes.                                           
min_wal_size                      512       Sets the minimum size to shrink the WAL to.                                              
random_page_cost                  1.1       Sets the planner's estimate of the cost of a nonsequentially fetched disk page.          
shared_buffers                    524288    Sets the number of shared memory buffers used by the server.                             
wal_buffers                       2048      Sets the number of disk-page buffers in shared memory for WAL.                           
work_mem                          20480     Sets the maximum memory to be used for query workspaces.                                 

```
## [1] TRUE
```

## Initialize 

Initializing a pgbench_accounts with 5,000,000 rows (integer).


```
## [1] "initializing on host1: localhost"
```

```
## [1] "initializing on host2: concept.bcgov"
```

## Compare 

Simulating `4` clients executing `5000` transactions on `2` worker processes using --select-only script


Table: localhost

output                                      value                                                 
------------------------------------------  ------------------------------------------------------
transaction type                            TPC-B (sort of)                                       
scaling factor                              50                                                    
query mode                                  simple                                                
number of clients                           4                                                     
number of threads                           2                                                     
number of transactions per client           5000                                                  
number of transactions actually processed   20000/20000                                           
latency average                             0.000 ms                                              
tps                                         = 3143.412336 (including connections establishing)    
tps                                         = 3170.990065 (excluding connections establishing)  C 



Table: concept.bcgov

output                                      value                                               
------------------------------------------  ----------------------------------------------------
transaction type                            TPC-B (sort of)                                     
scaling factor                              50                                                  
query mode                                  simple                                              
number of clients                           4                                                   
number of threads                           2                                                   
number of transactions per client           5000                                                
number of transactions actually processed   20000/20000                                         
latency average                             0.000 ms                                            
tps                                         = 30.079835 (including connections establishing)    
tps                                         = 30.083628 (excluding connections establishing)  C 
