glusterfs:
  cluster_optimize_params:
    - performance.io-thread-count 8
    - network.remote-dio on                      
    - cluster.eager-lock on                      
    - performance.stat-prefetch off              
    - performance.io-cache on                    
    - performance.cache-size 512MB              
    - performance.read-ahead on                  
    - performance.readdir-ahead on               
    - performance.write-behind on                
    - performance.write-behind-window-size 512MB 
    
  volumes:
    - nova:
        name: nova-vol
        brick: /datas/local/glusterfs/nova-vol/brick1
    - cinder: 
        name: cinder-vol
        brick: /datas/local/glusterfs/cinder-vol/brick1
