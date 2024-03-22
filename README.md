# SQANTI3-dockerfile

## Obtain image from GitHub
```
git clone https://github.com/josiegleeson/SQANTI3-dockerfile.git
```

## Build image
```
cd SQANTI-dockerfile
docker build -t sqanti3_docker_env . -f sqanti3.dockerfile
```

## Test installation
```
docker run sqanti3_docker_env sqanti3_qc.py --help
```

## Begin interactive container and mount local file system
```
docker run --name sqanti_container -v ~/path/to/local/data:/root/data -it --rm --entrypoint=/bin/bash sqanti3_docker_env
```

## Run sqanti3 inside the container (note, report generation fails)
```
(base) root@c1458b6cb9b3:~ sqanti3_qc.py data/test_isoforms.gtf data/test_ref.gtf data/hg38.fa -o test --skipORF --report skip
```

## Exit container, then copy files to local
```
docker cp sqanti_container:/root/test_classification.txt ~/path/to/local/destination/
```
